extends Node
## Game — SATRAP core state and monthly tick. Autoload.
## UI registers itself via Game.ui; world registers via group "world".

signal state_changed
signal log_added(text: String, level: int)
signal event_requested(event: Dictionary)
signal month_advanced(month: int)
signal game_ended(over: Dictionary)
signal construction_mode_changed(mode: String)

const MONTH_SECONDS := 18.0
const CAMPAIGN_MONTHS := 48
const MONTHS_IN_YEAR := 12

var ui: Node = null

# --- time
var start_id := "local_revol"
var month := 0
var speed := 1
var paused := true
var _timer := 0.0
var _started := false
var _ended := false

# --- resources
var res := {"money": 0, "food": 0, "basic_goods": 0, "luxury_goods": 0, "basic_mil": 0, "special_mil": 0}
var soldiers := {"militia": 0, "specialist": 0, "gendarme": 0}
var garrison_reserve := 0
var pop := {"avantist": 0, "imagist": 0, "fragmentist": 0, "other": 0}
var approval := {"avantist": 50, "imagist": 50, "fragmentist": 50, "other": 50, "directorate": 50, "composition": 50}
var organized_resistance := 10.0

# --- policies / research
var policies_active := {}
var research_done := {}
var research_unlocked_hidden := {}
var research_active: Variant = null
var research_progress := 0.0
var temp_mods := []  # {key, value, months_left}

# --- advisors
var advisor_cooldowns := {}
var advisors_lost := {}  # faction -> replacement triggered
var advisors_extra := {}  # unlocked extra advisors

# --- events / meta
var events_used := {}
var event_tags := {}
var log := []
var suspicion := 0.0
var hidden_assets := 0
var aphotic_month := 11
var totals := {"quota_money": 0, "quota_mil": 0, "events_resolved": 0, "hostiles_killed": 0}
var achievements := {}
var construction_mode := ""
var selected_building: Node2D = null

var pop_start_total := 1

func _ready() -> void:
	load_progress()
	aphotic_month = randi_range(10, 12)

func _process(delta: float) -> void:
	if not _started or _ended or paused:
		_timer = 0.0
		return
	_timer += delta
	var month_len := MONTH_SECONDS / maxf(speed, 0.1)
	if _timer >= month_len:
		_timer = 0.0
		do_month()

# ================================================================= start

func start_game(new_start_id: String) -> void:
	var start: Dictionary = Data.STARTS.get(new_start_id, Data.STARTS["local_revol"])
	start_id = new_start_id
	month = 0
	speed = 1
	paused = false
	_started = true
	_ended = false
	res = start.res.duplicate(true)
	soldiers = start.soldiers.duplicate(true)
	garrison_reserve = 0
	pop = start.pop.duplicate(true)
	approval = start.approval.duplicate(true)
	organized_resistance = float(start.or)
	policies_active = {}
	research_done = {}
	research_unlocked_hidden = {}
	research_active = null
	research_progress = 0.0
	temp_mods = []
	advisor_cooldowns = {}
	advisors_lost = {}
	advisors_extra = {}
	events_used = {}
	event_tags = {}
	log = []
	suspicion = 0.0
	hidden_assets = 0
	aphotic_month = randi_range(10, 12)
	totals = {"quota_money": 0, "quota_mil": 0, "events_resolved": 0, "hostiles_killed": 0}
	achievements = {}
	construction_mode = ""
	selected_building = null
	pop_start_total = total_pop()
	# initial log
	log_msg("> Welcome to the Omicron OS Adaptive Civil Management Software Package, an Omicron System Solutions product.")
	log_msg("> Analysis indicates a significant change in civil circumstances has occurred. Reconfiguring.")
	log_msg("> Injecting revolution.djinn — complete. You are the Satrap. The Dictator Suzerain has placed his trust in you.")
	log_msg("> You will be held accountable for failure.")
	log_msg("The campaign runs " + str(CAMPAIGN_MONTHS / MONTHS_IN_YEAR) + " years. Quotas are due monthly. Good luck, Satrap.")
	emit_signal("state_changed")
	# opening event
	pending_events.append(make_opening_event())

func make_opening_event() -> Dictionary:
	return {
		"id": "opening",
		"title": "First Month in Office",
		"text": "The Avantist armies are already moving on to the next province. Your report to Cardiaque is due at the end of the month, and it is due in Bull. The population is watching what a Satrap is made of.",
		"options": [
			{"text": "Begin work, Satrap.", "effects": {}, "tag": "inaction"},
		],
	}

# ================================================================= ticks

func do_month() -> void:
	month += 1
	# tick temp modifiers
	for m in temp_mods:
		m["months_left"] -= 1
	temp_mods = temp_mods.filter(func(x): return x["months_left"] > 0)
	for k in advisor_cooldowns.keys():
		if advisor_cooldowns[k] > 0:
			advisor_cooldowns[k] -= 1

	tick_production()
	tick_population()
	tick_research()
	tick_training()
	tick_military()
	tick_quotas()
	tick_approval_drift()
	tick_organized_resistance()

	var w = world_node()
	if w:
		w.month_tick()

	# advisor reversion check (total conflict)
	check_advisor_conflicts()

	# aphotic interview
	if month % MONTHS_IN_YEAR == aphotic_month:
		do_aphotic_interview()

	# random events
	if month > 1 and randf() < 0.55:
		maybe_trigger_event()

	# win check
	if month >= CAMPAIGN_MONTHS and not _ended:
		end_game(true, "four_years")
		finish_month()
		return

	check_game_over()
	finish_month()

func finish_month() -> void:
	emit_signal("month_advanced", month)
	emit_signal("state_changed")
	autosave()

func world_node() -> Node:
	var nodes := get_tree().get_nodes_in_group("world")
	return nodes[0] if nodes.size() > 0 else null

# ------------------------------------------------------------- production

