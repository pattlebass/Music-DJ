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
var user_dir := ""
var clipboard

const category_names = ["Introduction", "Verse", "Chorus", "Solo"]
const instrument_names = [
	"INSTRUMENT_DRUMS",
	"INSTRUMENT_BASS",
	"INSTRUMENT_KEYS",
	"INSTRUMENT_TRUMPET"
]

onready var main = get_node("/root/main/")

signal theme_changed


func _ready() -> void:
	traverse(main)
	get_tree().connect("node_added", self, "_node_added")
	get_tree().connect("node_removed", self, "_node_removed")
	
	# Options
	timer = Timer.new()
	timer.one_shot = true
	timer.connect("timeout", self, "on_timer_timeout")
	add_child(timer)
	
	if !file.file_exists("user://options.json"):
		print("Created options.json")
		save_options(0)
		return
	
	file.open("user://options.json", File.READ)
	var file_options: Dictionary = parse_json(file.get_as_text())
	file.close()
	
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
			yield(get_tree(), "idle_frame")
			main.play_button.grab_focus()
		
	elif event.is_action_pressed("left_click"):
		show_focus = false
		for i in buttons:
			i.set("custom_styles/focus", StyleBoxEmpty.new())


func _node_added(node) -> void:
	if node is Button:
		if not show_focus:
			node.set("custom_styles/focus", StyleBoxEmpty.new())
		buttons.append(node)

func _node_removed(node) -> void:
	if node in buttons:
		buttons.erase(node)


func traverse(child) -> void:
	for i in child.get_children():
		traverse(i)
	_node_added(child)
