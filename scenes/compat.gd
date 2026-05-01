extends Node


func _ready() -> void:
	move_projects_to_internal()
	convert_projects()


# DEPRECATED v1.0-stable: Move projects on Android to internal app storage
func move_projects_to_internal() -> void:
	if OS.get_name() == "Android":
		var old_dir := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("MusicDJ/Projects")
		if FileAccess.file_exists(old_dir):
			for project in Utils.list_files_in_directory(old_dir, ["mdj", "mdjt"]):
				var old_project_path := old_dir.path_join(project)
				var new_project_path := "user://saves/Projects/".path_join(project)
				if DirAccess.copy_absolute(old_project_path, new_project_path) == OK:
					print("Copied project (%s) from old location" % project)
					DirAccess.remove_absolute(old_project_path)


# DEPRECATED v1.0-stable: Convert projects
func convert_projects() -> void:
	for project in Utils.list_files_in_directory(Variables.projects_dir, ["mdj", "mdjt"]):
		var converted_project := BoomBox.convert_project(Variables.projects_dir.path_join(project)).convert_to_json()
		
		var file_name := Variables.projects_dir.path_join(project.get_basename() + ".mdj")
		var file := FileAccess.open(file_name, FileAccess.WRITE)
		
		if FileAccess.get_open_error():
			printerr(FileAccess.get_open_error())
			return
		
		if project.get_extension() == "mdjt":
			DirAccess.remove_absolute(Variables.projects_dir.path_join(project))
		
		file.store_string(converted_project)
		file.close()