func tick_production() -> void:
	var w = world_node()
	if not w:
		return
	var factory_mult := factory_mult()
	for b in w.buildings.values():
		if b.is_ruin:
			continue
		match b.building_id:
			"farm":
				res.food += Data.BUILDINGS["farm"].food
			"village":
				res.food += Data.BUILDINGS["village"].food
			"factory":
				var out := 0.0
				match b.assigned:
					"basic_goods": out = 2.0
					"luxury_goods": out = 1.0
					"basic_mil": out = 1.0
					"special_mil": out = 0.5
				if power_boosts(b):
					out *= 1.5
				out *= factory_mult
				var produced := int(out) + (1 if (out - int(out)) > randf() else 0)
				match b.assigned:
					"basic_goods": res.basic_goods += produced
					"luxury_goods": res.luxury_goods += produced
					"basic_mil":
						res.basic_mil += produced
						if "currency_reform" in research_done:
							res.money += int(produced * 0.5)
					"special_mil": res.special_mil += int(produced * 0.5 + 0.5)
	# money
	var pop_total := total_pop()
	res.money += int(pop_total * 0.004) + 2
	# policy money modifiers
	res.money += policy_money_per_pop(pop_total)
	# consumption
	res.food = maxf(0, res.food - pop_total * 0.02)
	res.basic_goods = maxf(0, res.basic_goods - pop_total * 0.0012)

func factory_mult() -> float:
	var m := 1.0
	if "industrial_efficiency_1" in research_done:
		m += 0.25
	if "industrial_efficiency_2" in research_done:
		m += 0.25
	return m

func power_boosts(b: Node2D) -> bool:
	var w = world_node()
	if not w:
		return false
	for other in w.buildings.values():
		if other == b or other.is_ruin:
			continue
		if other.building_id == "power_station" and other.global_position.distance_to(b.global_position) <= 96.0:
			return true
	return false

func policy_money_per_pop(pop_total: int) -> int:
	var per := 0.0
	for pid in policies_active:
		var p: Dictionary = Data.POLICIES[pid]
		if p.monthly.get("money_per_pop", 0.0) != 0.0:
			per += p.monthly["money_per_pop"]
	return int(pop_total * per)

# ------------------------------------------------------------ population

func total_pop() -> int:
	return int(pop.avantist + pop.imagist + pop.fragmentist + pop.other)

func tick_population() -> void:
	var pop_total := total_pop()
	if pop_total <= 0:
		return
	# food check
	var food_need := pop_total * 0.02
	var starving: bool = res.food < food_need
	if starving:
		lose_pop(int(pop_total * 0.015))
		for f in Data.FACTIONS:
			set_approval(f, -3)
		organized_resistance = minf(100, organized_resistance + 2)
		log_msg("FOOD SHORT. The population is going hungry. (-1.5% population)", 2)
	# housing check
	var housing := housing_capacity()
	if pop_total > housing:
		for f in Data.FACTIONS:
			set_approval(f, -2)
		organized_resistance = minf(100, organized_resistance + 1)
		log_msg("OVERCROWDING. Population exceeds housing capacity.", 1)
	# conversion to avantism
	var conv := conversion_rate()
	if conv > 0:
		convert_to_avantist(conv)
	# imagist drift
	var i2o := 0.001 if approval.imagist < 35 else 0.0
	for pid in policies_active:
		i2o += Data.POLICIES[pid].monthly.get("imagist_to_other", 0.0)
	if i2o > 0 and pop.imagist > 10:
		var n := int(pop.imagist * i2o)
		pop.imagist -= n
		pop.other += n
	# avantist churn
	if approval.avantist < 30 and pop.avantist > 10:
		var n := int(pop.avantist * 0.002)
		pop.avantist -= n
		pop.other += n
	# growth
	if not starving and pop_total <= housing:
		var avg := avg_local_approval()
		var g := pop_total * 0.004 * (avg / 60.0)
		distribute_pop_change(int(g))

func housing_capacity() -> int:
	var w = world_node()
	if not w:
		return 1000
	var cap := 0
	for b in w.buildings.values():
		if not b.is_ruin and Data.BUILDINGS[b.building_id].get("capacity", 0) > 0:
			cap += int(Data.BUILDINGS[b.building_id]["capacity"])
	return cap

func conversion_rate() -> float:
	var rate: float = 0.002 * (approval.avantist / 50.0)
	for pid in policies_active:
		rate += Data.POLICIES[pid].monthly.get("conversion", 0.0)
	var w = world_node()
	if w:
		for b in w.buildings.values():
			if b.is_ruin:
				continue
			if b.building_id == "amphitheatre":
				rate += 0.0015
				if "arena_testing" in research_done:
					pass
			elif b.building_id == "monument":
				rate += 0.001
	if res.luxury_goods > 20:
		rate += 0.0005
	return rate

func convert_to_avantist(fraction: float) -> void:
	var non_a: float = pop.imagist + pop.fragmentist + pop.other
	if non_a <= 0:
		return
	var target := int(non_a * fraction)
	var left := target
	for f in ["other", "imagist", "fragmentist"]:
		if left <= 0:
			break
		var take := mini(left, int(pop[f]))
		pop[f] -= take
		left -= take
	pop.avantist += target

func lose_pop(n: int) -> void:
	var left := n
	for f in ["other", "avantist", "imagist", "fragmentist"]:
		if left <= 0:
			break
		var take := mini(left, int(pop[f]))
		pop[f] -= take
		left -= take

func distribute_pop_change(n: int) -> void:
	if n <= 0:
		return
	# growth distributed by current fractions
	var total := total_pop()
	var left := n
	for f in Data.FACTIONS:
		var share := int(n * (pop[f] / maxf(total, 1)))
		pop[f] += share
		left -= share
	if left > 0:
		pop.other += left

func avg_local_approval() -> float:
	var total := maxf(total_pop(), 1)
	var s := 0.0
	for f in Data.FACTIONS:
		s += approval[f] * (pop[f] / total)
	return s

# --------------------------------------------------------------- research

func research_speed() -> float:
	var rs := 1.0
	var w = world_node()
	if w:
		for b in w.buildings.values():
			if b.is_ruin:
				continue
			if b.building_id == "rdlab":
				rs += 0.5
			elif b.building_id == "amphitheatre" and "arena_testing" in research_done:
				rs += 0.3
	for pid in policies_active:
		rs += Data.POLICIES[pid].monthly.get("research_speed_add", 0.0)
	for m in temp_mods:
		if m["key"] == "research_speed":
			rs += m["value"]
	return rs

