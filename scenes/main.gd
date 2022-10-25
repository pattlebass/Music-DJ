extends Control

onready var play_button = $HBoxToolBar/Play
onready var export_button = $HBoxToolBar/HBoxContainer/Export
onready var save_button = $HBoxToolBar/HBoxContainer/SaveProject
onready var more_button = $HBoxToolBar/HBoxContainer/More
onready var add_button = $HBoxContainer/ScrollContainer/HBoxContainer/VBoxContainer/AddButton
onready var save_dialog = $SaveDialog
onready var load_dialog = $LoadDialog
onready var sound_dialog = $SoundDialog
onready var progress_dialog = $ProgressDialog
onready var animation = $AnimationPlayer
onready var column_container = $HBoxContainer/ScrollContainer/HBoxContainer
onready var scroll_container = $HBoxContainer/ScrollContainer

# Notes:

# I will refactor most of the code at some point

# * "column" refers to the column node itself, while "column_no" refers
# to the column as a number


func _ready() -> void:
	get_tree().connect("files_dropped", self, "_files_dropped")
	Variables.connect("theme_changed", self, "on_theme_changed")
	Variables.change_theme(Variables.options.theme)
	
	BoomBox.connect("play_ended", self, "_on_play_ended")
	BoomBox.connect("play_started", self, "_on_play_started")
	BoomBox.connect("column_play_started", scroll_container, "ensure_control_visible")
	
	load_dialog.connect("project_selected", self, "load_song")
	
	var more_popup = more_button.get_popup()
	more_popup.connect("id_pressed", self, "more_item_pressed")
	more_popup.connect("about_to_show", self, "more_about_to_show", [more_popup])
	more_popup.script = preload("res://scenes/dialogs/custom_dialog/DialogScript.gd")
	more_popup.main = self
	more_popup.dim = false
	more_popup.rect_pivot_offset.x = more_popup.rect_size.x
	more_popup.pivot_manual = true
	
	randomize()
	
	OS.min_window_size.x = ProjectSettings.get("display/window/size/width") * 0.75
	OS.min_window_size.y = ProjectSettings.get("display/window/size/height") * 0.75
	
	for i in BoomBox.column_index:
		add_column(i)


func on_theme_changed(new_theme) -> void:
	theme = load("res://assets/themes/%s/%s.tres" % [new_theme, new_theme])
	more_button.icon = load("res://assets/themes/%s/more.svg" % new_theme)


func _process(_delta) -> void:
	export_button.disabled = BoomBox.is_playing or BoomBox.used_columns.max() == -1
	play_button.disabled = BoomBox.used_columns.max() == -1
	save_button.disabled = BoomBox.used_columns.max() == -1


func _on_Play_toggled(button_pressed) -> void:
	if button_pressed:
		BoomBox.play_song()
	else:
		BoomBox.stop()


func _on_play_started() -> void:
	play_button.text = "BTN_STOP"
	play_button.set_pressed_no_signal(true)


func _on_play_ended() -> void:
	play_button.text = "BTN_PLAY"
	play_button.set_pressed_no_signal(false)


func on_Tile_pressed(column, _instrument) -> void:
	if BoomBox.is_playing:
		return
	sound_dialog.instrument = _instrument
	sound_dialog.column = column
	sound_dialog.popup_centered(Vector2(500, 550))


func on_Tile_held(_column_no, _instrument, _button) -> void:
	# Needs cleanup
	if BoomBox.is_playing:
		return
	yield(get_tree().create_timer(0.5), "timeout")
	if _button.pressed and _button.text != "":
		# This is so that the button doesn't send the "pressed" signal
		_button.disabled = true
		_button.disabled = false
		
		scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var float_button_scene = preload("res://scenes/FloatButton.tscn")
		var float_button_parent = float_button_scene.instance()
		
		float_button_parent.add_child(_button.duplicate())
		
		var float_button = float_button_parent.get_child(1)
		
		var rect_size = float_button.rect_size
		
		float_button.get_node("Area2D").queue_free()
		float_button.rect_position = -rect_size*1.5/2
		float_button.rect_size = rect_size * 1.5
		float_button.set("custom_colors/font_color", Color.black)
		float_button_parent.instrument = _instrument
		float_button_parent.sample = BoomBox.song[_instrument][_column_no]
		float_button_parent.global_position = get_global_mouse_position()
		add_child(float_button_parent)
		
		Input.vibrate_handheld(70)
		
		yield(float_button_parent, "released")
		
		scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_Export_pressed() -> void:
	save_dialog.type_of_save = "export"
	save_dialog.popup_centered()


