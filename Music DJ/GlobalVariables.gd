extends Node

var colors = [Color(0.678, 0.847, 90.2), Color(0.565, 0.933, 0.565), Color(1, 0.502, 1), Color(1, 0.894, 0.71)]
var options
var file = File.new()

func _ready():
	if file.file_exists("user://options.txt"):
		file.open("user://options.txt", File.READ)
		options = file.get_var()
	else:
		options = {"show_tutorial":true}
		file.open("user://options.txt", File.WRITE)
		file.store_var(options)

func save_options():
	file.open("user://options.txt", File.WRITE)
	file.store_var(options)
