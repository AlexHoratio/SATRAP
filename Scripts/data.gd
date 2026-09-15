class_name Data
## Static game data for SATRAP: buildings, policies, research, events, advisors, starts.
## Effects are pure data dicts interpreted by Game.apply_effects().

const SAVE_PATH := "user://satrap_save.json"
const PROGRESS_PATH := "user://satrap_progress.json"
const FONT := "res://Graphics/Fonts/MorePerfectDOSVGA.ttf"
const GREEN := Color(0, 0.95, 0.35)
const GREEN_DIM := Color(0, 0.55, 0.25)
const GREEN_DARK := Color(0, 0.3, 0.12)
const RED := Color(0.95, 0.25, 0.18)
const PANEL_BG := Color(0.0, 0.05, 0.02, 0.92)

const FACTIONS := ["avantist", "imagist", "fragmentist", "other"]
const FACTION_NAMES := {
	"avantist": "Avantists",
	"imagist": "Imagists",
	"fragmentist": "Fragmentists",
	"other": "Other",
}
const RESOURCE_NAMES := {
	"money": "Money (Bull)",
	"food": "Food",
	"basic_goods": "Basic Goods",
	"luxury_goods": "Luxury Goods",
	"basic_mil": "Basic Mil. Equip.",
	"special_mil": "Specialist Mil. Equip.",
}

const MONTH_NAMES := ["January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"]

# ---------------------------------------------------------------- buildings

const BUILDINGS := {
	"admin": {
		"name": "Administrative Building",
		"cost": 0,
		"sprite": "res://Graphics/Entities/Buildings/admin1.png",
		"desc": "From here you govern the Satrapy. If it falls, so do you.",
	},
	"civil": {
		"name": "Civil Building",
		"cost": 20,
		"sprite": "res://Graphics/Entities/Buildings/civil2.png",
		"capacity": 150,
		"desc": "Housing and basic amenities for 150 citizens. If population exceeds housing capacity, people will get angry.",
	},
	"farm": {
		"name": "Farm",
		"cost": 25,
		"sprite": "res://Graphics/Entities/Sprites/Farm.png",
		"food": 8,
		"desc": "Produces 8 food per month.",
	},
	"factory": {
		"name": "Factory",
		"cost": 40,
		"sprite": "res://Graphics/Entities/Sprites/Factory.png",
		"desc": "Assignable production facility. Right-click to assign. Basic Goods: 2/mo, Luxury Goods: 1/mo, Basic Mil Equip: 1/mo, Specialist Mil Equip: 0.5/mo.",
	},
	"barracks": {
		"name": "Barracks",
		"cost": 40,
		"sprite": "res://Graphics/Entities/Sprites/Barracks.png",
		"garrison_radius": 96,
		"desc": "Trains soldiers (1 per 2 months while assigned). While troops are stationed, reduces casualties for attacks within 3 tiles.",
	},
	"outpost": {
		"name": "Outpost",
		"cost": 30,
		"sprite": "res://Graphics/Entities/Sprites/Outpost.png",
		"garrison_radius": 96,
		"desc": "Station troops here to reduce casualties for attacks within 3 tiles.",
	},
	"temple": {
		"name": "Temple",
		"cost": 35,
		"sprite": "res://Graphics/Entities/Sprites/Temple.png",
		"desc": "Assign a denomination: Solarite (pleases Avantists), Imagist, Fragmentist, or Non-denominational (pleases everyone mildly).",
	},
	"village": {
		"name": "Village",
		"cost": 0,
		"sprite": "res://Graphics/Entities/Sprites/Village1.png",
		"capacity": 100,
		"food": 2,
		"desc": "A small settlement on the Satrapy's periphery. Houses 100 citizens and produces 2 food per month.",
	},
	"gate": {
		"name": "Circulatory Gate",
		"cost": 0,
		"sprite": "res://Graphics/Entities/Sprites/Circulatory Entrance.png",
		"desc": "An egress from the Circulatory. Mechanoids emerge from the dark. Garrison with 20 soldiers to seal it — at a steady cost in attrition, and the garrison may be lost.",
	},
	"amphitheatre": {
		"name": "Amphitheatre",
		"cost": 60,
		"unlock": "spectacle_combat",
		"desc": "Spectacle in the name of the Suzerain. Pleases Avantists and accelerates their conversion. (Research: Spectacle Combat)",
	},
	"rdlab": {
		"name": "R&D Laboratory",
		"cost": 50,
		"unlock": "lab_programs",
		"research_speed": 0.5,
		"desc": "Specialists from the Carcasse adapt local research practice. +0.5 Research Speed. (Research: Laboratory Programs)",
	},
	"power_station": {
		"name": "Power Station",
		"cost": 45,
		"unlock": "power_grid",
		"radius": 96,
		"desc": "Factories within 3 tiles produce +50%. (Research: Power Grid)",
	},
	"biomedical": {
		"name": "Biomedical Centre",
		"cost": 55,
		"unlock": "biomed_science",
		"desc": "Reduces military attrition by 10% and mildly pleases the populace. (Research: Biomedical Science)",
	},
	"monument": {
		"name": "Architectural Monument",
		"cost": 50,
		"unlock": "architectural_programs",
		"desc": "A visible testament to the vision. Accelerates conversion to Avantism. (Research: Architectural Programs)",
	},
	"autodefence": {
		"name": "Automated Defences",
		"cost": 45,
		"unlock": "automated_defences",
		"radius": 96,
		"desc": "Automated turrets destroy Hostile Wildlife that enters a 3-tile radius. (Research: Automated Defences)",
	},
	"ruin": {
		"name": "Ruins",
		"cost": 0,
		"sprite": "res://Graphics/Entities/Sprites/Ruins.png",
		"desc": "The remains of a destroyed structure. Can be demolished at no cost to clear the tile.",
	},
}