func _on_SaveProject_pressed() -> void:
	save_dialog.type_of_save = "project"
	save_dialog.popup_centered()


func _on_OpenProject_pressed() -> void:
	$LoadDialog.popup_centered()


func _on_AddButton_pressed() -> void:
	BoomBox.column_index += 1
	add_column(BoomBox.column_index-1).fade_in()
	yield(get_tree(), "idle_frame")
	scroll_container.ensure_control_visible(add_button)


func add_column(_column_no: int, add_to_song: bool = true) -> Node2D:
	var column = load(Column.scene).instance()
	column_container.add_child(column)
	column_container.move_child(column, column_container.get_child_count()-2)
	column.add(_column_no)
	
	
	# Signals
	for b in 4:
		var button = column.get_node("Button"+str(b+1))
		button.connect("pressed", self, "on_Tile_pressed", [column, b])
		button.connect("button_down", self, "on_Tile_held", [_column_no, b, column.get_node("Button"+str(b+1))])
	column.column_button.connect("pressed", $ColumnDialog, "on_Column_Button_pressed", [_column_no, column])
	
	# Add to song
	if add_to_song:
		BoomBox.add_column()
	
	return column


func remove_column(column_no) -> void:
	BoomBox.remove_column(column_no)
	add_button.call_deferred("grab_focus")


func save_project(file_name: String) -> void:
	file_name = file_name.strip_edges()
	# Project save
	var path = Variables.projects_dir.plus_file("%s.mdj" % file_name)
	var file = File.new()
	var err = file.open(path, File.WRITE)
	file.store_string(to_json(BoomBox.song))
	file.close()
	
	# ProgressDialog
	
	progress_dialog.path = path
	progress_dialog.after_saving = "close"
	progress_dialog.type_of_save = "project"
	progress_dialog.progress_bar.max_value = 0.2
	progress_dialog.popup_centered()
	
	if err:
		progress_dialog.error(err)
	
	Variables.opened_file = file_name


var _recording_cancelled = false

func _on_ProgressDialog_cancelled() -> void:
	_recording_cancelled = true
	BoomBox.stop()

func export_song(file_name: String) -> void:
	_recording_cancelled = false
	file_name = file_name.strip_edges()
	Variables.opened_file = file_name
	
	sound_dialog.audio_player.stop()
	
	# ProgressDialog
	var path = Variables.exports_dir.plus_file(file_name + ".wav")
	
	progress_dialog.path = path
	progress_dialog.after_saving = "stay"
	progress_dialog.type_of_save = "export"
	progress_dialog.progress_bar.max_value = 3*(BoomBox.used_columns.max()+1) + 0.5
	progress_dialog.popup_centered()
	
	# Export
	var effect = AudioServer.get_bus_effect(0, 0)
	effect.set_recording_active(true)
	BoomBox.play_song()
	yield(BoomBox, "play_ended")
	effect.set_recording_active(false)
	
	# Saving
	var recording = effect.get_recording()
	if not recording or _recording_cancelled:
		print("Canceled recording.")
		return
	
	# HACK: Save directly to path when bug is fixed
	# https://github.com/godotengine/godot/issues/63949
	var dir = Directory.new()
	dir.make_dir("user://_temp/")
	var err = recording.save_to_wav("user://_temp/".plus_file(path.get_file()))
	
	if err:
		progress_dialog.error(err)
		print("Recording failed. Code: %s" % err)
	else:
		if OS.get_name() == "Android":
			var download_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS).plus_file("MusicDJ")
			dir.make_dir(download_dir)
			
			print("Android export-----------")
			print(recording.save_to_wav(download_dir.plus_file("Song.wav")))
			print(dir.file_exists(download_dir.plus_file("Song.wav")))
			print(dir.rename(download_dir.plus_file("Song.wav"), path))
			print("Android export end-----------")
			
			if not dir.file_exists(path):
				progress_dialog.error(1234)
				print("Exporting didn't work.")
		else:
			var err2 = dir.rename("user://_temp/".plus_file(path.get_file()), path)
			if err2:
				progress_dialog.error(4321)
				print("Non Android export failed: %s" % err2)
		dir.remove("user://_temp/".plus_file(path.get_file()))


