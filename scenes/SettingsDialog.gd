extends "res://scenes/DialogScript.gd"


func _ready():
	get_node("VBoxContainer/ScrollContainer/SettingsContainer/ThemeContainer/"+GlobalVariables.options.theme.capitalize()).pressed = true
	$VBoxContainer/ScrollContainer/SettingsContainer/LabelVersion.text = "%s" % load("res://version.gd").VERSION

func _on_CloseButton_pressed():
	hide()


func _on_theme_chosen(button_pressed, theme_name):
	if button_pressed and visible:
		GlobalVariables.change_theme(theme_name)
		GlobalVariables.options.theme = theme_name
		GlobalVariables.save_options()


func _on_ShowTutorial_pressed():
	hide()
	main.get_node("TutorialDialog").popup_centered()
	
