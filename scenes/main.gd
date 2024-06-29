extends Control

const FLOAT_BUTTON = preload("res://scenes/float_button/float_button.tscn")
const COLUMN = preload("res://scenes/column/column.tscn")

@onready var play_button: Button = %Play
@onready var export_button: Button = %Export
@onready var save_button: Button = %SaveProject
@onready var more_button: CustomMenuButton = %More
@onready var bpm_spinbox: SpinBox = %BPMSpinBox

@onready var add_button: Button = %AddButton
@onready var column_container: HBoxContainer = %ColumnContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer

@onready var save_dialog: FilenameDialog = $SaveDialog
@onready var load_dialog: LoadDialog = $LoadDialog
@onready var sound_dialog: SoundDialog = $SoundDialog
@onready var progress_dialog: ProgressDialog = $ProgressDialog
@onready var column_dialog: ColumnDialog = $ColumnDialog
@onready var settings_dialog: CustomDialog = $SettingsDialog
@onready var about_dialog: AboutDialog = $AboutDialog
@onready var tutorial_dialog: TutorialDialog = $TutorialDialog

@onready var bg_panel: Panel = $BgPanel
@onready var dim_overlay: Panel = $DimOverlay

var columns: Array[Column] = []

# Notes:
# "column" refers to the column node itself, while "column_no" refers
# to the column as a number


func _ready() -> void:
	# Signals *******************************************
	get_window().files_dropped.connect(_on_files_dropped)
	Utils.theme_changed.connect(_on_theme_changed)
	Utils.exclusive_popup_visible.connect(show_shadow)
	Utils.exclusive_popup_hidden.connect(hide_shadow)
	
	BoomBox.play_ended.connect(_on_play_ended)
	BoomBox.play_started.connect(_on_play_started)
	BoomBox.column_play_started.connect(scroll_container.ensure_control_visible)
	BoomBox.song_changed.connect(_on_song_changed)
	
	load_dialog.project_selected.connect(load_song_path)
	more_button.get_popup().item_pressed.connect(_on_more_item_pressed)
	# Signals end ***************************************
	
	Utils.change_theme(Options.theme)
	
	get_window().min_size.x = ProjectSettings.get("display/window/size/viewport_width") * 0.75
	get_window().min_size.y = ProjectSettings.get("display/window/size/viewport_height") * 0.75
	
	new_song()
	
	if OS.get_name() == "Web":
		var project := get_project_from_query()
		if project != null:
			load_song(project)


func _on_theme_changed(new_theme: String) -> void:
	theme = load("res://assets/themes/%s/%s.tres" % [new_theme, new_theme])


func _on_play_toggled(button_pressed: bool) -> void:
	if button_pressed:
		BoomBox.play_song()
	else:
		BoomBox.stop()


func _on_play_started() -> void:
	play_button.text = "BTN_STOP"
	play_button.set_pressed_no_signal(true)
	
	export_button.disabled = true
	bpm_spinbox.editable = false


func _on_play_ended() -> void:
	play_button.text = "BTN_PLAY"
	play_button.set_pressed_no_signal(false)
	
	export_button.disabled = BoomBox.song.get_trimmed_length() == 0
	bpm_spinbox.editable = true


func _on_song_changed() -> void:
	var trimmed_len := BoomBox.song.get_trimmed_length()
	play_button.disabled = trimmed_len == 0
	save_button.disabled = trimmed_len == 0
	export_button.disabled = trimmed_len == 0 and !BoomBox.is_playing 


func _on_tile_pressed(column: Column, instrument: int) -> void:
	if BoomBox.is_playing:
		return
	sound_dialog.instrument = instrument
	sound_dialog.column = column
	sound_dialog.popup_centered()


func _on_tile_held(_column_no, _instrument, _button) -> void:
	# Needs cleanup
	if BoomBox.is_playing:
		return
	await get_tree().create_timer(0.5).timeout
	if _button.pressed and _button.text != "":
		# This is so that the button doesn't send the "pressed" signal
		_button.disabled = true
		_button.disabled = false
		
		scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var float_button_parent: FloatButton = FLOAT_BUTTON.instantiate()
		
		float_button_parent.add_child(_button.duplicate())
		
		var float_button = float_button_parent.get_child(1)
		
		var size = float_button.size
		
		float_button.get_node("Area2D").queue_free()
		float_button.position = -size*1.5/2
		float_button.size = size * 1.5
		float_button.set("theme_override_colors/font_color", Color.BLACK)
		float_button_parent.instrument = _instrument
		float_button_parent.sample = BoomBox.song.data[_instrument][_column_no]
		float_button_parent.global_position = get_global_mouse_position()
		add_child(float_button_parent)
		
		Input.vibrate_handheld(70)
		
		await float_button_parent.released
		
		scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_export_pressed() -> void:
	save_dialog.title = "DIALOG_SAVE_TITLE_EXPORT"
	save_dialog.name_picked.connect(export_song, CONNECT_ONE_SHOT)
	save_dialog.popup_centered()


