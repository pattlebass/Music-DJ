extends "res://scenes/DialogScript.gd"

var selected_file = ""
var button_scene = preload("res://scenes/LoadButton.tscn")


func _ready():
	GlobalVariables.connect("theme_changed", self, "on_theme_changed")


func _on_OkButton_pressed():
	load_song(main.user_dir+"Projects/"+selected_file)
	

func load_song(_path, _song = null):
	if _song:
		main.song = _song
	else:
		var file = File.new()
		file.open(_path, File.READ)
		if _path.ends_with(".mdj"):
			var json_result = JSON.parse(file.get_as_text())
			if json_result.error: # Godot dictionary
				main.song = file.get_var()
			else: # JSON format
				main.song = json_result.result
			file.close()
		else: # .mdjt
			main.song = str2var(file.get_as_text())
			file.close()
			var dir = Directory.new()
			dir.remove(_path)
			_path.erase(_path.length()-1, 1)
			file.open(_path, File.WRITE)
			file.store_var(main.song)
			file.close()
	
	# Add remaining columns
	var song_column_index = main.song[0].size()
	
	if main.column_index < song_column_index:
		for i in song_column_index - main.column_index:
			main.add_column(main.column_index, false)
			main.column_index += 1

	elif main.column_index > song_column_index:
		for i in main.column_index - song_column_index:
			main.get_node("HBoxContainer/StepContainer/HBoxContainer").get_child(main.column_index-1).queue_free()
			main.column_index -= 1
		
		
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


func on_theme_changed(new_theme):
	$VBoxContainer/TitleHBox/OpenButton.icon = load("res://assets/themes/%s/open_folder.png" % new_theme)


func about_to_show():
	# Check for permissions
	OS.request_permissions()
	yield(get_tree(), "idle_frame")
	if OS.get_granted_permissions().empty() && OS.get_name() == "Android":
		hide()
	
	if OS.get_name() == "HTML5":
		$VBoxContainer/TitleHBox/OpenButton.hide()
	$VBoxContainer/HBoxContainer/OkButton.disabled = true
	if list_files_in_directory(main.user_dir+"Projects/").empty():
		$VBoxContainer/ScrollContainer/VBoxContainer/NoProjectsLabel.show()
	else:
		$VBoxContainer/ScrollContainer/VBoxContainer/NoProjectsLabel.hide()
	
	for i in list_files_in_directory(main.user_dir+"Projects/"):
		var button_container = button_scene.instance()
		var load_button = button_container.get_node("LoadButton")
		var delete_button = button_container.get_node("DeleteButton")
		var download_button = button_container.get_node("DownloadButton")
		
		load_button.text = i
		load_button.connect("pressed", self, "on_Button_selected", [i])
		
		delete_button.connect("pressed", self, "on_Button_deleted", [button_container])
		
		if OS.get_name() == "HTML5":
			download_button.connect("pressed", self, "on_Button_download", [button_container])
		else:
			download_button.hide()
		
		$VBoxContainer/ScrollContainer/VBoxContainer.add_child(button_container)
		
	.about_to_show()


func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and (file.ends_with(".mdj") or file.ends_with(".mdjt")):
			files.append(file)

	dir.list_dir_end()

	return files


func on_Button_selected(_path):
	if _path == selected_file:
		for i in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
			for x in i.get_children():
				if x is Button and x.text == _path:
					x.pressed = true
	
	selected_file = _path
	$VBoxContainer/HBoxContainer/OkButton.disabled = false
	
	for i in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		for x in i.get_children():
			if x is Button and x.text != _path:
				x.pressed = false


func popup_hide():
	.popup_hide()
	for i in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		if i is HBoxContainer:
			i.queue_free()


func _on_CancelButton_pressed():
	hide()


func _on_OpenButton_pressed():
	if OS.get_name() == "Android":
		OS.alert(ProjectSettings.globalize_path(main.user_dir), "Folder location")
	else:
		OS.shell_open(ProjectSettings.globalize_path(main.user_dir))


func on_Button_deleted(_container):
	var dir = Directory.new()
	var _path = _container.get_child(0).text
	var dialog = preload("res://scenes/ConfirmationDialog.tscn").instance()
	
	main.add_child(dialog)
	dialog.alert("Are you sure?","[color=#4ecca3]%s[/color] will be deleted." %_path.substr(0, 20))
	var choice = yield(dialog, "chose")
	if choice:
		dir.remove(main.user_dir+"Projects/"+_path)
		_container.queue_free()


func on_Button_download(_container):
	var file_name = _container.get_child(0).text
	main.get_node("SaveDialog").download_file(main.user_dir+"Projects/"+file_name, file_name)
