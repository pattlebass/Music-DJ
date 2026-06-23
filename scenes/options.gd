extends Node

const FILE_PATH = "user://options.cfg"

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

const _KEYS = [&"last_seen_tutorial", &"theme", &"language", &"check_updates",
				&"check_updates_answered", &"last_update_check"]

var _config_file := ConfigFile.new()
var _timer: Timer


func _ready() -> void:
	# Options
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_save)
	add_child(_timer)
	
	init_options()


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