func _on_save_project_pressed() -> void:
	save_dialog.title = "DIALOG_SAVE_TITLE_PROJECT"
	save_dialog.name_picked.connect(save_project, CONNECT_ONE_SHOT)
	save_dialog.popup_centered()


func _on_open_project_pressed() -> void:
	load_dialog.popup_centered()


func _on_add_button_pressed() -> void:
	BoomBox.song.add_column()
	add_column(BoomBox.song.get_length() - 1).fade_in()
	# HACK
	await get_tree().process_frame
	await get_tree().process_frame
	scroll_container.ensure_control_visible(add_button)


func _on_bpm_spin_box_value_changed(value: int) -> void:
	BoomBox.song.bpm = value
	BoomBox.update_pitch()


func add_column(column_no: int) -> Column:
	var column: Column = COLUMN.instantiate()
	column_container.add_child(column)
	column_container.move_child(column, column_container.get_child_count() - 2)
	column.add(column_no)
	
	# Signals
	for i in 4:
		var button: Button = column.tiles[i]
		button.pressed.connect(_on_tile_pressed.bind(column, i))
		button.button_down.connect(_on_tile_held.bind(column_no, i, button))
	column.column_button.pressed.connect(column_dialog._on_column_button_pressed.bind(column))
	column.removed.connect(remove_column.bind(column_no))
	
	columns.insert(column_no, column)
	
	return column


func remove_column(column_no: int) -> void:
	columns.remove_at(column_no)
	BoomBox.song.remove_column(column_no)


func get_project_from_query() -> Song:
	var project_string = JavaScriptBridge.eval(\
		"""
		(function getParams() {
			const urlString = (window.location != window.parent.location)
						? document.referrer
						: document.location.href;
			const url = new URL(urlString);
			const song = url.searchParams.get("song");
			
			url.search = "";
			history.replaceState(null, "", url.toString())
			
			return song;
		}())
		"""
	)
	if project_string:
		var parser := JSON.new()
		var err := parser.parse(project_string)
		if err:
			Utils.toast("Error parsing project from URL (code: %s)" % err)
		else:
			var song := Song.new().from(parser.data)
			return song
	return null


func save_project(file_name: String) -> void:
	file_name = file_name.strip_edges()
	
	var path := Variables.projects_dir.path_join("%s.mdj" % file_name)
	
	# ProgressDialog
	progress_dialog.popup_centered()
	progress_dialog.body_text = ""
	progress_dialog.body_text_completed = "DIALOG_PROGRESS_AFTER_PROJECT"
	progress_dialog.open_button.pressed.connect(
		OS.shell_open.bind(ProjectSettings.globalize_path(Variables.saves_dir)),
		CONNECT_ONE_SHOT
	)
	progress_dialog.download_button.pressed.connect(
		Utils.download_file.bind(path, path.get_file()),
		CONNECT_ONE_SHOT
	)
	progress_dialog.share_button.pressed.connect(
		Utils.share_file.bind(path, "", "", "", "audio/wav"),
		CONNECT_ONE_SHOT
	)
	
	var tween := create_tween()
	tween.tween_property(progress_dialog, ^"progress", 1, 0.2)
	tween.tween_callback(progress_dialog.hide)
	
	var err := BoomBox.song.save(path)
	
	if err:
		progress_dialog.error(err)
	
	Variables.opened_file = file_name