func tick_research() -> void:
	if research_active == null:
		return
	var p: Dictionary = Data.RESEARCH[research_active]
	research_progress += research_speed()
	if research_progress >= p.cost:
		research_progress = 0.0
		var id: String = research_active
		research_done[id] = true
		research_active = null
		if p.get("unlocks", "").begins_with("building:"):
			log_msg("Research complete: " + p.name + ". " + p.desc, 0)
		elif p.get("unlocks", "").begins_with("policy:"):
			log_msg("Research complete: " + p.name + ". Policy unlocked: " + Data.POLICIES[p.unlocks.split(":")[1]].name, 0)
		elif p.get("unlocks", "").begins_with("advisor:"):
			var adv: String = p.unlocks.split(":")[1]
			advisors_extra[adv] = true
			log_msg("Research complete: " + p.name + ". New advisor: " + Data.ADVISORS[adv].name, 0)
		else:
			log_msg("Research complete: " + p.name, 0)
		var ce: Variant = p.get("complete_effects")
		if ce:
			apply_effects(ce)

# --------------------------------------------------------------- military

func total_soldiers() -> int:
	return int(soldiers.militia + soldiers.specialist + soldiers.gendarme)

func available_soldiers() -> int:
	return maxf(0, total_soldiers() - garrison_reserve)

func tick_training() -> void:
	var w = world_node()
	if not w:
		return
	for b in w.buildings.values():
		if b.is_ruin or b.building_id != "barracks" or b.assigned == "":
			continue
		b.training_progress += 0.5
		while b.training_progress >= 1.0:
			var cost := training_cost(b.assigned)
			if res.basic_mil >= cost.basic_mil and res.special_mil >= cost.special_mil:
				res.basic_mil -= cost.basic_mil
				res.special_mil -= cost.special_mil
				soldiers[b.assigned] += 1
				b.training_progress -= 1.0
				log_msg("Barracks trained 1 " + str(b.assigned).capitalize() + ".", 0)
			else:
				b.training_progress = 1.0  # stall until equipment available
				break

func training_cost(unit: String) -> Dictionary:
	var basic := 0
	var special := 0
	match unit:
		"militia": basic = 2
		"specialist": special = 2
		"gendarme":
			basic = 2 if "multi_purpose_equipment" in research_done else 3
			special = 1
	return {"basic_mil": basic, "special_mil": special}

func tick_military() -> void:
	# attrition
	var rate := 0.02
	var w = world_node()
	if w:
		var gates := 0
		for b in w.buildings.values():
			if b.is_ruin:
				continue
			if b.building_id == "gate" and b.garrisoned:
				gates += 1
			elif b.building_id == "biomedical":
				rate -= 0.01
		rate += gates * 0.05
	for pid in policies_active:
		rate += Data.POLICIES[pid].monthly.get("attrition_add", 0.0)
	for m in temp_mods:
		if m["key"] == "attrition":
			rate += m["value"]
	rate = maxf(0.0, rate)
	var militia_only := false
	for pid in policies_active:
		if Data.POLICIES[pid].monthly.get("attrition_militia_only", false):
			militia_only = true
	var losses := int(round(available_soldiers() * rate))
	if losses > 0:
		if militia_only and soldiers.militia >= losses:
			soldiers.militia -= losses
			res.basic_mil = maxf(0, res.basic_mil - losses * 2)
		else:
			var left := losses
			for u in ["militia", "specialist", "gendarme"]:
				if left <= 0:
					break
				var take := mini(left, int(soldiers[u]))
				soldiers[u] -= take
				left -= take
				var c := training_cost(u)
				res.basic_mil = maxf(0, res.basic_mil - take * c.basic_mil)
				res.special_mil = maxf(0, res.special_mil - take * c.special_mil)
		log_msg("Military attrition: -" + str(losses) + " soldiers.", 1)
	# garrison losses
	if w:
		for b in w.buildings.values():
			if not b.is_ruin and b.building_id == "gate" and b.garrisoned and randf() < 0.18:
				var lose := minf(20, total_soldiers())
				# remove from pool (not from reserve bookkeeping)
				var left := int(lose)
				for u in ["militia", "specialist", "gendarme"]:
					if left <= 0:
						break
					var take := mini(left, int(soldiers[u]))
					soldiers[u] -= take
					left -= take
				garrison_reserve = maxf(0, garrison_reserve - 20)
				b.garrisoned = false
				log_msg("The gate garrison has been lost to the dark. The " + Data.BUILDINGS["gate"].name + " is open again.", 2)

# ---------------------------------------------------------------- quotas

func tick_quotas() -> void:
	# directorate money quota
	var quota_money := 6 + (month / MONTHS_IN_YEAR)
	if res.money >= quota_money:
		res.money -= quota_money
		totals.quota_money += quota_money
		set_approval("directorate", 1)
	else:
		set_approval("directorate", -6)
		log_msg("FAILED QUOTA. Not enough Bull to pay the Directorate. (Directorate -6)", 2)
	# composition quota: 2 soldiers (gendarme preferred) or 4 basic mil
	var got := 0
	for u in ["gendarme", "militia", "specialist"]:
		if got >= 2:
			break
		if soldiers[u] - garrison_reserve > 0:
			var take := mini(2 - got, int(soldiers[u] - garrison_reserve))
			soldiers[u] -= take
			got += take
	if got < 2 and res.basic_mil >= (2 - got) * 2:
		res.basic_mil -= (2 - got) * 2
		got = 2
	if got >= 2:
		totals.quota_mil += 2
		set_approval("composition", 1)
	else:
		set_approval("composition", -6)
		log_msg("FAILED QUOTA. Could not supply the Composition. (Composition -6)", 2)

# --------------------------------------------------------------- approval

func set_approval(faction: String, delta: float) -> void:
	if faction in approval:
		approval[faction] = clampf(approval[faction] + delta, 0.0, 100.0)

