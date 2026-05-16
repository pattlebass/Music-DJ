extends Control

const PROGRESS_DIALOG = preload("res://scenes/dialogs/progress_dialog/progress_dialog.tscn")

@onready var play_button: Button = %Play
@onready var export_button: Button = %Export
@onready var save_button: Button = %SaveProject
@onready var more_button: CustomMenuButton = %More

@onready var add_button: Button = %AddButton
@onready var column_container: ColumnContainer = %ColumnContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer

@onready var save_dialog: FilenameDialog = $SaveDialog
@onready var load_dialog: LoadDialog = $LoadDialog
@onready var sound_dialog: SoundDialog = $SoundDialog
@onready var column_dialog: ColumnDialog = $ColumnDialog
@onready var settings_dialog: CustomDialog = $SettingsDialog
@onready var about_dialog: AboutDialog = $AboutDialog
@onready var tutorial_dialog: TutorialDialog = $TutorialDialog

@onready var bg_panel: Panel = $BgPanel
@onready var dim_overlay: Panel = $DimOverlay


# Notes:
# "column" refers to the column node itself, while "column_no" refers
# to the column as a number


func _ready() -> void:
	#region Signals
	get_window().files_dropped.connect(_on_files_dropped)
	Utils.theme_changed.connect(_on_theme_changed)
	Utils.exclusive_popup_visible.connect(show_shadow)
	Utils.exclusive_popup_hidden.connect(hide_shadow)
	
	BoomBox.play_ended.connect(_on_play_ended)
	BoomBox.play_started.connect(_on_play_started)
	BoomBox.column_play_started.connect(_on_column_play_started)
	BoomBox.song_loaded.connect(_on_song_loaded)
	
	column_container.column_added.connect(_on_column_added_node)
	
	load_dialog.project_selected.connect(load_song_path)
	more_button.get_popup().item_pressed.connect(_on_more_item_pressed)
	#endregion
	
	Utils.change_theme(Options.theme)
	
	get_window().min_size.x = ProjectSettings.get("display/window/size/viewport_width") * 0.75
	get_window().min_size.y = ProjectSettings.get("display/window/size/viewport_height") * 0.75
	
	new_song()
	
	if OS.get_name() == "Web":
		var project := get_project_from_query()
		if project != null:
			BoomBox.song = project


func _on_theme_changed(new_theme: String) -> void:
	theme = load("res://assets/themes/%s/%s.tres" % [new_theme, new_theme])


func _on_song_loaded() -> void:
	BoomBox.song.removed_column.connect(_on_removed_column)
	BoomBox.song.trimmed_length_changed.connect(_on_song_trimmed_length_changed)
	
	scroll_container.scroll_horizontal = 0
	_on_song_trimmed_length_changed()


