extends CustomDialog

var selected_file = ""

onready var project_container: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
onready var open_folder: Button = $VBoxContainer/TitleHBox/OpenFolderButton
onready var ok_button: Button = $VBoxContainer/HBoxContainer/OkButton


func _ready() -> void:
	Variables.connect("theme_changed", self, "on_theme_changed")
	if !OS.is_ok_left_and_cancel_right():
		$VBoxContainer/HBoxContainer.move_child(
			$VBoxContainer/HBoxContainer/CancelButton,
			0
		)


func _on_OkButton_pressed():
	load_song(Variables.user_dir.plus_file("Projects/%s" % selected_file))
	

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
		main.get_node("SaveDialog").last_name = _path.get_file().get_basename()
		
	# Add remaining columns
	var song_column_index = main.song[0].size()
	
	if main.column_index < song_column_index:
		for i in song_column_index - main.column_index:
			main.add_column(main.column_index, false)
			main.column_index += 1
	
	elif main.column_index > song_column_index:
		for i in main.column_index - song_column_index:
			main.column_container.get_child(main.column_index-1).queue_free()
			main.column_index -= 1
		
	
	# Clear used_columns
	main.used_columns.clear()
	main.used_columns.append(-1)
	
	main.scroll_container.scroll_horizontal = 0
	
	# TODO: Cleanup
	
	for instrument in main.song.size():
		for column_no in main.song[instrument].size():
			var column = main.column_container.get_child(column_no)
			var value = main.song[instrument][column_no]
			
			if value != 0: # If not empty
				if not main.used_columns.has(column_no):
					main.used_columns.append(column_no)
			
			column.set_tile(instrument, value)
			
	hide()


func on_theme_changed(new_theme):
	open_folder.icon = load("res://assets/themes/%s/open_folder.svg" % new_theme)


func about_to_show():
	if !Variables.has_storage_perms():
		hide()
	
	if OS.get_name() == "HTML5":
		open_folder.hide()
	ok_button.disabled = true
	
	selected_file = ""
	
	var projects = list_files_in_directory(
		Variables.user_dir.plus_file("Projects/"),
		["mdj", "mdjt"]
	)
	
	var theme_path = "res://assets/themes/%s/" % Variables.options.theme
	
	if projects.empty():
		$"%NoProjectsLabel".show()
	else:
		$"%NoProjectsLabel".hide()
	
	var btn_group = ButtonGroup.new()
	
	for i in projects.size():
		var project_path = projects[i]
		var button_container = HBoxContainer.new()
		
		project_container.add_child(button_container)
		
		var load_button = Button.new()
		load_button.name = "LoadButton"
		load_button.text = project_path
		load_button.align = Button.ALIGN_LEFT
		load_button.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		load_button.theme_type_variation = "ListItem"
		load_button.toggle_mode = true
		load_button.group = btn_group
		button_container.add_child(load_button)
		if i == 0:
			open_folder.focus_neighbour_bottom = load_button.get_path()
			load_button.call_deferred("grab_focus")
		
		var download_button = Button.new()
		download_button.name = "DownloadButton"
		download_button.icon = load(theme_path+"download.svg")
		download_button.theme_type_variation = "ListItem"
		download_button.hide()
		button_container.add_child(download_button)
		
		var delete_button = Button.new()
		delete_button.name = "DeleteButton"
		delete_button.icon = load(theme_path+"delete.svg")
		delete_button.theme_type_variation = "ListItem"
		delete_button.hide()
		button_container.add_child(delete_button)
		
		load_button.connect("toggled", self, "on_Button_toggled", [button_container, project_path])
		
		delete_button.connect("pressed", self, "on_Delete_pressed", [button_container, project_path])
		
		connect("popup_hide", button_container, "queue_free")
		
		if OS.get_name() == "HTML5":
			download_button.connect("pressed", self, "on_Button_download", [button_container])
	
	$VBoxContainer.rect_size = rect_size
	
	.about_to_show()


func list_files_in_directory(path: String, extensions := []) -> Array:
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file: String = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.get_extension() in extensions:
				files.append(file)

	dir.list_dir_end()
	
	return files


func on_Button_toggled(button_pressed, button_container, _path):
	button_container.get_node("DeleteButton").visible = button_pressed
	button_container.get_node("DownloadButton").visible = button_pressed && OS.get_name() == "HTML5"
	
	if not button_pressed:
		return
	
	if _path == selected_file:
		button_container.get_node("LoadButton").set_pressed_no_signal(true)
	else:
		selected_file = _path
		ok_button.disabled = false


func _on_CancelButton_pressed():
	hide()


func _on_OpenButton_pressed():
	if OS.get_name() == "Android":
		OS.alert(ProjectSettings.globalize_path(Variables.user_dir), "Folder location")
	else:
		OS.shell_open(ProjectSettings.globalize_path(Variables.user_dir))


func on_Delete_pressed(_container, file_name):
	modulate = Color.transparent
	
	var body = tr("DIALOG_CONFIRMATION_BODY_DELETE") % "[color=#4ecca3]%s[/color]" % file_name
	if yield(Variables.confirm_popup("DIALOG_CONFIRMATION_TITLE_DELETE", body), "completed"):
		var path := Variables.user_dir.plus_file("Projects/%s" % file_name)
		if OS.move_to_trash(ProjectSettings.globalize_path(path)) != OK:
			var dir =  Directory.new()
			dir.remove(ProjectSettings.globalize_path(path))
		
		ok_button.disabled = _container.get_node("LoadButton").text == selected_file
		_container.queue_free()
	
	modulate = Color.white


func on_Button_download(_container):
	var file_name = _container.get_child(0).text
	Variables.download_file(
		Variables.user_dir.plus_file("Projects/%s" % file_name),
		file_name
	)