func tick_approval_drift() -> void:
	# drift toward 50
	for k in ["directorate", "composition"]:
		if approval[k] < 50:
			set_approval(k, 0.2)
		elif approval[k] > 50:
			set_approval(k, -0.2)
	# avantist policies pressure
	var standard_count := 0
	for pid in policies_active:
		if Data.POLICIES[pid].get("standard", false):
			standard_count += 1
	if standard_count >= 2:
		set_approval("directorate", 0.5)
	elif standard_count == 0 and month > 6:
		set_approval("directorate", -0.5)
	# avantist discontent -> external displeasure
	if approval.avantist < 30:
		set_approval("directorate", -2)
		set_approval("composition", -1)
		suspicion = minf(100, suspicion + 2)
	# luxury goods
	if res.luxury_goods > 20:
		for f in Data.FACTIONS:
			set_approval(f, 0.3)
	# basic goods shortage
	if res.basic_goods < 5:
		for f in Data.FACTIONS:
			set_approval(f, -1)
	# building-based approval (temples, amphitheatres, biomedical)
	var w = world_node()
	if w:
		var temple = {"solarite": "avantist", "imagist": "imagist", "fragmentist": "fragmentist"}
		for b in w.buildings.values():
			if b.is_ruin:
				continue
			match b.building_id:
				"temple":
					var target = temple.get(b.assigned, null)
					if target:
						set_approval(target, 0.8)
					elif b.assigned == "non_denominational":
						for f in Data.FACTIONS:
							set_approval(f, 0.3)
				"amphitheatre":
					set_approval("avantist", 0.5)
				"biomedical":
					for f in Data.FACTIONS:
						set_approval(f, 0.2)
	# policy monthly approvals
	for pid in policies_active:
		var a: Variant = Data.POLICIES[pid].monthly.get("approval")
		if a:
			for f in a:
				set_approval(f, a[f])
	# suspicion decay
	suspicion = maxf(0, suspicion - 0.5)

# ------------------------------------------------------ organized resis.

func tick_organized_resistance() -> void:
	var delta := 0.1
	var pop_total := maxf(total_pop(), 1)
	for f in ["imagist", "fragmentist", "other"]:
		if approval[f] < 45:
			delta += (45 - approval[f]) * 0.015 * (pop[f] / pop_total) * 10
	for pid in policies_active:
		delta += Data.POLICIES[pid].monthly.get("or_add", 0.0)
		delta -= Data.POLICIES[pid].monthly.get("or_sub", 0.0)
	var prev := organized_resistance
	organized_resistance = clampf(organized_resistance + delta, 0.0, 100.0)
	if organized_resistance >= 70 and prev < 70:
		log_msg("CRITICAL: Organized Resistance has passed 70%. The city is a powder keg.", 2)
		suspicion = minf(100, suspicion + 5)

# ------------------------------------------------------------ advisors

func advisor_available(id: String) -> bool:
	match id:
		"vizier", "dramaturge", "attache": return true
		"pater_aleph":
			if "imagist" in advisors_lost:
				return "excoriator" in advisor_available_list()
			return "pater_aleph" in advisors_extra
		"esotechnist":
			if "fragmentist" in advisors_lost:
				return "exterminator" in advisor_available_list()
			return "esotechnist" in advisors_extra
		_: return id in advisor_available_list()

func advisor_available_list() -> Array:
	var list := ["vizier", "dramaturge", "attache"]
	if "pater_aleph" in advisors_extra and not "imagist" in advisors_lost:
		list.append("pater_aleph")
	elif "imagist" in advisors_lost:
		list.append("excoriator")
	if "esotechnist" in advisors_extra and not "fragmentist" in advisors_lost:
		list.append("esotechnist")
	elif "fragmentist" in advisors_lost:
		list.append("exterminator")
	return list

func check_advisor_conflicts() -> void:
	if not "imagist" in advisors_lost and approval.imagist < 15:
		advisors_lost["imagist"] = true
		log_msg("The Pater-Aleph has severed contact with you. The Solar Excoriator has taken his place at your table.", 2)
	if not "fragmentist" in advisors_lost and approval.fragmentist < 15:
		advisors_lost["fragmentist"] = true
		log_msg("The Esotechnist has vanished. The Artiste-Exterminator now attends to the Fragmentist question.", 2)

func perform_advisor_action(advisor_id: String, action_id: String) -> bool:
	var a: Dictionary = Data.ADVISORS[advisor_id]
	var action: Variant = null
	for x in a.actions:
		if x["id"] == action_id:
			action = x
			break
	if action == null:
		return false
	if advisor_cooldowns.get(advisor_id + ":" + action_id, 0) > 0:
		log_msg("That request is still in progress. (" + str(advisor_cooldowns[advisor_id + ":" + action_id]) + " months left)", 1)
		return false
	# affordability
	var cost: Dictionary = action["effects"].get("res", {})
	for r in cost:
		if cost[r] < 0 and res[r] < -cost[r]:
			log_msg("Insufficient " + Data.RESOURCE_NAMES[r] + ".", 1)
			return false
	apply_effects(action["effects"])
	var cd: int = action.get("cooldown", 3)
	advisor_cooldowns[advisor_id + ":" + action_id] = cd
	emit_signal("state_changed")
	autosave()
	return true

# ---------------------------------------------------------------- effects