func _on_column_added_node(column: Column) -> void:
	column.tile_pressed.connect(_on_tile_pressed.bind(column))
	column.column_button_pressed.connect(column_dialog.popup_on_column.bind(column))
	column.drag_started.connect(
		func(): scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
	column.drag_ended.connect(
		func(): scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	)
	column.tile_drag_started.connect(
		func():
			scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
	column.tile_drag_ended.connect(
		func():
			scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	)
	column.tile_swipe_started.connect(
		func():
			scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
	column.tile_swipe_ended.connect(
		func():
			scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	)


func _on_removed_column(column_no: int) -> void:
	# Decide focus
	var columns := column_container.columns
	var next_focus: Control = add_button
	if column_no < columns.size():
		next_focus = columns[column_no].column_button
	elif column_no - 1 > 0 and column_no - 1 < columns.size():
		next_focus = columns[column_no - 1].column_button
	next_focus.grab_focus.call_deferred()


func _on_song_trimmed_length_changed() -> void:
	var trimmed_len := BoomBox.song.get_trimmed_length()
	play_button.disabled = trimmed_len == 0
	save_button.disabled = trimmed_len == 0
	export_button.disabled = trimmed_len == 0 and !BoomBox.is_playing 


func _on_tile_pressed(instrument: int, column: Column) -> void:
	if BoomBox.is_playing:
		return
	sound_dialog.instrument = instrument
	sound_dialog.column = column
	sound_dialog.popup2()


func _on_play_toggled(button_pressed: bool) -> void:
	if button_pressed:
		BoomBox.play()
	else:
		BoomBox.stop()


func _on_play_started() -> void:
	play_button.text = "BTN_STOP"
	play_button.set_pressed_no_signal(true)
	
	export_button.disabled = true


func _on_play_ended() -> void:
	play_button.text = "BTN_PLAY"
	play_button.set_pressed_no_signal(false)
	
	export_button.disabled = BoomBox.song.get_trimmed_length() == 0


func _on_column_play_started(column_no: int) -> void:
	scroll_container.ensure_control_visible(column_container.columns[column_no])


func _on_export_pressed() -> void:
	save_dialog.title2 = "DIALOG_SAVE_TITLE_EXPORT"
	save_dialog.popup2()
	save_dialog.name_picked.connect(export_song, CONNECT_ONE_SHOT)


func _on_save_project_pressed() -> void:
	save_dialog.title2 = "DIALOG_SAVE_TITLE_PROJECT"
	save_dialog.popup2()
	save_dialog.name_picked.connect(save_project, CONNECT_ONE_SHOT)


func _on_open_project_pressed() -> void:
	load_dialog.popup2()


func _on_add_button_pressed() -> void:
	BoomBox.song.add_column(BoomBox.song.get_length())
	# HACK
	await column_container.resized
	await get_tree().process_frame
	scroll_container.ensure_control_visible(add_button)


func _on_bpm_spin_box_value_changed(value: int) -> void:
	BoomBox.song.bpm = value


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
	var path := Variables.projects_dir.path_join("%s.mdj" % file_name)
	# ProgressDialog
	var progress_dialog: ProgressDialog = PROGRESS_DIALOG.instantiate()
	add_child(progress_dialog)
	progress_dialog.popup2()
	progress_dialog.body_text = ""
	progress_dialog.body_text_completed = ""
	progress_dialog.popup_hidden.connect(progress_dialog.queue_free)
	
	progress_dialog.open_button.hide()
	progress_dialog.share_button.hide()
	progress_dialog.download_button.hide()
	
	progress_dialog.open_button.pressed.connect(
		OS.shell_open.bind(ProjectSettings.globalize_path(Variables.saves_dir))
	)
	
	var tween := create_tween()
	tween.tween_property(progress_dialog, ^"progress", 1, 0.2)
	tween.tween_callback(progress_dialog.popup_hide2)
	
	var err := BoomBox.song.save(path)
	
	if err:
		progress_dialog.error(err)
	
	Variables.opened_file = file_name


# TODO: Remember web exports 
func export_song(file_name: String) -> void:
	var path := Variables.exports_dir.path_join(file_name + ".wav")
	
	# ProgressDialog
	var progress_dialog: ProgressDialog = PROGRESS_DIALOG.instantiate()
	add_child(progress_dialog)
	if OS.get_name() == "Web":
		progress_dialog.body_text = "DIALOG_PROGRESS_KEEP_FOCUSED"
	else:
		progress_dialog.body_text_completed = tr("DIALOG_PROGRESS_AFTER_EXPORT") % ProjectSettings.globalize_path(path)
	
	progress_dialog.popup_hidden.connect(progress_dialog.queue_free)
	progress_dialog.popup2()
	
	progress_dialog.open_button.pressed.connect(
		OS.shell_open.bind(ProjectSettings.globalize_path(Variables.saves_dir))
	)
	progress_dialog.download_button.pressed.connect(
		Utils.download_file.bind(path, path.get_file())
	)
	progress_dialog.share_button.pressed.connect(
		Utils.share_file.bind(path, "", "", "", "audio/wav")
	)
	
	# Animate progress bar
	var tween := create_tween()
	tween.tween_property(progress_dialog, ^"progress", 1, BoomBox.song.get_duration() + 0.5)
	
	# Recording
	var bus_idx := AudioServer.get_bus_index(&"Master")
	var effect: AudioEffectRecord = AudioServer.get_bus_effect(bus_idx, 0)
	
	effect.set_recording_active(true)
	BoomBox.play()
	await BoomBox.play_ended
	effect.set_recording_active(false)
	
	# Saving
	var recording := effect.get_recording()
	if recording == null:
		print("Export cancelled.")
	var err := recording.save_to_wav(path)
	if err:
		progress_dialog.error(err)


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
	
	BoomBox.song = Song.new().from(parser.data)
	Variables.opened_file = path.get_file().get_basename()


func new_song() -> void:
	BoomBox.song = Song.new()
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
	
	load_dialog.popup2()


func _on_more_item_pressed(id: int) -> void:
	match id:
		0:
			settings_dialog.popup2()
		1:
			tutorial_dialog.popup2()
		2:
			var link := "https://github.com/pattlebass/Music-DJ/issues/new?labels=bug&template=bug_report.yaml&version={version}&device={device}"
			link = link.format(
				{
					"version": ProjectSettings.get_setting("application/config/version"),
					"device": OS.get_model_name().uri_encode() if OS.get_name() == "Android" else ""
				}
			)
			OS.shell_open(link)
		3:
			OS.shell_open("https://github.com/pattlebass/Music-DJ/issues/new?labels=enhancement&template=feature_request.yaml")
		4:
			OS.shell_open("https://ko-fi.com/fabians")
		5:
			about_dialog.popup2()


func _on_load_dialog_new_project() -> void:
	var confirmed: bool = (await Utils.confirm_popup("DIALOG_CONFIRMATION_TITLE_NEW_PROJECT",
			"DIALOG_CONFIRMATION_BODY_NEW_PROJECT"))
	if confirmed:
		new_song()
		load_dialog.hide()