# glyph letters for buildings without pixel art
const BUILDING_GLYPHS := {
	"amphitheatre": "AM",
	"rdlab": "RD",
	"power_station": "PW",
	"biomedical": "BM",
	"monument": "MN",
	"autodefence": "DF",
}

const HOSTILES := {
	"humanoid": {
		"name": "Hostile Humanoids",
		"sprite": "res://Graphics/Entities/Sprites/Hostile Humanoid.png",
		"desc": "Bandits, insurgents, foreign scouting parties. Militia are effective against them.",
	},
	"wildlife": {
		"name": "Hostile Wildlife",
		"sprite": "res://Graphics/Entities/Sprites/Hostile Wildlife.png",
		"desc": "Dangerous fauna of the untamed planet. Specialist Militia are effective against them.",
	},
	"mechanoid": {
		"name": "Mechanoids",
		"sprite": "res://Graphics/Entities/Sprites/Hostile Mechanoid.png",
		"desc": "Biomechanical horrors from the Circulatory. Specialist Militia and Gendarmes are effective against them.",
	},
}

# casualties rolled 1..base per attacker type (lower = better)
const COMBAT_BASE := {
	"humanoid": {"militia": 3, "specialist": 6, "gendarme": 1},
	"wildlife": {"militia": 4, "specialist": 2, "gendarme": 1},
	"mechanoid": {"militia": 6, "specialist": 2, "gendarme": 2},
}

# ------------------------------------------------------------------ policies

