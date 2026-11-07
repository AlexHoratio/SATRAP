extends Control

func _ready():
	for button in $advisors.get_children():
		button.pressed.connect(ask_advisor.bind(button.name))
		
		if Advisors.event_comments[get_parent().name][button.name] == "":
			button.disabled = true
		
func ask_advisor(advisor_name) -> void:
	if Advisors.event_comments[get_parent().name][advisor_name] != "":
		$advice.text = "[center][color=#8f8][i]The " + advisor_name.to_pascal_case() + " says...[/i][color=#0f0]\n\n" + Advisors.event_comments[get_parent().name][advisor_name]
		$advice_expire.start()

func _on_advice_expire_timeout():
	$advice.text = ""
