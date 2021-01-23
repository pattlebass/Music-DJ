extends PopupDialog

onready var main = get_parent()
var selected_file = ""
var button_scene = preload("res://LoadButton.tscn")


func _ready():
	theme = load("res://assets/themes/%s/theme.tres" % GlobalVariables.options.theme)


func _on_OkButton_pressed():
	load_song(main.user_dir+"Projects/"+selected_file)
	

func load_song(_path, _song = null):
	if _song:
		main.song = _song
	else:
		var file = File.new()
		file.open(_path, File.READ)
		if _path.ends_with(".mdj"):
			main.song = file.get_var()
			file.close()
		else:
			main.song = str2var(file.get_as_text())
			file.close()
			var dir = Directory.new()
			dir.remove(_path)
			_path.erase(_path.length()-1, 1)
			file.open(_path, File.WRITE)
			file.store_var(main.song)
			file.close()
	
	# Add remaining columns
	var column_index = main.column_index
	var song_column_index = main.song[0].size()
	
	if column_index != song_column_index:
		var column_scene = preload("res://Column.tscn")
		for i in song_column_index - column_index:
			column_index += 1
			var column_instance = column_scene.instance()
			column_instance.get_node("Label").text = str(column_index)
			var column_container = main.get_node("HBoxContainer/StepContainer/HBoxContainer")
			column_container.add_child(column_instance)
			var add_button = main.get_node("HBoxContainer/StepContainer/HBoxContainer/VBoxContainer")
			column_container.move_child(add_button, column_index)
			
			# Signals
			for b in 4:
				var button = column_instance.get_node("Button"+str(b+1))
				button.connect("pressed", main, "on_Tile_pressed", [column_index-1, b])
				button.connect("button_down", main, "on_Tile_held", [column_index-1, b, column_instance.get_node("Button"+str(b+1))])
			column_instance.get_node("Label").connect("pressed", main, "on_Column_Button_pressed", [column_index-1, column_instance])
			
		main.column_index = song_column_index
	
	
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
	
	
func _on_LoadDialog_about_to_show():
	# Check for permissions
	OS.request_permissions()
	yield(get_tree(), "idle_frame")
	if OS.get_granted_permissions().empty() && OS.get_name() == "Android":
		hide()
	
	if OS.get_name() == "HTML5":
		$VBoxContainer/HBoxContainer/OpenButton.hide()
	main.get_node("ShadowPanel").visible = true
	$VBoxContainer/HBoxContainer/OkButton.disabled = true
	if list_files_in_directory(main.user_dir+"Projects/").empty():
		$VBoxContainer/ScrollContainer/VBoxContainer/NoProjectsLabel.show()
	else:
		$VBoxContainer/ScrollContainer/VBoxContainer/NoProjectsLabel.hide()
	$VBoxContainer/ScrollContainer/VBoxContainer/NoProjectsLabel.theme = load("res://assets/themes/%s/theme2.tres" % GlobalVariables.options.theme)
	
	for i in list_files_in_directory(main.user_dir+"Projects/"):
		var button_container = button_scene.instance()
		var load_button = button_container.get_node("LoadButton")
		var delete_button = button_container.get_node("DeleteButton")
		var download_button = button_container.get_node("DownloadButton")
		
		button_container.theme = load("res://assets/themes/%s/theme2.tres" % GlobalVariables.options.theme)
		
		load_button.text = i
		load_button.connect("pressed", self, "on_Button_selected", [i])
		
		delete_button.connect("pressed", self, "on_Button_deleted", [button_container])
		
		if OS.get_name() == "HTML5":
			download_button.connect("pressed", self, "on_Button_download", [button_container])
		else:
			download_button.hide()
		
		$VBoxContainer/ScrollContainer/VBoxContainer.add_child(button_container)
		
	$AnimationPlayer.play("fade_in")


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


func _on_LoadDialog_popup_hide():
	visible = true
	# Animation
	$AnimationPlayer.play_backwards("fade_in")
	yield(get_tree().create_timer(0.1), "timeout")
	
	for i in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		if i is HBoxContainer:
			i.queue_free()
	
	main.get_node("ShadowPanel").visible = false
	visible = false

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
	var dialog = preload("res://ConfirmationDialog.tscn").instance()
	
	main.add_child(dialog)
	dialog.alert("Are you sure?","A file will be deleted (%s)" %_path)
	var choice = yield(dialog, "chose")
	if choice:
		dir.remove(main.user_dir+"Projects/"+_path)
		_container.queue_free()


func on_Button_download(_container):
	var filename = _container.get_child(0).text
	var file = File.new()
	file.open(main.user_dir+"Projects/"+filename, File.READ)
	var file_data_string = var2str(file.get_var())
	file.close()
	main.get_node("SaveDialog").download_file(filename+"t", file_data_string)