func load_song(path, song = null):
	var dir = Directory.new()
	if song:
		BoomBox.song = song
	else:
		var file = File.new()
		file.open(path, File.READ)
		if path.ends_with(".mdj"):
			var json_result = JSON.parse(file.get_as_text())
			if json_result.error: # DEPRECATED v1.0-stable: Godot dictionary
				BoomBox.song = file.get_var()
			else: # JSON format
				BoomBox.song = json_result.result
			file.close()
		elif path.ends_with(".mdjt"): # DEPRECATED v1.0-stable: mdjt
			BoomBox.song = str2var(file.get_as_text())
			file.close()
			dir.remove(path)
			path.erase(path.length()-1, 1)
			file.open(path, File.WRITE)
			file.store_var(BoomBox.song)
			file.close()
		Variables.opened_file = path.get_file().get_basename()
		
	# Add remaining columns
	var song_column_index = BoomBox.song[0].size()
	
	if BoomBox.column_index < song_column_index:
		for i in song_column_index - BoomBox.column_index:
			add_column(BoomBox.column_index, false)
			BoomBox.column_index += 1
	
	elif BoomBox.column_index > song_column_index:
		for i in BoomBox.column_index - song_column_index:
			column_container.get_child(BoomBox.column_index-1).queue_free()
			BoomBox.column_index -= 1
		
	
	BoomBox.used_columns = [-1]
	
	scroll_container.scroll_horizontal = 0
	play_button.pressed = false
	
	# TODO: Cleanup
	
	for instrument in BoomBox.song.size():
		for column_no in BoomBox.song[instrument].size():
			var column = column_container.get_child(column_no)
			var value = BoomBox.song[instrument][column_no]
			
			if value != 0: # If not empty
				if not BoomBox.used_columns.has(column_no):
					BoomBox.used_columns.append(column_no)
			
			column.set_tile(instrument, value)


func new_song() -> void:
	var empty_song = [[], [], [], []]
	
	for i in 4:
		for j in 15:
			empty_song[i].append(0)
	
	load_song(null, empty_song)
	Variables.opened_file = ""


func _on_Settings_pressed() -> void:
	$SettingsDialog.popup_centered()


func show_shadow() -> void:
	animation.play("dim")


func hide_shadow() -> void:
	animation.play("undim")


func _files_dropped(_files, _screen) -> void:
	var dir = Directory.new()
	
	for i in _files:
		if not (i.ends_with(".mdj") or i.ends_with(".mdjt")):
			continue
		
		var file_name = i.get_file()
		
		if dir.file_exists(Variables.saves_dir.plus_file("Projects/%s" % file_name)):
			var body = tr("DIALOG_CONFIRMATION_BODY_OVERWRITE") % "[color=#4ecca3]%s[/color]" % file_name
			if yield(Variables.confirm_popup("DIALOG_CONFIRMATION_TITLE_OVERWRITE", body), "completed"):
				dir.copy(i, Variables.projects_dir.plus_file("%s" % file_name))
		else:
			dir.copy(i, Variables.projects_dir.plus_file("%s" % file_name))
	$LoadDialog.popup_centered()


func more_item_pressed(id) -> void:
	#await navigator.userAgentData.getHighEntropyValues(["model", "platform", "platformVersion", "uaFullVersion"])
	match id:
		0:
			$SettingsDialog.popup_centered()
		1:
			$TutorialDialog.popup_centered()
		2:
			var link = "https://github.com/pattlebass/Music-DJ/issues/new?labels=bug&template=bug_report.yaml&title=%5BBug%5D%3A+&version={version}&device={device}"
			link = link.format(
				{
					"version": Variables.VERSION.percent_encode(),
					"device": OS.get_model_name().percent_encode() if OS.get_name() == "Android" else ""
				}
			)
			OS.shell_open(link)
		3:
			OS.shell_open("https://github.com/pattlebass/Music-DJ/issues/new?labels=enhancement&template=feature_request.yaml&title=%5BFeature%5D%3A+")
		4:
			$AboutDialog.popup_centered()


func more_about_to_show(popup) -> void:
	if not OS.has_feature("pc"):
		popup.rect_position.y -= more_button.rect_size.y
	# Spacing
	popup.rect_global_position.x = more_button.rect_global_position.x + more_button.rect_size.x - popup.rect_size.x


func _on_LoadDialog_new_project() -> void:
	if yield(
		Variables.confirm_popup(
			"DIALOG_CONFIRMATION_TITLE_NEW_PROJECT", tr("DIALOG_CONFIRMATION_BODY_NEW_PROJECT")
		), "completed"
	):
		new_song()
		load_dialog.hide()