const POLICIES := {
	"standardise_currency": {
		"name": "Standardise Currency",
		"desc": "Switch the mixed old currencies to Avantist Bull. Costs a great deal as you must pay out, but Military Equipment production will thereafter also mint Money.",
		"standard": true,
		"cost": 100,
		"one_time": {"approval": {"avantist": 8, "other": -5}, "unlock_currency_reform": true},
		"monthly": {"money_per_pop": 0.002},
	},
	"ideological_education": {
		"name": "Ideological Education Reform",
		"desc": "A curriculum of theory, artist-interclass-consciousness and Avantist Virtue. Really offends everyone who is not an Avantist, but raises the Avantist conversion rate.",
		"standard": true,
		"cost": 30,
		"one_time": {"approval": {"avantist": 10, "imagist": -12, "fragmentist": -12, "other": -8}},
		"monthly": {"conversion": 0.005},
	},
	"distribute_firearms": {
		"name": "Distribute Firearms",
		"desc": "The Suzerain wants all his citizens armed and ready to fight for Avantism. Pleases Avantists greatly; increases Military Attrition and Organized Resistance.",
		"standard": true,
		"cost": 50,
		"one_time": {"approval": {"avantist": 15, "imagist": -5, "fragmentist": -5, "other": -5}},
		"monthly": {"attrition_add": 0.01, "or_add": 0.3},
	},
	"mandatory_graffiti": {
		"name": "Mandatory Graffiti Program",
		"desc": "Every wall a mural, every brick a canvas, not one alley from which a scrawled visage of the Suzerain cannot be seen. The Suzerain Sees You.",
		"standard": true,
		"cost": 20,
		"one_time": {"approval": {"avantist": 5, "other": -4}},
		"monthly": {"conversion": 0.003},
	},
	"public_broadcast": {
		"name": "Public Broadcast System",
		"desc": "Loudspeakers across the city. Unlocks: Speeches of the Suzerain.",
		"cost": 40,
		"one_time": {"unlock_policy": "speeches_of_the_suzerain"},
	},
	"speeches_of_the_suzerain": {
		"name": "Speeches of the Suzerain",
		"desc": "Recordings of the Dictator at regular intervals. Pleases Avantists, raises conversion.",
		"requires_policy": "public_broadcast",
		"cost": 10,
		"one_time": {"approval": {"avantist": 6}},
		"monthly": {"conversion": 0.003, "approval": {"avantist": 0.2}},
	},
	"curfew": {
		"name": "Impose Curfews",
		"desc": "Civilian population not allowed out after dark. Makes everyone unhappy but greatly reduces Organized Resistance.",
		"cost": 10,
		"one_time": {"approval": {"avantist": -4, "imagist": -6, "fragmentist": -6, "other": -6}},
		"monthly": {"or_sub": 1.0, "approval": {"avantist": -0.3, "imagist": -0.4, "fragmentist": -0.4, "other": -0.4}},
	},
	"worker_bonuses": {
		"name": "Worker Bonuses",
		"desc": "All who labour for the cause are beloved by the Suzerain. Costs money monthly; makes everyone happier and converts some to Avantism.",
		"cost": 0,
		"monthly": {"money_per_pop": -0.002, "approval": {"avantist": 0.4, "imagist": 0.3, "fragmentist": 0.3, "other": 0.4}, "conversion": 0.002},
	},
	"research_subsidies": {
		"name": "Research Subsidies",
		"desc": "State funding for research. +0.5 Research Speed; reduces Money income.",
		"cost": 20,
		"monthly": {"research_speed_add": 0.5, "money_per_pop": -0.001},
	},
	"secularisation_education": {
		"name": "Secularisation Education Program",
		"desc": "Slowly converts Imagists into Other population, who are far easier to convert into Avantists.",
		"requires_research": "population_assessment",
		"cost": 30,
		"one_time": {"approval": {"imagist": -8}},
		"monthly": {"imagist_to_other": 0.004},
	},
	"reserve_the_gendarmerie": {
		"name": "Reserve the Gendarmerie",
		"desc": "Increases Military Attrition, but only Militia are ever lost to it.",
		"cost": 0,
		"monthly": {"attrition_add": 0.01, "attrition_militia_only": true},
	},
}

# ------------------------------------------------------------------ research

const RESEARCH := {
	"population_assessment": {
		"name": "Population Assessment",
		"cost": 2,
		"desc": "Unlock detailed per-faction approval figures in the Population tab and unlock the Secularisation Education Program.",
		"unlocks": "policy:secularisation_education",
	},
	"industrial_efficiency_1": {
		"name": "Industrial Efficiency (I)",
		"cost": 3,
		"desc": "Factory output +25%.",
	},
	"industrial_efficiency_2": {
		"name": "Industrial Efficiency (II)",
		"cost": 5,
		"requires": "industrial_efficiency_1",
		"desc": "Factory output +25% again.",
	},
	"lab_programs": {
		"name": "Laboratory Programs",
		"cost": 3,
		"desc": "Unlock the R&D Laboratory for construction.",
		"unlocks": "building:rdlab",
	},
	"power_grid": {
		"name": "Power Grid",
		"cost": 4,
		"desc": "Unlock the Power Station for construction.",
		"unlocks": "building:power_station",
	},
	"biomed_science": {
		"name": "Biomedical Science",
		"cost": 4,
		"desc": "Unlock the Biomedical Centre for construction.",
		"unlocks": "building:biomedical",
	},
	"architectural_programs": {
		"name": "Architectural Programs",
		"cost": 4,
		"desc": "Unlock the Architectural Monument for construction.",
		"unlocks": "building:monument",
	},
	"automated_defences": {
		"name": "Automated Defences",
		"cost": 5,
		"desc": "Unlock Automated Defences for construction.",
		"unlocks": "building:autodefence",
	},
	"spectacle_combat": {
		"name": "Spectacle Combat",
		"cost": 4,
		"desc": "Unlock the Amphitheatre for construction.",
		"unlocks": "building:amphitheatre",
	},
	"arena_testing": {
		"name": "Arena Testing",
		"cost": 3,
		"requires": "spectacle_combat",
		"desc": "Amphitheatres now also provide +0.3 Research Speed each.",
	},
	"multi_purpose_equipment": {
		"name": "Multi-purpose Equipment",
		"cost": 3,
		"desc": "Gendarmes now require only 2 Basic Military Equipment instead of 3.",
	},
	"animal_control_training": {
		"name": "Animal Control Training",
		"cost": 3,
		"desc": "Specialist Militia are -1 casualty against Wildlife.",
	},
	"combat_doctrine": {
		"name": "Combat Doctrine",
		"cost": 2,
		"desc": "Attack options in hostile context menus display casualty ranges.",
	},
	"contact_imagists": {
		"name": "Find the Imagist Leadership",
		"cost": 4,
		"desc": "Make contact with a pliable local Imagist leader. Unlocks the Pater-Aleph as an advisor.",
		"unlocks": "advisor:pater_aleph",
	},
	"contact_fragmentists": {
		"name": "Find the Fragmentist Leadership",
		"cost": 4,
		"desc": "Make contact with a reformer among the Fragmentists. Unlocks the Esotechnist as an advisor.",
		"unlocks": "advisor:esotechnist",
	},
	"decode_languages": {
		"name": "Decode the Archaic Languages",
		"cost": 6,
		"desc": "Specialist agents learn the Imagist languages. On completion: reduces Organized Resistance and converts some Imagists to Avantists.",
		"complete_effects": {"or_sub": 8, "convert_imagist_to_avantist": 0.02},
		"hidden": true,
	},
}

