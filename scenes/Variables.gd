extends Node

var options = {
	"last_seen_tutorial": -1, # Hasn't seen the tutorial
	"theme": "dark",
	"language": "", # Auto
	"check_updates": null,
}
var current_tutorial_version = 1
var timer: Timer
var file := File.new()
var saves_dir := "user://saves/"
var projects_dir := "user://saves/Projects/"
var exports_dir := "user://saves/Exports/"
var clipboard
var opened_file := ""

var share_service

onready var VERSION = load("res://version.gd").VERSION

const category_names = ["Introduction", "Verse", "Chorus", "Solo"]
const instrument_names = [
	"INSTRUMENT_DRUMS",
	"INSTRUMENT_BASS",
	"INSTRUMENT_KEYS",
	"INSTRUMENT_TRUMPET"
]
const MINIMUM_DRAG = 100

onready var main = get_node("/root/main/")

signal theme_changed
signal virtual_keyboard_visible
signal virtual_keyboard_hidden


func _ready() -> void:
	get_tree().connect("node_added", self, "_node_added")
	get_tree().connect("node_removed", self, "_node_removed")
	
	traverse(main)
	
	# Singletons
	if Engine.has_singleton("GodotFileSharing"):
		share_service = Engine.get_singleton("GodotFileSharing")
	
	# Set directories
	if OS.get_name() == "Android":
		has_storage_perms()
		exports_dir = OS.get_system_dir(OS.SYSTEM_DIR_MUSIC).plus_file("MusicDJ")
	
	# Make directories
	var dir = Directory.new()
	dir.make_dir_recursive(projects_dir)
	dir.make_dir_recursive(exports_dir)
	
	# Demo song
	if not dir.file_exists(projects_dir.plus_file("Demo.mdj")):
		dir.copy("res://demo.mdj", projects_dir.plus_file("Demo.mdj"))
	
	# Options
	timer = Timer.new()
	timer.one_shot = true
	timer.connect("timeout", self, "on_timer_timeout")
	add_child(timer)
	
	if not file.file_exists("user://options.json"):
		print("Created options.json")
		save_options(0)
		return
	
	file.open("user://options.json", File.READ)
	var json_result := JSON.parse(file.get_as_text())
	file.close()
	
	if json_result.error:
		printerr("Json parse error: ", json_result.error_string)
		save_options(0)
		return
	
	var file_options: Dictionary = json_result.result
	
	var file_keys = file_options.keys()
	var options_keys = options.keys()
	file_keys.sort()
	options_keys.sort()
	
	if file_keys != options_keys:
		print("options.json on disk has different keys")
		for i in file_options.keys():
			if options.has(i):
				options[i] = file_options[i]
		save_options(0)
		return
	
	options = file_options
	
	if options.language:
		TranslationServer.set_locale(options.language)
	
	print("Loaded options.json")


func save_options(delay := 2) -> void:
	timer.start(delay)


func on_timer_timeout() -> void:
	file.open("user://options.json", File.WRITE)
	file.store_string(to_json(options))
	file.close()
	print("Written to options.json")


func change_theme(new_theme) -> void:
	emit_signal("theme_changed", new_theme)


func has_storage_perms() -> bool:
	if OS.get_granted_permissions().empty() && OS.get_name() == "Android":
		return OS.request_permissions()
	return true


func download_file(_file_path, _file_name):
	if OS.get_name() == "HTML5":
		file.open(_file_path, File.READ)
		var file_data_raw := file.get_buffer(file.get_len())
		file.close()
		
		var mime_type
		if _file_name.ends_with(".wav"):
			mime_type = "audio/wav"
		elif _file_name.ends_with(".mdj"):
			mime_type = "application/octet-stream"
		
		JavaScript.download_buffer(file_data_raw, _file_name, mime_type)
	else: # Android
		var dir = Directory.new()
		var destination_dir := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS).plus_file("MusicDJ")
		dir.make_dir(destination_dir)
		
		var err = dir.copy(_file_path, destination_dir.plus_file(_file_name))
		if err:
			printerr("Failed to copy project (%s) to %s: " % [_file_name, destination_dir] + err)
		else:
			print("Copied project (%s) to %s" % [_file_name, destination_dir])


func share_file(path: String, title: String, subject: String, text: String, mimeType: String) -> void:
	if share_service == null:
		return
	share_service.shareFile(ProjectSettings.globalize_path(path), title, subject, text, mimeType)


func list_files_in_directory(path: String, extensions := [""]) -> Array:
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


func confirm_popup(title: String, body: String) -> bool:
	var dialog = preload("res://scenes/dialogs/ConfirmationDialog.tscn").instance()
	
	main.add_child(dialog)
	dialog.alert(title, body)
	
	return yield(dialog, "chose")


func truncate(string: String, max_length: int) -> String:
	if string.length() > max_length:
		return string.left(max_length - 3) + "..."
	return string


# Virtual keyboard signals

var virtual_kb_up := false

func _process(_delta):
	if OS.get_virtual_keyboard_height() == 0:
		if virtual_kb_up:
			virtual_kb_up = false
			emit_signal("virtual_keyboard_hidden")
	else:
		if not virtual_kb_up:
			virtual_kb_up = true
			emit_signal("virtual_keyboard_visible")


# Keyboard focus

var buttons := []
var show_focus := false

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_focus_next")
		or event.is_action_pressed("ui_focus_prev")
		or event.is_action_pressed("ui_left")
		or event.is_action_pressed("ui_right")
		or event.is_action_pressed("ui_up")
		or event.is_action_pressed("ui_down")):
		
		show_focus = true
		for i in buttons:
			i.set("custom_styles/focus", null)
		
		if not main.get_focus_owner():
			main.play_button.call_deferred("grab_focus")
		
	elif event.is_action_pressed("left_click"):
		show_focus = false
		for i in buttons:
			i.set("custom_styles/focus", StyleBoxEmpty.new())


func _node_added(node) -> void:
	if node is Button:
		if not show_focus and node.focus_mode == Control.FOCUS_ALL:
			node.set("custom_styles/focus", StyleBoxEmpty.new())
		buttons.append(node)

func _node_removed(node) -> void:
	if node in buttons:
		buttons.erase(node)


func traverse(child) -> void:
	for i in child.get_children():
		traverse(i)
	_node_added(child)
