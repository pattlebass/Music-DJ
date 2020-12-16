extends Node

var colors = [Color(0.678, 0.847, 90.2), Color(0.565, 0.933, 0.565), Color(1, 0.502, 1), Color(1, 0.894, 0.71)]
var options
var file = File.new()
var current_tutorial_version = 1
var default_options = {"show_tutorial":true, "last_tutorial_version":current_tutorial_version, "theme":"dark"}
var theme = "dark"
var themes = ["dark", "white", "classic1", "classic2"]
var last_song


func _ready():
	# Options
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
			else:
				options = default_options.duplicate()
		else:
			options = default_options.duplicate()
		
	else:
		options = default_options.duplicate()
	save_options()

func save_options():
	file.open("user://options.txt", File.WRITE)
	file.store_var(options)
	file.close()