# -------------------------------------------------------------------- starts

const STARTS := {
	"local_revol": {
		"name": "Local Revolutionary",
		"desc": "You led the insurrectionary cell that flung open the gates before the Avantist armies arrived. Infrastructure is scarred by the fighting; the population is divided; the Directorate is moderately satisfied.",
		"ruin_chance": 0.18,
		"pop": {"avantist": 1200, "imagist": 800, "fragmentist": 600, "other": 1400},
		"approval": {"avantist": 55, "imagist": 48, "fragmentist": 44, "other": 52,
			"directorate": 50, "composition": 50},
		"or": 8.0,
		"res": {"money": 180, "food": 130, "basic_goods": 40, "luxury_goods": 8,
			"basic_mil": 30, "special_mil": 8},
		"soldiers": {"militia": 40, "specialist": 10, "gendarme": 8},
	},
	"monarch": {
		"name": "Former Monarch",
		"desc": "You governed before the Avantists came and negotiated a bloodless annexation. The infrastructure is intact and the locals respect you — but the Directorate and Composition regard you with suspicion.",
		"ruin_chance": 0.0,
		"pop": {"avantist": 600, "imagist": 1000, "fragmentist": 600, "other": 1800},
		"approval": {"avantist": 45, "imagist": 58, "fragmentist": 50, "other": 65,
			"directorate": 35, "composition": 35},
		"or": 6.0,
		"res": {"money": 220, "food": 140, "basic_goods": 45, "luxury_goods": 10,
			"basic_mil": 25, "special_mil": 8},
		"soldiers": {"militia": 35, "specialist": 8, "gendarme": 6},
	},
	"appointee": {
		"name": "Directorate Appointee",
		"desc": "You were dispatched from Cardiaque to a city that resisted the tide and was broken for it. The Satrapy is a wreck, most of the locals hate you, and the central government trusts you most of anyone.",
		"ruin_chance": 0.35,
		"pop": {"avantist": 1800, "imagist": 600, "fragmentist": 400, "other": 1200},
		"approval": {"avantist": 62, "imagist": 38, "fragmentist": 34, "other": 30,
			"directorate": 70, "composition": 70},
		"or": 14.0,
		"res": {"money": 150, "food": 110, "basic_goods": 30, "luxury_goods": 5,
			"basic_mil": 35, "special_mil": 10},
		"soldiers": {"militia": 45, "specialist": 12, "gendarme": 10},
	},
}

# ------------------------------------------------------------------ advisors