func apply_effects(e: Dictionary) -> void:
	if e.is_empty():
		pass
	# resources
	if e.has("res"):
		for r in e["res"]:
			res[r] = maxf(0.0, res[r] + e["res"][r])
	# approvals
	if e.has("approval"):
		for f in e["approval"]:
			set_approval(f, e["approval"][f])
	# soldiers
	if e.has("soldiers"):
		for u in e["soldiers"]:
			soldiers[u] = maxf(0, soldiers[u] + e["soldiers"][u])
	# population
	if e.has("pop"):
		for f in e["pop"]:
			pop[f] = maxf(0, pop[f] + e["pop"][f])
	if e.has("pop_loss_fraction") and e["pop_loss_fraction"] > 0:
		lose_pop(int(total_pop() * e["pop_loss_fraction"]))
	# organized resistance
	organized_resistance = clampf(organized_resistance + e.get("or_add", 0.0) - e.get("or_sub", 0.0), 0.0, 100.0)
	# conversions
	if e.has("conversion") and e["conversion"] > 0:
		convert_to_avantist(e["conversion"])
	if e.has("convert_imagist_to_avantist"):
		var n := int(pop.imagist * e["convert_imagist_to_avantist"])
		pop.imagist -= n
		pop.avantist += n
	if e.has("convert_fragmentist_to_avantist"):
		var n2 := int(pop.fragmentist * e["convert_fragmentist_to_avantist"])
		pop.fragmentist -= n2
		pop.avantist += n2
	# research unlocks
	if e.has("unlock_research") and e["unlock_research"] not in research_unlocked_hidden:
		research_unlocked_hidden[e["unlock_research"]] = true
	if e.has("unlock_policy"):
		log_msg("Policy unlocked: " + Data.POLICIES[e["unlock_policy"]].name, 0)
	if e.has("unlock_currency_reform"):
		research_done["currency_reform"] = true
	# suspicion / assets
	suspicion = minf(100, suspicion + e.get("suspicion", 0.0))
	hidden_assets += e.get("hidden_assets", 0)
	# temporary modifiers
	var dur := int(e.get("duration", 3))
	if e.has("attrition_add") and e["attrition_add"] != 0:
		temp_mods.append({"key": "attrition", "value": e["attrition_add"], "months_left": dur})
	if e.has("research_speed_mod") and e["research_speed_mod"] != 0:
		temp_mods.append({"key": "research_speed", "value": e["research_speed_mod"], "months_left": dur})
	# world actions
	var w = world_node()
	if e.has("spawn_hostiles") and w:
		for kind in e["spawn_hostiles"]:
			for i in e["spawn_hostiles"][kind]:
				w.spawn_hostile(kind)
	if e.has("kill_mechanoid") and w:
		w.kill_hostile_of_kind("mechanoid", "The Esotechnist's rite unmade a Mechanoid.")
	if e.has("kill_all_hostiles") and w:
		w.kill_hostiles_of_kind(e["kill_all_hostiles"], "The mass hunt drove off the " + str(e["kill_all_hostiles"]))
	if e.has("event_log"):
		log_msg(e["event_log"], 0)
	# tag for achievements
	if e.has("tag"):
		event_tags[e["tag"]] = event_tags.get(e["tag"], 0) + 1
		totals.events_resolved += 1

# ---------------------------------------------------------------- policies

func policy_available(id: String) -> bool:
	var p: Dictionary = Data.POLICIES[id]
	if p.get("requires_policy", "") != "":
		return p["requires_policy"] in policies_active
	if p.get("requires_research", "") != "":
		return p["requires_research"] in research_done
	return true

func toggle_policy(id: String) -> bool:
	if id in policies_active:
		policies_active.erase(id)
		log_msg("Policy repealed: " + Data.POLICIES[id].name, 0)
	else:
		if not policy_available(id):
			return false
		var p: Dictionary = Data.POLICIES[id]
		if res.money < p.cost:
			log_msg("Not enough Money to institute " + p.name + ".", 1)
			return false
		res.money -= p.cost
		policies_active[id] = true
		log_msg("Policy instituted: " + p.name, 0)
		if p.one_time:
			apply_effects(p.one_time)
	emit_signal("state_changed")
	autosave()
	return true

# ---------------------------------------------------------------- research

func research_available(id: String) -> bool:
	var p: Dictionary = Data.RESEARCH[id]
	if p.get("hidden") and id not in research_unlocked_hidden:
		return false
	if p.get("requires", "") != "":
		return p["requires"] in research_done
	return true

func start_research(id: String) -> bool:
	if id in research_done or not research_available(id):
		return false
	if research_active != null and research_active != id:
		var refund_ratio: float = research_progress / Data.RESEARCH[research_active].cost
		# simple: keep progress if same, else reset
		research_active = null
		research_progress = 0.0
	research_active = id
	research_progress = 0.0
	log_msg("Research begun: " + Data.RESEARCH[id].name, 0)
	emit_signal("state_changed")
	return true

# ------------------------------------------------------------------ hostiles

func attack_hostile(hostile: Node, unit: String) -> int:
	var kind: String = hostile.kind
	var base := int(Data.COMBAT_BASE[kind][unit])
	if unit == "specialist" and kind == "wildlife" and "animal_control_training" in research_done:
		base = maxi(1, base - 1)
	var bonus := 0
	var w = world_node()
	if w:
		for b in w.buildings.values():
			if not b.is_ruin and (b.building_id == "outpost" or b.building_id == "barracks") and b.stationed:
				if b.global_position.distance_to(hostile.global_position) <= 96.0:
					bonus += 1
					break
	var casualties := maxi(0, randi_range(1, maxi(1, base)) - bonus)
	# remove from chosen unit first, spill over to other units
	var left := casualties
	var take := mini(left, int(soldiers[unit]))
	soldiers[unit] -= take
	left -= take
	for u in ["militia", "specialist", "gendarme"]:
		if left <= 0:
			break
		take = mini(left, int(soldiers[u]))
		soldiers[u] -= take
		left -= take
	# consume equipment proportional to losses
	var c := training_cost(unit)
	res.basic_mil = maxf(0.0, res.basic_mil - casualties * c.basic_mil)
	res.special_mil = maxf(0.0, res.special_mil - casualties * c.special_mil)
	totals.hostiles_killed += 1
	log_msg("Attack on " + Data.HOSTILES[kind].name + ": " + str(casualties) + " casualties (" + unit + ").", 1)
	w.remove_hostile(hostile)
	emit_signal("state_changed")
	autosave()
	return casualties

func can_attack(hostile: Node, unit: String) -> bool:
	return soldiers[unit] > 0

# -------------------------------------------------------------- events

