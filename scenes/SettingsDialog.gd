extends "res://scenes/DialogScript.gd"


func _ready():
	get_node("VBoxContainer/ScrollContainer/SettingsContainer/ThemeContainer/"+ \
		Variables.options.theme.capitalize()).pressed = true
	$VBoxContainer/ScrollContainer/SettingsContainer/LabelVersion.text = "%s" % load("res://version.gd").VERSION

func _on_CloseButton_pressed():
	hide()


func _on_theme_chosen(button_pressed, theme_name):
	if button_pressed and visible:
		Variables.change_theme(theme_name)
		Variables.options.theme = theme_name
		Variables.save_options()


func _on_ShowTutorial_pressed():
	hide()
	main.get_node("TutorialDialog").popup_centered()
	