const ADVISORS := {
	"vizier": {
		"name": "The Vizier",
		"title": "Interfaces with the People",
		"lines": [
			"The people's mood runs with the price of bread, Satrap. Keep the granaries full and the queues short.",
			"They do not ask for much: food, goods, safety, and that their children are not dragged into the factories.",
			"If the Avantist share of the population grows, the Directorate will notice. So will the others.",
		],
		"actions": [
			{"id": "vizier_survey", "label": "Order a civic survey (-0.2 Research Speed, small approval for all)", "cooldown": 3,
				"effects": {"approval": {"avantist": 2, "imagist": 2, "fragmentist": 2, "other": 2}, "research_speed_mod": -0.2, "duration": 3}},
			{"id": "vizier_charity", "label": "Distribute relief goods (needs 20 Food, 10 Basic Goods)", "cooldown": 4,
				"effects": {"res": {"food": -20, "basic_goods": -10}, "approval": {"avantist": 3, "imagist": 4, "fragmentist": 4, "other": 5}}},
		],
	},
	"dramaturge": {
		"name": "The Dramaturge",
		"title": "Liaison to the Adhocratic Directorate",
		"lines": [
			"Cardiaque is patient, Satrap, but its patience is a budget line. Quotas, policies, conversion. In that order.",
			"We can requisition food or funds from the centre. It costs goodwill, and goodwill is spent faster than it is earned.",
			"Every avantist policy you implement is a line in a report that makes your name shine in the capital.",
		],
		"actions": [
			{"id": "dramaturge_food", "label": "Requisition a food convoy (Directorate -4 Approval)", "cooldown": 4,
				"effects": {"res": {"food": 60}, "approval": {"directorate": -4}}},
			{"id": "dramaturge_money", "label": "Request emergency funds (Directorate -5 Approval)", "cooldown": 5,
				"effects": {"res": {"money": 80}, "approval": {"directorate": -5}}},
			{"id": "dramaturge_colonists", "label": "Petition for Avantist colonists (Directorate -3 Approval)", "cooldown": 6,
				"effects": {"pop": {"avantist": 150}, "approval": {"directorate": -3}}},
		],
	},
	"attache": {
		"name": "The Attache",
		"title": "Liaison to the Militant Composition",
		"lines": [
			"The Composition's concern is simple: threats dealt with, quotas supplied, and the Circulatory kept in its holes.",
			"We can send a shipment of equipment or a company of troops. The ledger remembers such kindness — and charges interest.",
			"Remember: Gendarmes belong to the Composition. Train them, and they will be called home.",
		],
		"actions": [
			{"id": "attache_equipment", "label": "Request equipment shipment (Composition -4 Approval)", "cooldown": 4,
				"effects": {"res": {"basic_mil": 20, "special_mil": 8}, "approval": {"composition": -4}}},
			{"id": "attache_troops", "label": "Request a company of Militia (Composition -5 Approval)", "cooldown": 6,
				"effects": {"soldiers": {"militia": 20}, "approval": {"composition": -5}}},
		],
	},
	"pater_aleph": {
		"name": "The Pater-Aleph",
		"title": "Leader of the Imagists — an aged pragmatist",
		"lines": [
			"\"We have guarded this land since your revolution was a scribble. Treat our people well, and we will keep the peace.\"",
			"\"There are stores of our people's — of the old empire's — hidden in the hills. I know where.\"",
			"\"Our congregations are not your enemies, Satrap. Your beaters and your murals are.\"",
		],
		"actions": [
			{"id": "pater_caches", "label": "Open the Ramonid supply caches (Imagists -6 Approval)", "cooldown": 6,
				"effects": {"res": {"food": 50, "basic_goods": 30, "luxury_goods": 10}, "approval": {"imagist": -6}}},
			{"id": "pater_quiet", "label": "Ask the congregations to stand down (Organized Resistance -8, Imagists -3)", "cooldown": 5,
				"effects": {"or_sub": 8, "approval": {"imagist": -3}}},
		],
	},
	"esotechnist": {
		"name": "The Esotechnist",
		"title": "Reformer of the Fragmentists",
		"lines": [
			"\"The machines beneath the soil answer to the old names. We can teach you a few of them.\"",
			"\"We have given up the worst of the rites, as the Suzerain demanded. Do not ask us to give up more.\"",
			"\"The Mechanoids are not our fault, Satrap. But we can make them less of a problem.\"",
		],
		"actions": [
			{"id": "esot_mechanoid", "label": "Invoke a rite to unmake one Mechanoid (Fragmentists -4 Approval)", "cooldown": 3,
				"effects": {"approval": {"fragmentist": -4}, "kill_mechanoid": true}},
			{"id": "esot_knowledge", "label": "Exchange forbidden knowledge (+0.5 Research Speed for 6 months, Fragmentists -2)", "cooldown": 6,
				"effects": {"research_speed_mod": 0.5, "duration": 6, "approval": {"fragmentist": -2}}},
		],
	},
	"excoriator": {
		"name": "The Solar Excoriator",
		"title": "Replacement for the Pater-Aleph. Speaks only of liquidation.",
		"lines": [
			"The Imagist remnants are a stain on the vision. The Directorate has provided the means. The question is only the scale.",
		],
		"actions": [
			{"id": "exco_purge", "label": "Oversee a purge action (Imagists -20, Avantists +10, Organized Resistance +6)", "cooldown": 8,
				"effects": {"approval": {"imagist": -20, "avantist": 10}, "or_add": 6, "convert_imagist_to_avantist": 0.05, "tag": "purge"}},
		],
	},
	"exterminator": {
		"name": "The Artiste-Exterminator",
		"title": "Replacement for the Esotechnist. Speaks only of erasure.",
		"lines": [
			"The Fragmentist cults must be removed from the record. The machinery, of course, will be kept for the state.",
		],
		"actions": [
			{"id": "exterm_purge", "label": "Oversee a purge action (Fragmentists -20, Avantists +10, Organized Resistance +6)", "cooldown": 8,
				"effects": {"approval": {"fragmentist": -20, "avantist": 10}, "or_add": 6, "convert_fragmentist_to_avantist": 0.05, "tag": "purge"}},
		],
	},
}