func event_eligible(ev: Dictionary) -> bool:
	if ev["id"] in events_used:
		return false
	if ev.get("month_min") and month < ev["month_min"]:
		return false
	var cond: Variant = ev.get("cond")
	if cond:
		if cond.has("approval_min"):
			for f in cond["approval_min"]:
				if approval[f] < cond["approval_min"][f]:
					return false
		if cond.has("hostiles_min"):
			var w = world_node()
			var n: int = w.hostiles.size() if w else 0
			if n < cond["hostiles_min"]:
				return false
		if cond.has("hostile_kind"):
			var w2 = world_node()
			var has := false
			if w2:
				for h in w2.hostiles:
					if h.kind == cond["hostile_kind"]:
						has = true
			if not has:
				return false
		if cond.has("building_min"):
			var w3 = world_node()
			for bid in cond["building_min"]:
				var count := 0
				if w3:
					for b in w3.buildings.values():
						if not b.is_ruin and b.building_id == bid:
							count += 1
				if count < cond["building_min"][bid]:
					return false
	return true

func option_eligible(opt: Dictionary) -> bool:
	var cond: Variant = opt.get("cond")
	if cond == null:
		return true
	if cond.has("approval_min"):
		for f in cond["approval_min"]:
			if approval[f] < cond["approval_min"][f]:
				return false
	return true

var pending_events: Array = []

func queue_event(ev: Dictionary) -> void:
	pending_events.append(ev)
	present_pending_event()

func maybe_trigger_event() -> void:
	var pool := []
	for ev in Data.EVENTS:
		if event_eligible(ev):
			pool.append(ev)
	if pool.is_empty():
		return
	var ev: Dictionary = pool[randi() % pool.size()]
	events_used[ev["id"]] = true
	queue_event(ev)

func present_pending_event() -> void:
	if pending_events.is_empty():
		return
	var ev: Dictionary = pending_events[0]
	if ui:
		paused = true
		emit_signal("event_requested", ev)
	else:
		# headless: auto-resolve with first eligible option
		pending_events.pop_front()
		for opt in ev["options"]:
			if option_eligible(opt):
				apply_effects(opt["effects"])
				break
		if pending_events.size() > 0:
			present_pending_event()

func resolve_event(option_index: int) -> void:
	if pending_events.is_empty():
		return
	var ev: Dictionary = pending_events.pop_front()
	var opt = ev["options"][clampi(option_index, 0, ev["options"].size() - 1)]
	apply_effects(opt["effects"])
	if ev["id"] != "opening" and ev["id"] != "aphotic":
		log_msg("Resolved '" + ev["title"] + "': " + opt["text"].left(60) + "…", 0)
	emit_signal("state_changed")
	if pending_events.size() > 0:
		present_pending_event()
	else:
		paused = false
	emit_signal("state_changed")

# -------------------------------------------------------------- aphotic

func do_aphotic_interview() -> void:
	var issues := []
	var severities := 0
	if approval.directorate < 40:
		issues.append("Your reports to Cardiaque are thin, and thin is a word the Directorate does not forgive.")
		severities += 1
	if approval.composition < 40:
		issues.append("The Militant Composition is dissatisfied with the state of the satrapy's defence.")
		severities += 1
	if approval.avantist < 40:
		issues.append("Your own people have begun to drift from the vision. This is noted. This is remembered.")
		severities += 1
	if organized_resistance > 50:
		issues.append("Intelligence indicates a significant degree of Organized Resistance within your borders.")
		severities += 1
	var w = world_node()
	var hostiles: int = w.hostiles.size() if w else 0
	if hostiles > 2:
		issues.append(str(hostiles) + " hostile forces persist in your satrapy. The darkness is not meant to be a permanent tenant.")
		severities += 1
	if res.money > 300:
		issues.append("Your ledgers show a considerable hoard of Bull. Profiteering from your position, or simply failing to spend?")
		severities += 1
	if suspicion > 30:
		issues.append("There are questions about your loyalty, Satrap. Loyalty is a thing we prefer to assume.")
		severities += 1
	var standard_count := 0
	for pid in policies_active:
		if Data.POLICIES[pid].get("standard", false):
			standard_count += 1
	if standard_count == 0 and month > 8:
		issues.append("The revolutionary program remains unimplemented. The Directorate expected progress.")
		severities += 1

	var text := "An Aphotic of the Coterie has requested an audience. They do not smile, but they are not hostile. The interview is private, and it is long."
	var options := []
	if severities == 0:
		text += "\n\n\"Your satrapy functions. The Carcasse takes note.\""
		var blessing := [
			{"text": "Receive the Aphotic's regards.", "effects": {"res": {"food": 40, "basic_goods": 20}, "event_log": "The Aphotic requisitions a shipment of provisions for your satrapy, citing 'operational necessity'."}},
			{"text": "Receive the Aphotic's regards.", "effects": {"approval": {"directorate": 5, "composition": 5}}},
			{"text": "Receive the Aphotic's regards.", "effects": {"res": {"basic_mil": 20, "special_mil": 8}}},
		]
		options = [blessing[randi() % blessing.size()]]
	elif severities <= 2:
		text += "\n\n" + "\n".join(issues) + "\n\n\"These matters will be in the next report. Resolve them, Satrap. There will be consequences if this is not resolved when we next speak.\""
		options = [
			{"text": "Stand your ground. The work is progressing as it must.", "effects": {"suspicion": 4, "approval": {"directorate": -2}}},
			{"text": "Submit. Promise reform where promises are cheapest.", "effects": {"approval": {"directorate": 4, "other": -2, "avantist": -1}}},
		]
	else:
		# severe
		text += "\n\n" + "\n".join(issues) + "\n\nThe Aphotic's expression does not change, which is somehow worse."
		var exprop := int(res.money * 0.4)
		options = [
			{"text": "Explain. Defend. The satrapy is as it is because of forces beyond your command.",
				"effects": {"res": {"money": -exprop}, "approval": {"directorate": -8}, "suspicion": -15, "event_log": "A significant sum of Bull is expropriated from the satrapy's coffers."}},
			{"text": "Submit to whatever is required.",
				"effects": {"res": {"money": -exprop}, "approval": {"directorate": -5, "other": -4}, "suspicion": -20, "event_log": "A significant sum of Bull is expropriated from the satrapy's coffers."}},
		]
		# purge chance
		if suspicion >= 60 or severities >= 5:
			if randf() < 0.6:
				pending_events.append({"id": "aphotic", "title": "The Interview", "text": text, "options": [
					{"text": "…", "effects": {"purge": true}}
				]})
				present_pending_event()
				return
	pending_events.append({"id": "aphotic", "title": "The Aphotic Interview — Year " + str(month / MONTHS_IN_YEAR + 1), "text": text, "options": options})
	present_pending_event()

