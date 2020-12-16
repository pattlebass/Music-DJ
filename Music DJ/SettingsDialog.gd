extends PopupDialog

onready var main = get_parent()

func _ready():
	$VBoxContainer/HBoxContainer/OptionButton.selected = GlobalVariables.themes.find(GlobalVariables.options.theme)
	theme = load("res://assets/themes/%s/theme.tres" % GlobalVariables.options.theme)

func _on_OptionButton_item_selected(index):
	#print(GlobalVariables.themes[index])
	GlobalVariables.options.theme = GlobalVariables.themes[index]
	GlobalVariables.last_song = main.song
	GlobalVariables.save_options()
	get_tree().reload_current_scene()


func _on_CloseButton_pressed():
	hide()