# --------------------------------------------------------------------- events
## cond: {"approval_min": {...}, "hostiles_min": N, "has_policy": id, "research_done": id, "month_min": N}
## effects: data dict for Game.apply_effects

const EVENTS := [
	{
		"id": "archaic_languages",
		"title": "The Archaic Tongues",
		"text": "Reports: Imagist communities are increasingly using archaic languages for sermons, public events, and even on the streets. While all the population is fluent in Accordian, only the Imagists have widespread familiarity with these. This is unnerving the rest of the population, and the gendarmerie is concerned the languages are being used to secretly organize. What should be done?",
		"options": [
			{"text": "Permit. The risks are marginal; better not to offend the Imagists. Make a show of our tolerance.",
				"effects": {"approval": {"imagist": 6, "avantist": -3, "other": -3}, "or_add": 1}, "tag": "inaction"},
			{"text": "Prohibit. Public use of any irregular language will be punished with public beatings.",
				"effects": {"approval": {"imagist": -14, "other": 3, "avantist": 2}, "attrition_add": 0.005, "duration": 3, "or_sub": 4}, "tag": "suppression"},
			{"text": "Crackdown. Detain and question those involved in any gathering. Execute the organizers; hold tribunals for the rest.",
				"effects": {"approval": {"imagist": -18, "avantist": 4}, "or_sub": 7, "suspicion": 5}, "tag": "purge"},
			{"text": "Decode. Specialist agents can learn the languages. In the long term, understanding what they think we cannot will be more useful than forcing them to speak out of earshot.",
				"effects": {"unlock_research": "decode_languages", "research_speed_mod": -0.1, "duration": 6}, "tag": "curiosity"},
			{"text": "Integrate. Recruit trusted Imagist collaborators as informants, translators and code-talkers.",
				"cond": {"approval_min": {"imagist": 70}},
				"effects": {"approval": {"imagist": 8, "avantist": 6}, "or_sub": 10}, "tag": "collab_imagist"},
		],
	},
	{
		"id": "witch",
		"title": "The Witch of the Road",
		"text": "A small group has approached the city. When soldiers intercepted them, their leader declared herself a Witch of substantial ability, the rest her servants. She claims ideological sympathy for Avantism and offers her technical services in exchange for sanctuary. Such skills, if genuine, could benefit your research pursuits — but the presence of a Witch is a dangerous prospect, sure to alarm the populace.",
		"options": [
			{"text": "Politely refuse and turn the group away. The risks are not worth the gain; better not to offend a Witch.",
				"effects": {"hidden_assets": 1, "event_log": "She leaves a token of shimmering red orichalcoid metal as a gift."}, "tag": "curiosity"},
			{"text": "Seize the group and prepare their executions. We will not sully Avantism with such profanity; the spectacle will please the populace.",
				"effects": {"approval": {"avantist": 4, "fragmentist": 8, "other": 3}, "spawn_hostiles": {"mechanoid": 3}, "suspicion": 8}, "tag": "purge"},
			{"text": "Accept the offer. There is nothing Avantism cannot integrate. Caution would be cowardice.",
				"effects": {"approval": {"avantist": -4, "imagist": -6, "fragmentist": -12, "other": -5}, "research_speed_mod": 0.5, "duration": 12}, "tag": "collab_fragmentist"},
			{"text": "Seize the group and turn them over to Fragmentist collaborators. The Witch's talents can be exploited without risk of malfeasance — in the dark, on our terms.",
				"cond": {"approval_min": {"fragmentist": 70}},
				"effects": {"approval": {"fragmentist": 8}, "research_speed_mod": 0.5, "duration": 12, "spawn_hostiles": {"mechanoid": 3}, "suspicion": 4}, "tag": "collab_fragmentist"},
		],
	},
	{
		"id": "counter_lit",
		"title": "Counterrevolutionary Literature",
		"text": "Gendarmerie investigators have uncovered a cache of seditious pamphlets: 'THE SUZERAIN IS A MACHINE' and 'BREAD BEFORE BULL'. Copies are already circulating in the market districts. What should be done?",
		"options": [
			{"text": "Launch an education campaign refuting the material, point by point.",
				"effects": {"res": {"money": -15}, "approval": {"avantist": 3, "other": 2}, "or_sub": 2}, "tag": "inaction"},
			{"text": "Arrest anyone found in possession of the material.",
				"effects": {"approval": {"other": -4, "imagist": -4, "avantist": 4}, "or_sub": 5}, "tag": "suppression"},
			{"text": "Ignore it. The revolution outgrows its slander.",
				"effects": {"or_add": 3, "suspicion": 2}, "tag": "inaction"},
		],
		"month_min": 3,
	},
	{
		"id": "standoff",
		"title": "A Street of Two Faiths",
		"text": "Imagists and Fragmentists have come to a public standoff on the old market street — processions meeting processions, sermons answering rituals, and a growing crowd of Other citizens caught between them. Violence is one bad word away.",
		"options": [
			{"text": "Send the Militia to break up both processions by force.",
				"effects": {"approval": {"imagist": -8, "fragmentist": -8, "avantist": 3}, "or_sub": 3, "attrition_add": 0.005, "duration": 2}, "tag": "suppression"},
			{"text": "Impose temporary travel restrictions between the districts.",
				"effects": {"approval": {"imagist": -4, "fragmentist": -4, "other": -4}, "or_sub": 2}, "tag": "suppression"},
			{"text": "Ask the religious leaders of both communities to calm their people.",
				"cond": {"approval_min": {"imagist": 60, "fragmentist": 60}},
				"effects": {"approval": {"imagist": 4, "fragmentist": 4, "other": 3}, "or_sub": 4}, "tag": "collab_imagist"},
		],
	},
	{
		"id": "mechanoid_panic",
		"title": "Panic in the Outer Wards",
		"text": "Mechanoids have been sighted in the outer wards and failed attacks have left citizens dead. Panic is spreading. The crowd is demanding answers — and the finger is beginning to point at the Fragmentists, who are widely scapegoated for the horrors of the Circulatory.",
		"options": [
			{"text": "Scapegoat the Fragmentists. Detain a number of their ritualists as 'sympathizers of the machines'.",
				"effects": {"approval": {"fragmentist": -18, "avantist": 4, "other": 4}, "or_add": 4, "suspicion": 6}, "tag": "purge"},
			{"text": "Publicly reassure the population: the state has the threat in hand.",
				"effects": {"approval": {"other": 3, "avantist": 2, "imagist": 1, "fragmentist": 1}, "or_sub": 2}, "tag": "inaction"},
			{"text": "Order a mass hunt: conscript citizens to man the firing lines with your troops.",
				"effects": {"soldiers": {"militia": -8}, "approval": {"other": -4, "avantist": 3}, "kill_all_hostiles": "mechanoid"}, "tag": "conscription"},
		],
		"cond": {"hostiles_min": 2, "hostile_kind": "mechanoid"},
	},
	{
		"id": "convoy",
		"title": "A Convoy From Cardiaque",
		"text": "A supply convoy has arrived from Cardiaque under the Directorate's seal. The Dramaturge's courier informs you that the centre is prepared to sell its contents at a modest discount — or to donate them, at a cost to your standing in the capital's ledgers. Either way, the choice is yours.",
		"options": [
			{"text": "Buy the contents (80 Money for 50 Food, 30 Basic Goods, 10 Specialist Mil Equip).",
				"effects": {"res": {"money": -80, "food": 50, "basic_goods": 30, "special_mil": 10}}, "tag": "inaction"},
			{"text": "Accept the donation (Directorate -6 Approval, 40 Food, 20 Basic Goods).",
				"effects": {"res": {"food": 40, "basic_goods": 20}, "approval": {"directorate": -6}}, "tag": "inaction"},
			{"text": "Decline. The Satrapy provides for itself.",
				"effects": {"approval": {"directorate": -2, "avantist": 2}}, "tag": "inaction"},
		],
	},
	{
		"id": "plague",
		"title": "Fever in the Wards",
		"text": "A fever has broken out in the crowded inner wards. The physicians — such as they are — are asking for resources to isolate the sick, and the population is frightened.",
		"options": [
			{"text": "Fund the quarantine and medical response (40 Money, 20 Food).",
				"effects": {"res": {"money": -40, "food": -20}, "approval": {"avantist": 2, "imagist": 2, "fragmentist": 2, "other": 6}, "pop_loss_fraction": 0.0}, "tag": "inaction"},
			{"text": "Let it run its course. The strong survive.",
				"effects": {"pop_loss_fraction": 0.03, "approval": {"other": -8, "avantist": -4, "imagist": -5, "fragmentist": -5}}, "tag": "inaction"},
		],
	},
	{
		"id": "festival",
		"title": "A Festival of the Vision",
		"text": "The Avantist communities have proposed a public festival celebrating the anniversary of the annexation: processions, music, the works of the artists, and a great mural of the Suzerain completed before the crowd. It will cost, and it will be seen from every window.",
		"options": [
			{"text": "Fund the festival (30 Money).",
				"effects": {"res": {"money": -30}, "approval": {"avantist": 10, "other": 2, "imagist": -3, "fragmentist": -3}, "conversion": 0.01, "once": true}, "tag": "inaction"},
			{"text": "Decline. The people have enough to worry about.",
				"effects": {"approval": {"avantist": -4}}, "tag": "inaction"},
		],
		"cond": {"building_min": {"amphitheatre": 1}},
	},
	{
		"id": "defector",
		"title": "A Defector at the Gate",
		"text": "An officer of the old regime's guard — if the stories are true, a former commander — has walked to the Administrative Building and surrendered himself, his sidearm, and what he claims are intelligence on insurgent cells in the region. The Directorate wants a ruling.",
		"options": [
			{"text": "Detain and interrogate him under state authority.",
				"effects": {"or_sub": 6, "approval": {"directorate": 2}}, "tag": "curiosity"},
			{"text": "Execute him publicly as a traitor to the old order.",
				"effects": {"approval": {"avantist": 5, "other": -3}, "or_add": 2, "suspicion": 3}, "tag": "purge"},
			{"text": "Release him into the population.",
				"effects": {"or_add": 6, "approval": {"other": 2}}, "tag": "inaction"},
		],
		"month_min": 4,
	},
]