# ----------------------------------------------------------------- ending

func end_game(win: bool, reason: String) -> void:
	_ended = true
	paused = false
	var over := {"win": win, "reason": reason}
	if win:
		over.merge(scorecard(), false)
	else:
		over["letter"] = end_letter_lose(reason)
	# achievements
	if win:
		achieve("the_suzerain_sees_you")
		if over.get("verdict", "") == "commendable":
			achieve("the_suzerain_loves_you")
	# progress
	save_progress()
	clear_save()
	log_msg("CAMPAIGN ENDED: " + (str(reason).capitalize() if not win else "The four years are complete."), 0)
	emit_signal("game_ended", over)
	emit_signal("state_changed")

func scorecard() -> Dictionary:
	var pop_total := maxf(total_pop(), 1)
	var avantist_frac: float = pop.avantist / pop_total
	var score := 0.0
	var lines := []
	var s1: float = avantist_frac * 40.0
	score += s1
	lines.append("Conversion to Avantism: " + str(int(avantist_frac * 100)) + "%  [" + str(int(s1)) + "/40]")
	var s2: float = approval.directorate / 100.0 * 15.0
	score += s2
	lines.append("Standing with the Directorate: " + str(int(approval.directorate)) + "%  [" + str(int(s2)) + "/15]")
	var s3: float = approval.composition / 100.0 * 15.0
	score += s3
	lines.append("Standing with the Composition: " + str(int(approval.composition)) + "%  [" + str(int(s3)) + "/15]")
	var growth := clampf((total_pop() / maxf(pop_start_total, 1) - 1.0), 0.0, 1.0)
	var s4 := growth * 15.0
	score += s4
	lines.append("Population growth: " + str(int(growth * 100)) + "%  [" + str(int(s4)) + "/15]")
	var s5 := clampf(float(totals.quota_money) / 400.0, 0.0, 1.0) * 10.0
	score += s5
	lines.append("Bull remitted to Cardiaque: " + str(totals.quota_money) + "  [" + str(int(s5)) + "/10]")
	var s6 := minf(research_done.size(), 5) * 1.0
	score += s6
	lines.append("Research programs completed: " + str(research_done.size()) + "  [" + str(int(s6)) + "/5]")
	var s7 := minf(achievements.size(), 10) * 2.0
	score += s7
	lines.append("Matters of note: " + str(achievements.size()) + "  [" + str(int(s7)) + "/10]")
	var verdict
	if score >= 70:
		verdict = "commendable"
	elif score >= 45:
		verdict = "adequate"
	else:
		verdict = "disappointing"
	return {"score": int(score), "lines": lines, "verdict": verdict}

func end_letter_lose(reason: String) -> String:
	match reason:
		"resistance":
			return "THE OPEN REVOLT\n\nThe traitors did not kill you themselves. The Avant Carcasse purged you for failure, after they had restored order. Your name has been removed from the records, which is a kindness of a sort."
		"directorate":
			return "PURGED\n\nThe Directorate's patience has run out. The Coterie visited you in the night. In the morning the Administrative Building was quiet, and a new name was in your chair."
		"composition":
			return "DISMISSED AND ERASED\n\nThe Composition no longer considers you worth keeping alive. The details of your disappearance are a matter for the archives."
		"admin":
			return "THE BUILDING FALLS\n\nHostile forces took the Administrative Building. You were not given the courtesy of a clean death. The Carcasse will absorb the loss of the satrapy as it absorbs all losses: completely."
		"purge":
			return "PURGED BY THE APHOTIC COTERIE\n\nThe interview ended. That was, in the end, the most important thing about it. The Coterie answers directly to the Suzerain, and you have been answered for."
	return "The campaign has ended."

# ------------------------------------------------------------- game over

func check_game_over() -> void:
	if organized_resistance >= 100:
		end_game(false, "resistance")
	elif approval.directorate <= 0:
		end_game(false, "directorate")
	elif approval.composition <= 0:
		end_game(false, "composition")
	var w = world_node()
	if w:
		for b in w.buildings.values():
			if b.building_id == "admin" and b.is_ruin:
				end_game(false, "admin")
				return
	# admin destroyed check via world

# ---------------------------------------------------------------- achievements

func achieve(id: String) -> void:
	if id in achievements:
		return
	achievements[id] = true
	var a: Variant = Data.ACHIEVEMENTS.get(id)
	if a:
		log_msg("ACHIEVEMENT: " + a["name"], 0)
	save_progress()

