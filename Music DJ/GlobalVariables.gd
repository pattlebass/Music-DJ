extends Node

var colors = [Color(0.678, 0.847, 90.2), Color(0.565, 0.933, 0.565), Color(1, 0.502, 1), Color(1, 0.894, 0.71)]
var options
var file = File.new()
var current_tutorial_version = 1

func _ready():
	if file.file_exists("user://options.txt"):
		file.open("user://options.txt", File.READ)
		options = file.get_var()
		
		# Show tutorial if outdated
		# This part is very messy
		if options.has("last_tutorial_version"):
			if current_tutorial_version > options["last_tutorial_version"]:
				options = {"show_tutorial":true, "last_tutorial_version":current_tutorial_version}
		else:
			options = {"show_tutorial":true, "last_tutorial_version":current_tutorial_version}
		
	else:
		options = {"show_tutorial":true, "last_tutorial_version":current_tutorial_version}
		file.open("user://options.txt", File.WRITE)
		file.store_var(options)

func save_options():
	file.open("user://options.txt", File.WRITE)
	file.store_var(options)