# achievements: id -> {name, desc, check: callable-name on Game}
const ACHIEVEMENTS := {
	"the_suzerain_sees_you": {"name": "THE SUZERAIN SEES YOU", "desc": "Beat the game."},
	"the_suzerain_loves_you": {"name": "THE SUZERAIN LOVES YOU", "desc": "Beat the game with the Suzerain's pleasure."},
	"tired_aparatchik": {"name": "TIRELESS APARATCHIK", "desc": "Reach 100% approval with the Directorate."},
	"patron_of_the_arts": {"name": "PATRON OF THE ARTS", "desc": "Reach 100% approval with the Composition."},
	"radical_populist": {"name": "RADICAL POPULIST", "desc": "Reach 95% average approval with the People."},
	"a_friendly_fanatic": {"name": "A FRIENDLY FANATIC", "desc": "Reach 95% approval with the Avantists."},
	"my_brothers_keeper": {"name": "MY BROTHER'S KEEPER", "desc": "Reach 95% approval with the Imagists."},
	"in_found_carcosa": {"name": "IN FOUND CARCOSA", "desc": "Reach 95% approval with the Fragmentists."},
	"a_hundred_flowers_bloom": {"name": "A HUNDRED FLOWERS BLOOM", "desc": "Reach 95% approval with the Unaligned."},
	"revolutionary_consensus": {"name": "REVOLUTIONARY CONSENSUS", "desc": "Have more than 95% of the population Avantist."},
	"least_committed_radical": {"name": "LEAST COMMITTED RADICAL", "desc": "Have less than 5% of the population Avantist."},
	"centricide": {"name": "CENTRICIDE", "desc": "Have less than 5% of the population Unaligned."},
	"industrial_revolution": {"name": "INDUSTRIAL REVOLUTION", "desc": "Have 20 factories in operation."},
	"are_you_not_entertained": {"name": "ARE YOU NOT ENTERTAINED?", "desc": "Have 5 amphitheatres in operation."},
	"hallowed_ground": {"name": "HALLOWED GROUND", "desc": "Have 5 temples in operation."},
	"in_the_shadows_of_the_guns": {"name": "IN THE SHADOWS OF THE GUNS", "desc": "Have 20 outposts in operation."},
	"infinite_city_sprawl": {"name": "INFINITE CITY SPRAWL", "desc": "Have 100 buildings."},
	"technology_shall_lead": {"name": "TECHNOLOGY SHALL LEAD THE WAY", "desc": "Have over 2.0 Research Speed."},
	"war_against_the_present": {"name": "WAR AGAINST THE PRESENT", "desc": "Have over 4.0 Research Speed."},
	"friends_in_low_places": {"name": "FRIENDS IN LOW PLACES", "desc": "Resolve 5 events with the support of the Fragmentists."},
	"deus_vult": {"name": "DEUS VULT", "desc": "Resolve 5 events with the support of the Imagists."},
	"nobodycaresanymoreism": {"name": "NOBODYCARESANYMOREISM", "desc": "Resolve 15 events with inaction."},
	"until_morale_improves": {"name": "UNTIL MORALE IMPROVES", "desc": "Resolve 15 events with suppression and beatings."},
	"one_day_in_the_life": {"name": "ONE DAY IN THE LIFE", "desc": "Resolve 15 events with penal conscriptions."},
	"spectacle_and_expedience": {"name": "SPECTACLE AND EXPEDIENCE", "desc": "Resolve 15 events with executions and purges."},
}
