extends Node

var colors = [Color(0.678, 0.847, 90.2), Color(0.565, 0.933, 0.565), Color(1, 0.502, 1), Color(1, 0.894, 0.71)]
var options
var file = File.new()
var current_tutorial_version = 1
var default_options = {"show_tutorial":true, "last_tutorial_version":current_tutorial_version, "theme":"dark"}
var loaded_theme = "dark"
var themes = ["dark", "white", "classic1", "classic2"]
var timer

signal theme_changed

func _ready():
	# Options
	timer = Timer.new()
	timer.one_shot = true
	timer.connect("timeout", self, "on_timer_timeout")
	add_child(timer)
	
	if file.file_exists("user://options.txt"):
		file.open("user://options.txt", File.READ)
		options = file.get_var()
		file.close()
		
		# Show tutorial if outdated
		# This part is very messy
		if options:
			if options.has("last_tutorial_version"):
				if current_tutorial_version > options["last_tutorial_version"]:
					options = default_options.duplicate()
					save_options()
			else:
				options = default_options.duplicate()
				save_options()
		else:
			options = default_options.duplicate()
			save_options()
		
	else:
		options = default_options.duplicate()
		save_options()


func save_options(delay := 2):
	timer.start(delay)


func on_timer_timeout():
	file.open("user://options.txt", File.WRITE)
	file.store_var(options)
	file.close()
	print("Written to options.txt")


func change_theme(new_theme):
	emit_signal("theme_changed", new_theme)
