extends PopupDialog

onready var main = get_parent()
var selected_file = ""


func _on_OkButton_pressed():
	var file = File.new()
	file.open(main.user_dir+"Projects/"+selected_file, File.READ)
	main.song = file.get_var()
	
	# Clear last_columns
	main.last_columns.clear()
	main.last_columns.append(-1)

	for instrument in main.song.size():
		for column_no in main.song[instrument].size():
			var column = main.get_node("HBoxContainer/StepContainer/HBoxContainer").get_child(column_no)
			var button = column.get_child(instrument + 1)
			var value = main.song[instrument][column_no]
			
			if value == 0:
				button.text = ""
				button.set("custom_styles/normal", null)
				button.set("custom_styles/pressed", null)
				button.set("custom_styles/disabled", null)
				button.set("custom_styles/hover", null)
				
				continue
			
			# Find last columns
			if column_no > main.last_columns.back() and not main.last_columns.has(column_no):
				print(column_no)
				main.last_columns.append(column_no)

			# Button
			var text
			var style_box = preload("res://assets/button_stylebox.tres").duplicate()
			var colors = GlobalVariables.colors
			
			if value >= 1 and value <= 8:
				text = value
				style_box.bg_color = colors[0]
			elif value >= 9 and value <= 16:
				text = value - 8
				style_box.bg_color = colors[1]
			elif value >= 17 and value <= 24:
				text = value - 16
				style_box.bg_color = colors[2]
			elif value >= 25 and value <= 32:
				text = value - 24
				style_box.bg_color = colors[3]
			
			button.text = str(text)
			button.set("custom_styles/normal", style_box)
			button.set("custom_styles/pressed", style_box)
			button.set("custom_styles/disabled", style_box)
			button.set("custom_styles/hover", style_box)
			
	hide()
	
	
func _on_LoadDialog_about_to_show():
	$VBoxContainer/HBoxContainer/OkButton.disabled = true
	for i in list_files_in_directory(main.user_dir+"Projects/"):
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