func check_achievements() -> void:
	var w = world_node()
	if w:
		var count = {"factory": 0, "amphitheatre": 0, "temple": 0, "outpost": 0}
		var total_b := 0
		for b in w.buildings.values():
			if not b.is_ruin:
				total_b += 1
				if b.building_id in count:
					count[b.building_id] += 1
		if count.factory >= 20:
			achieve("industrial_revolution")
		if count.amphitheatre >= 5:
			achieve("are_you_not_entertained")
		if count.temple >= 5:
			achieve("hallowed_ground")
		if count.outpost >= 20:
			achieve("in_the_shadows_of_the_guns")
		if total_b >= 100:
			achieve("infinite_city_sprawl")
	if approval.directorate >= 99.9:
		achieve("tired_aparatchik")
	if approval.composition >= 99.9:
		achieve("patron_of_the_arts")
	if avg_local_approval() >= 95:
		achieve("radical_populist")
	if approval.avantist >= 95:
		achieve("a_friendly_fanatic")
	if approval.imagist >= 95:
		achieve("my_brothers_keeper")
	if approval.fragmentist >= 95:
		achieve("in_found_carcosa")
	if approval.other >= 95:
		achieve("a_hundred_flowers_bloom")
	var pop_total := maxf(total_pop(), 1)
	if pop.avantist / pop_total > 0.95:
		achieve("revolutionary_consensus")
	if pop.avantist / pop_total < 0.05:
		achieve("least_committed_radical")
	if pop.other / pop_total < 0.05:
		achieve("centricide")
	if research_speed() > 2.0:
		achieve("technology_shall_lead")
	if research_speed() > 4.0:
		achieve("war_against_the_present")
	for tag in ["collab_fragmentist", "collab_imagist", "inaction", "suppression", "conscription", "purge"]:
		if event_tags.get(tag, 0) >= 5 and tag in ["collab_fragmentist", "collab_imagist"]:
			achieve("friends_in_low_places" if tag == "collab_fragmentist" else "deus_vult")
		if event_tags.get(tag, 0) >= 15:
			match tag:
				"inaction": achieve("nobodycaresanymoreism")
				"suppression": achieve("until_morale_improves")
				"conscription": achieve("one_day_in_the_life")
				"purge": achieve("spectacle_and_expedience")

# ------------------------------------------------------------------- log

func log_msg(text: String, level: int = 0) -> void:
	log.append({"m": month, "t": text, "l": level})
	if log.size() > 60:
		log = log.slice(-60)
	emit_signal("log_added", text, level)

# ------------------------------------------------------------------ save

func save_data() -> Dictionary:
	var w = world_node()
	var b_list := []
	var h_list := []
	if w:
		for b in w.buildings.values():
			b_list.append({"id": b.building_id, "pos": [int(b.pos.x), int(b.pos.y)], "assigned": b.assigned,
				"garrisoned": b.garrisoned, "stationed": b.stationed, "hp": b.hp, "is_ruin": b.is_ruin,
				"training_progress": b.training_progress})
		for h in w.hostiles:
			h_list.append({"kind": h.kind, "pos": [int(h.global_position.x / 32.0), int(h.global_position.y / 32.0)]})
	return {
		"v": 1,
		"start_id": start_id, "month": month, "speed": speed, "paused": true,
		"res": res, "soldiers": soldiers, "garrison_reserve": garrison_reserve,
		"pop": pop, "approval": approval, "or": organized_resistance,
		"policies": policies_active.keys(), "research_done": research_done.keys(),
		"research_unlocked_hidden": research_unlocked_hidden.keys(),
		"research_active": research_active, "research_progress": research_progress,
		"temp_mods": temp_mods, "advisor_cooldowns": advisor_cooldowns,
		"advisors_lost": advisors_lost, "advisors_extra": advisors_extra,
		"events_used": events_used.keys(), "event_tags": event_tags,
		"log": log, "suspicion": suspicion, "hidden_assets": hidden_assets,
		"aphotic_month": aphotic_month, "totals": totals, "achievements": achievements.keys(),
		"pop_start_total": pop_start_total, "buildings": b_list, "hostiles": h_list,
	}

func autosave() -> void:
	if not _started or _ended:
		return
	var f := FileAccess.open(Data.SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save_data()))
		f.close()

func clear_save() -> void:
	if FileAccess.file_exists(Data.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Data.SAVE_PATH))

func has_save() -> bool:
	return FileAccess.file_exists(Data.SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(Data.SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	start_id = data["start_id"]
	month = data["month"]
	speed = data.get("speed", 1)
	_started = true
	_ended = false
	res = data["res"]
	soldiers = data["soldiers"]
	garrison_reserve = data.get("garrison_reserve", 0)
	pop = data["pop"]
	approval = data["approval"]
	organized_resistance = data["or"]
	policies_active = {}
	for p in data["policies"]:
		policies_active[p] = true
	research_done = {}
	for r in data["research_done"]:
		research_done[r] = true
	research_unlocked_hidden = {}
	for r in data.get("research_unlocked_hidden", []):
		research_unlocked_hidden[r] = true
	research_active = data.get("research_active")
	research_progress = data.get("research_progress", 0.0)
	temp_mods = data.get("temp_mods", [])
	advisor_cooldowns = data.get("advisor_cooldowns", {})
	advisors_lost = data.get("advisors_lost", {})
	advisors_extra = data.get("advisors_extra", {})
	events_used = {}
	for e in data.get("events_used", []):
		events_used[e] = true
	event_tags = data.get("event_tags", {})
	log = data.get("log", [])
	suspicion = data.get("suspicion", 0.0)
	hidden_assets = data.get("hidden_assets", 0)
	aphotic_month = data.get("aphotic_month", 11)
	totals = data.get("totals", {"quota_money": 0, "quota_mil": 0, "events_resolved": 0, "hostiles_killed": 0})
	achievements = {}
	for a in data.get("achievements", []):
		achievements[a] = true
	pop_start_total = data.get("pop_start_total", total_pop())
	# world
	var w = world_node()
	if w:
		w.load_layout(data.get("buildings", []), data.get("hostiles", []))
	log_msg("Game loaded. Month " + str(month) + ".", 0)
	emit_signal("state_changed")
	return true

# ---------------------------------------------------------------- progress

var progress := {"unlocked": ["local_revol"], "completed": {}, "achievements": []}

func load_progress() -> void:
	if FileAccess.file_exists(Data.PROGRESS_PATH):
		var f := FileAccess.open(Data.PROGRESS_PATH, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				progress = d
			f.close()

func save_progress() -> void:
	# merge achievements
	for a in achievements:
		if a not in progress["achievements"]:
			progress["achievements"].append(a)
	# unlock rules
	if progress["completed"].get("local_revol") and "monarch" not in progress["unlocked"]:
		progress["unlocked"].append("monarch")
	if ("local_revol" in progress["completed"]) or ("monarch" in progress["completed"]):
		if "appointee" not in progress["unlocked"]:
			progress["unlocked"].append("appointee")
	var f := FileAccess.open(Data.PROGRESS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(progress))
		f.close()

func record_completion(verdict: String) -> void:
	progress["completed"][start_id] = verdict
	save_progress()
