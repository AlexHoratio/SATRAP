extends Node

var policy_information = {
	"standardize_currency": {
		"name": "Standardize Currency",
		"desc": "[color=#47ff47]Make everything the same currency. Makes sense right?? Well it better. Because this is a sensible policy that you want to select, probably. "
	},
	"education_reform": {
		"name": "Education Reform",
		"desc": "opdfopfkdo fkapod fopka"
	}
}

var available_policies = []


func ready() -> void:
	pass
	
func update_available_policies() -> void:
	available_policies = []
	
	if not("standardize_currency" in Events.event_decisions.keys()):
		available_policies.append("standardize_currency")
	
	if not("education_reform" in Events.event_decisions.keys()):
		available_policies.append("education_reform")
