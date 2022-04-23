extends "res://scenes/DialogScript.gd"


func _ready():
	get_node("VBoxContainer/ScrollContainer/SettingsContainer/ThemeContainer/"+GlobalVariables.options.theme.capitalize()).pressed = true


func _on_CloseButton_pressed():
	hide()


func _on_theme_chosen(button_pressed, extra_arg_0):
	if button_pressed and visible:
		GlobalVariables.change_theme(extra_arg_0)
		GlobalVariables.options.theme = extra_arg_0
		GlobalVariables.save_options()


func _on_ShowTutorial_pressed():
	main.get_node("TutorialDialog").popup_centered()
	hide()
