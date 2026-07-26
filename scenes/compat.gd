extends Node


func _ready() -> void:
	move_web_project()


func move_web_project() -> void:
	if OS.get_name() != "Web":
		return
	
	if not DirAccess.dir_exists_absolute("/userfs/saves/Projects"):
		return
	
	print("Compat: move_web_project start")
	
	var dir := DirAccess.open("/userfs/saves/Projects")
	for file_path in dir.get_files():
		var new_path := Variables.projects_dir.path_join(file_path)
		
		if FileAccess.file_exists(new_path):
			var addition := "(moved %s)" % (int(Time.get_unix_time_from_system()) % 100000)
			new_path = new_path.get_basename() + addition + "." + new_path.get_extension()
		
		var abs_file_path := dir.get_current_dir().path_join(file_path)
		var move_err := DirAccess.rename_absolute(abs_file_path, new_path)
		if move_err:
			printerr("Error %s when moving '%s' to '%s'" % [move_err, file_path, new_path])
		else:
			print("Moved '%s' to '%s'" % [file_path, new_path])
			
			var song := BoomBox.convert_project(new_path)
			var conv_err := song.save(new_path)
			if conv_err:
				print("Error %s when saving converted song." % conv_err)
	
	print("Compat: move_web_project end")