# TODO: Remember web exports 
func export_song(file_name: String) -> void:
	file_name = file_name.strip_edges()
	
	var path := Variables.exports_dir.path_join(file_name + ".wav")
	
	# ProgressDialog
	if OS.get_name() == "Web":
		progress_dialog.body_text = "DIALOG_PROGRESS_KEEP_FOCUSED"
	else:
		progress_dialog.body_text_completed = tr("DIALOG_PROGRESS_AFTER_EXPORT") % ProjectSettings.globalize_path(path)
	progress_dialog.popup_centered()
	
	progress_dialog.open_button.pressed.connect(
		OS.shell_open.bind(ProjectSettings.globalize_path(Variables.saves_dir)),
		CONNECT_ONE_SHOT
	)
	progress_dialog.download_button.pressed.connect(
		Utils.download_file.bind(path, path.get_file()),
		CONNECT_ONE_SHOT
	)
	progress_dialog.share_button.pressed.connect(
		Utils.share_file.bind(path, "", "", "", "audio/wav"),
		CONNECT_ONE_SHOT
	)


func load_song(song: Song) -> void:
	BoomBox.song = song
	
	for i in range(columns.size() - 1, -1, -1):
		var column: Column = columns[i]
		if column.column_no >= BoomBox.song.get_length():
			column.queue_free()
			columns.remove_at(i)
	
	for column in columns:
		column.clear()
	
	for instrument in BoomBox.song.data.size():
		for column_no in BoomBox.song.data[instrument].size():
			if column_no >= columns.size():
				add_column(column_no)
			
			var column := columns[column_no]
			var sample: int = BoomBox.song.data[instrument][column_no]
			
			column.set_tile(instrument, sample)
	
	bpm_spinbox.value = BoomBox.song.bpm
	scroll_container.scroll_horizontal = 0
	_on_song_changed()


func load_song_path(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var parser := JSON.new()
	
	var err := parser.parse(file.get_as_text())
	file.close()
	
	if err:
		var msg := "Error opening project (code: %s)" % err
		Utils.toast(msg)
		printerr(msg)
		return
	
	load_song(Song.new().from(parser.data))
	Variables.opened_file = path.get_file().get_basename()


func new_song() -> void:
	load_song(Song.new())
	Variables.opened_file = ""


func show_shadow() -> void:
	var tween := create_tween()
	tween.tween_property(dim_overlay, ^"modulate:a", 1.0, 0.1)


func hide_shadow() -> void:
	var tween := create_tween()
	tween.tween_property(dim_overlay, ^"modulate:a", 0, 0.1)


func _on_files_dropped(files: PackedStringArray) -> void:
	for i in files:
		if not i.get_extension() in ["mdj", "mdjt", "mid"]:
			continue
		
		var file_name := i.get_file()
		
		if file_name.get_extension() == "mid":
			file_name += ".mdj"
		
		var can_overwrite := true
		if FileAccess.file_exists(Variables.saves_dir.path_join("Projects/%s" % file_name)):
			var body := tr("DIALOG_CONFIRMATION_BODY_OVERWRITE") % "[color=#4ecca3]%s[/color]" % file_name
			can_overwrite = await Utils.confirm_popup("DIALOG_CONFIRMATION_TITLE_OVERWRITE", body)
		
		if can_overwrite:
			if i.get_extension() == "mid":
				var file := FileAccess.open(Variables.projects_dir.path_join(file_name), FileAccess.WRITE)
				file.store_string(JSON.stringify(MidiFile.to_mdj(i)))
				file.close()
			else:
				DirAccess.copy_absolute(i, Variables.projects_dir.path_join(file_name))
	
	load_dialog.popup_centered()


func _on_more_item_pressed(id: int) -> void:
	match id:
		0:
			settings_dialog.popup_centered()
		1:
			tutorial_dialog.popup_centered()
		2:
			var link := "https://github.com/pattlebass/Music-DJ/issues/new?labels=bug&template=bug_report.yaml&title=%5BBug%5D%3A+&version={version}&device={device}"
			link = link.format(
				{
					"version": ProjectSettings.get_setting("application/config/version"),
					"device": OS.get_model_name().uri_encode() if OS.get_name() == "Android" else ""
				}
			)
			OS.shell_open(link)
		3:
			OS.shell_open("https://github.com/pattlebass/Music-DJ/issues/new?labels=enhancement&template=feature_request.yaml&title=%5BFeature%5D%3A+")
		4:
			about_dialog.popup_centered()


func _on_load_dialog_new_project() -> void:
	var confirmed: bool = (await Utils.confirm_popup("DIALOG_CONFIRMATION_TITLE_NEW_PROJECT",
			"DIALOG_CONFIRMATION_BODY_NEW_PROJECT"))
	if confirmed:
		new_song()
		load_dialog.hide()


func _on_column_dialog_removed_column() -> void:
	add_button.grab_focus.call_deferred()
