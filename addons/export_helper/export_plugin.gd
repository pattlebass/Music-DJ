extends EditorExportPlugin

const FINAL_DIR = "res://bin/_final"


func _get_name() -> String:
	return "Export Helper"


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	var base_dir := "res://".path_join(path.get_base_dir())
	
	if not base_dir.begins_with("res://bin"):
		return
	
	print()
	print("Deleting %s" % base_dir)
	
	if DirAccess.dir_exists_absolute(base_dir):
		remove_recursive(base_dir)
	DirAccess.make_dir_recursive_absolute(base_dir)
	DirAccess.make_dir_recursive_absolute(FINAL_DIR)


func _export_end() -> void:
	var platform := get_export_platform()
	var platform_name := platform.get_os_name()
	
	var export_preset := get_export_preset()
	var export_path := export_preset.get_export_path()
	var base_dir := "res://".path_join(export_path.get_base_dir())
	var base_name := export_path.get_basename().get_file()
	
	if not base_dir.begins_with("res://bin"):
		return
	
	var archive_path = FINAL_DIR.path_join("%s.%s.zip" % [base_name, platform_name])
	
	if platform_name == "Web":
		var dir := DirAccess.open(base_dir)
		if dir == null:
			printerr("Error renaming file (%s): %s" % [export_path.get_file(), error_string(DirAccess.get_open_error())])
			return
		var err := dir.rename(export_path.get_file(), "index.html")
		if err != OK:
			printerr("Error renaming file (%s): %s" % [export_path.get_file(), error_string(err)])
	
	if platform_name == "Android":
		for f in DirAccess.get_files_at(base_dir):
			DirAccess.copy_absolute(base_dir.path_join(f), FINAL_DIR.path_join(f))
		return
	
	archive_files(archive_path, base_dir, DirAccess.get_files_at(base_dir))
	
	print("Archived %s" % archive_path.get_file())


func remove_recursive(directory: String) -> void:
	if not directory.begins_with("res://"):
		printerr("Almost deleted your drive :)")
		return
	
	for dir_name in DirAccess.get_directories_at(directory):
		remove_recursive(directory.path_join(dir_name))
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	
	DirAccess.remove_absolute(directory)


func archive_files(path: String, base_dir: String, files: PackedStringArray) -> Error:
	var writer := ZIPPacker.new()
	var err := writer.open(path)
	if err != OK:
		printerr("Error opening archive (%s): %s" % [path, error_string(err)])
		return err
	
	for filepath in files:
		filepath = base_dir.path_join(filepath)
		var file_access := FileAccess.open(filepath, FileAccess.READ)
		if file_access == null:
			err = FileAccess.get_open_error()
			printerr("Error opening file (%s) for archiving: %s" % [filepath.get_file(), error_string(err)])
			return err
		writer.start_file(filepath.get_file())
		writer.write_file(file_access.get_buffer(file_access.get_length()))
		writer.close_file()
	
	writer.close()
	return OK
