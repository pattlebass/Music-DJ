extends Control

var song := [[], [], [], []]
var used_columns := [-1]
var column_index := 15
var is_playing := false

var column_scene = preload("res://scenes/Column.tscn")

onready var play_button = $HBoxToolBar/Play
onready var export_button = $HBoxToolBar/HBoxContainer/Export
onready var save_button = $HBoxToolBar/HBoxContainer/SaveProject
onready var save_dialog = $SaveDialog
onready var audio_players = $AudioPlayers
onready var animation = $AnimationPlayer
onready var column_container = $HBoxContainer/ScrollContainer/HBoxContainer
onready var scroll_container = $HBoxContainer/ScrollContainer

# Notes:

# I will refactor most of the code at some point

# * "column" refers to the column node itself, while "column_no" refers
# to the column as a number
# * Some signals are a bit messy


func _ready():
	get_tree().connect("files_dropped", self, "_files_dropped")
	Variables.connect("theme_changed", self, "on_theme_changed")
	Variables.change_theme(Variables.options.theme)
	
	randomize()
	
	OS.min_window_size.x = ProjectSettings.get("display/window/size/width") * 0.75
	OS.min_window_size.y = ProjectSettings.get("display/window/size/height") * 0.75
	
	for i in column_index:
		add_column(i)
	
	if OS.get_name() == "Android":
		yield(get_tree(), "idle_frame")
		Variables.has_storage_perms()
		
		Variables.user_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).plus_file("MusicDJ")
		var dir = Directory.new()
		dir.open(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS))
		dir.make_dir("MusicDJ")
		dir.open(Variables.user_dir)
		dir.make_dir("Projects")
		dir.make_dir("Exports")
		
		if Engine.has_singleton("GodotOpenWith"):
			var open_file = Engine.get_singleton("GodotOpenWith").getOpenFile()
			if open_file:
				$LoadDialog.load_song(null, parse_json(open_file))
	else:
		var dir = Directory.new()
		dir.open("user://")
		dir.make_dir("saves")
		dir.open("user://saves")
		dir.make_dir("Exports")
		dir.make_dir("Projects")
		Variables.user_dir = "user://saves/"


func on_theme_changed(new_theme):
	theme = load("res://assets/themes/%s/%s.tres" % [new_theme, new_theme])


func play_song():
	is_playing = true
	yield(get_tree(), "idle_frame")
	$SoundDialog.audio_player.stop()
	for i in column_index:
		if not is_playing:
			return
		play_column(i, false)
		yield(get_tree().create_timer(3), "timeout")
	
		if i >= used_columns.max():
			play_button.pressed = false
			is_playing = false
			return


func play_column(_column_no, _single):
	is_playing = true
	
	if _column_no > used_columns.max():
		play_button.pressed = false
		return
	
	# Visuals
	var column = column_container.get_child(_column_no)
	column.on_play_started()
	scroll_container.ensure_control_visible(column)
	
	# Play sounds
	for a in 4:
		if song[a][_column_no] == 0:
			continue
	
		var audio_player = audio_players.get_child(a)
		var sound = song[a][_column_no]
		audio_player.stream = load("res://sounds/"+str(a)+"/"+str(sound)+".ogg")
		audio_player.play()
	# Needs cleanup
	yield(get_tree().create_timer(3), "timeout")
	column.on_play_ended()
		
	if _single:
		is_playing = false
	
	if not is_playing:
		return


func on_Tile_pressed(_column_no, _instrument):
	if is_playing:
		return
	var sound_dialog = $SoundDialog
	sound_dialog.instrument_index = _instrument
	sound_dialog.column_no = _column_no
	sound_dialog.popup_centered(Vector2(500, 550))


func on_Tile_held(_column_no, _instrument, _button):
	# Needs cleanup
	if is_playing:
		return
	yield(get_tree().create_timer(0.5), "timeout")
	if _button.pressed and _button.text != "":
		# This is so that the button doesn't send the "pressed"
		_button.disabled = true
		_button.disabled = false
		
		$HBoxContainer/ScrollContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
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
		float_button_parent.column_no = _column_no
		float_button_parent.global_position = get_global_mouse_position()
		add_child(float_button_parent)
		var rect_global_pos = _button.rect_global_position
		float_button_parent.pos_y = rect_global_pos.y
		
		Input.vibrate_handheld(70)


func _on_Play_toggled(button_pressed):
	if button_pressed:
		play_song()
		play_button.text = "BTN_STOP"
	else:
		is_playing = false
		play_button.text = "BTN_PLAY"
		
		yield(get_tree(), "idle_frame")
		for i in audio_players.get_children():
			i.stop()


func _on_Export_pressed():
	if  used_columns.max() != -1:
		save_dialog.title = "DIALOG_SAVE_TITLE_EXPORT"
		save_dialog.type_of_save = "export"
		save_dialog.popup_centered()


func _on_SaveProject_pressed():
	save_dialog.title = "DIALOG_SAVE_TITLE_PROJECT"
	save_dialog.type_of_save = "project"
	save_dialog.popup_centered()


func _on_OpenProject_pressed():
	$LoadDialog.popup_centered()


func _on_AddButton_pressed():
	column_index += 1
	add_column(column_index-1).fade_in()


func add_column(_column_no:int, add_to_song:bool = true):
	var column = column_scene.instance()
	column_container.add_child(column)
	column_container.move_child(column, column_container.get_child_count()-2)
	column.add(_column_no)
	
	
	# Signals
	for b in 4:
		var button = column.get_node("Button"+str(b+1))
		button.connect("pressed", self, "on_Tile_pressed", [_column_no, b])
		button.connect("button_down", self, "on_Tile_held", [_column_no, b, column.get_node("Button"+str(b+1))])
	column.column_button.connect("pressed", $ColumnDialog, "on_Column_Button_pressed", [_column_no, column])
	
	# Add to song
	if add_to_song:
		for g in song:
			g.append(0)
	
	return column


func remove_column(_column_no) -> void:
	for i in 4:
		song[i].pop_back()
	used_columns.erase(_column_no)
	column_index -= 1


func _process(_delta):
	export_button.disabled = is_playing or used_columns.max() == -1
	play_button.disabled = used_columns.max() == -1
	save_button.disabled = used_columns.max() == -1


func _on_Settings_pressed():
	$SettingsDialog.popup_centered()


func on_popup_show():
	animation.play("dim")


func on_popup_hide():
	animation.play("undim")


func _files_dropped(_files, _screen):
	var dir = Directory.new()
	var dialog_scene = preload("res://scenes/ConfirmationDialog.tscn")
	
	for i in _files:
		if not (i.ends_with(".mdj") or i.ends_with(".mdjt")):
			continue
		
		var file_name = i.get_file()
		
		if dir.file_exists(Variables.user_dir.plus_file("Projects/%s" % file_name)):
			var dialog = dialog_scene.instance()
			add_child(dialog)
			dialog.alert(
				"DIALOG_CONFIRMATION_TITLE_OVERWRITE",
				# TODO: Cleanup
				tr("DIALOG_CONFIRMATION_BODY_OVERWRITE") % "[color=#4ecca3]%s[/color]" % file_name
			)
			var choice = yield(dialog, "chose")
			if choice == true:
				dir.copy(i, Variables.user_dir.plus_file("Projects/%s" % file_name))
		else:
			dir.copy(i, Variables.user_dir.plus_file("Projects/%s" % file_name))
	$LoadDialog.popup_centered()
