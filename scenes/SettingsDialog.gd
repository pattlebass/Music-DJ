extends "res://scenes/DialogScript.gd"


func _ready():
	get_node("VBoxContainer/ScrollContainer/SettingsContainer/ThemeContainer/"+GlobalVariables.options.theme.capitalize()).pressed = true
	$VBoxContainer/ScrollContainer/SettingsContainer/ThemeContainer/Label.theme = load("res://assets/themes/%s/theme2.tres" % GlobalVariables.options.theme)
	#$VBoxContainer/HSeparator.theme = GlobalVariables.theme_resource
	#$VBoxContainer/HSeparator2.theme = GlobalVariables.theme_resource
	#$VBoxContainer/ScrollContainer/SettingsContainer/HSeparator.theme = GlobalVariables.theme_resource
	
	
func _on_CloseButton_pressed():
	hide()


func _on_theme_chosen(button_pressed, extra_arg_0):
	if button_pressed and visible:
		GlobalVariables.change_theme(extra_arg_0)
		GlobalVariables.options.theme = extra_arg_0
		#GlobalVariables.last_song = main.song
		GlobalVariables.save_options()
		#get_tree().reload_current_scene()


func _on_ShowTutorial_pressed():
	main.get_node("TutorialDialog").popup_centered()
	hide()
