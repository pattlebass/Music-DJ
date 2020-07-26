extends PopupDialog

onready var main = get_parent()
var selected_file = ""

func _on_OkButton_pressed():
	hide()
	
	var file = File.new()
	file.open("user://saves/"+selected_file, File.READ)
	main.song = file.get_var()
	

func _on_LoadDialog_about_to_show():
	$VBoxContainer/HBoxContainer/OkButton.disabled = true
	for i in list_files_in_directory("user://saves"):
		var button = Button.new()
		
		button.text = i
		button.align = Button.ALIGN_LEFT
		button.theme = preload("res://assets/theme 2.tres")
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Button.MOUSE_FILTER_PASS
		button.toggle_mode = true
		button.connect("pressed", self, "on_Button_selected", [i])
		
		main.get_node("LoadDialog/VBoxContainer/ScrollContainer/VBoxContainer").add_child(button)


func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.ends_with(".mdj"):
			files.append(file)

	dir.list_dir_end()

	return files

func on_Button_selected(_path):
	if _path == selected_file:
		for i in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
			if i.text == _path:
				i.pressed = true
	
	selected_file = _path
	$VBoxContainer/HBoxContainer/OkButton.disabled = false
	
	for i in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		if i.text != _path:
			i.pressed = false


func _on_LoadDialog_popup_hide():
	for i in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		i.queue_free()


func _on_CancelButton_pressed():
	hide()
