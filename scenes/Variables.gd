extends Node

var colors = [Color(0.678, 0.847, 90.2), Color(0.565, 0.933, 0.565), Color(1, 0.502, 1), Color(1, 0.894, 0.71)]
var current_tutorial_version = 1
var options = {
	"last_seen_tutorial": -1, # Hasn't seen the tutorial
	"theme": "dark"
}
var themes = ["dark", "white", "classic1", "classic2"]
var timer
var user_dir := ""

const category_names = ["Introduction", "Verse", "Chorus", "Solo"]
const instrument_names = ["Drums", "Bass", "Keys", "Trumpet"]

signal theme_changed

var file = File.new()

func _ready():
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
	print("Loaded options.json")


func save_options(delay := 2):
	timer.start(delay)


func on_timer_timeout():
	file.open("user://options.json", File.WRITE)
	file.store_string(to_json(options))
	file.close()
	print("Written to options.json")


func change_theme(new_theme):
	emit_signal("theme_changed", new_theme)


func has_storage_perms() -> bool:
	if OS.get_granted_permissions().empty() && OS.get_name() == "Android":
		return OS.request_permissions()
	return true
