extends Node

const FILE_PATH = "user://options.cfg"
const SOUNDFONT_DIR = "user://soundfonts/"

# Keys
var last_seen_tutorial := -1 # Hasn't seen the tutorial
var theme := "dark":
	set(val):
		if val == theme:
			return
		theme = val
		Utils.change_theme(theme)

var language := "": # Auto
	set(val):
		if val == language:
			return
		language = val
		if language:
			TranslationServer.set_locale(language)
		else:
			TranslationServer.set_locale(OS.get_locale_language())

var check_updates := false
var check_updates_answered := false
var last_update_check := 0
var custom_soundfont_path := "":
	set(val):
		if custom_soundfont_path == val:
			return
		custom_soundfont_path = val
		save()

const _KEYS = [&"last_seen_tutorial", &"theme", &"language", &"check_updates",
				&"check_updates_answered", &"last_update_check", &"custom_soundfont_path"]

var _config_file := ConfigFile.new()
var _timer: Timer


func _ready() -> void:
	# Options
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_save)
	add_child(_timer)
	
	init_options()
	
	# Dirs
	DirAccess.make_dir_absolute("user://soundfonts/")


func init_options() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		print("Created options.cfg")
		save(0)
		return
	
	var err := _config_file.load(FILE_PATH)
	if err:
		printerr("Error opening options.cfg: %s" % err)
		print("Created options.cfg")
		save(0)
		return
	
	# Read options.cfg
	for key in _KEYS:
		set(key, _config_file.get_value("options", key, get(key)))
	
	print("Loaded options.cfg")
	
	save(0)


func save(delay := 0.5) -> void:
	_timer.start(delay)


func _save() -> void:
	for key in _KEYS:
		_config_file.set_value("options", key, get(key))
	var err := _config_file.save(FILE_PATH)
	if err:
		printerr("Error while saving options.cfg: %s" % err)
	else:
		print("Written to options.cfg")


func get_soundfont_path() -> String:
	if custom_soundfont_path.is_empty():
		return "res://playback/soundfonts/A100 DB2020 Synth 1.0.5.sf2"
	else:
		return custom_soundfont_path


func import_soundfont(file: String) -> Error:
	var new_filename := SOUNDFONT_DIR.path_join(file.get_file())
	if FileAccess.file_exists(new_filename):
		return Error.ERR_ALREADY_EXISTS
	return DirAccess.copy_absolute(file, new_filename)


func get_custom_soundfont_list() -> PackedStringArray:
	var files := DirAccess.get_files_at(SOUNDFONT_DIR)
	
	for i in files.size():
		files[i] = SOUNDFONT_DIR + files[i]
	
	return files
