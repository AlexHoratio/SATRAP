extends Node2D
class_name Hostile
## A hostile force on the map: humanoid, wildlife, or mechanoid.

var kind := "humanoid"
var hp := 100
var hovering := false
var _sprite: Sprite2D = null

const TILE := 32

func _ready() -> void:
	var spr := Sprite2D.new()
	_sprite = spr
	spr.texture = load(Data.HOSTILES[kind]["sprite"])
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spr)

func _process(_delta: float) -> void:
	if _sprite:
		var target := 1.15 if hovering else 1.0
		_sprite.scale = _sprite.scale.lerp(Vector2(target, target), 0.3)
	# slow menacing pulse
	if _sprite:
		_sprite.modulate = Color(1, 1, 1) if int(Time.get_ticks_msec() / 500) % 2 == 0 else Color(0.85, 0.85, 0.85)

func info_text() -> String:
	var d: Dictionary = Data.HOSTILES[kind]
	var t: String = "> " + d["name"].to_upper() + "
" + d["desc"] + "

"
	t += "Attack options (right-click to attack):\n"
	for u in ["militia", "specialist", "gendarme"]:
		var base := int(Data.COMBAT_BASE[kind][u])
		var range_txt
		if "combat_doctrine" in Game.research_done:
			range_txt = "casualties 0–" + str(base)
		else:
			range_txt = "casualties ?"
		var c := Game.training_cost(u)
		var cost_txt := "cost " + str(c.basic_mil) + " basic" + (", " + str(c.special_mil) + " special" if c.special_mil > 0 else "")
		t += "  - " + u.capitalize() + " (" + range_txt + ", " + cost_txt + ")\n"
	t += "\n" + str(Game.available_soldiers()) + " soldiers available."
	return t

func context_options() -> Array:
	var opts := []
	for u in ["militia", "specialist", "gendarme"]:
		var has: bool = Game.soldiers[u] > 0
		var base := int(Data.COMBAT_BASE[kind][u])
		var label: String = "Attack with " + u.capitalize().capitalize() + " (" + ("0–" + str(base) if "combat_doctrine" in Game.research_done else "casualties ?") + ")"
		opts.append({"label": label, "enabled": has, "action": Callable(Game, "attack_hostile").bind(self, u)})
	if Game.advisor_available("esotechnist") and kind == "mechanoid":
		opts.append({"label": "Esotechnist: invoke a rite (Fragmentists -4)", "enabled": Game.advisor_cooldowns.get("esotechnist:esot_mechanoid", 0) == 0, "action": Callable(Game, "perform_advisor_action").bind("esotechnist", "esot_mechanoid")})
	return opts
