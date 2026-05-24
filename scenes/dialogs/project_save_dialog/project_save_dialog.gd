extends FilenameDialog


func _on_OkButton_pressed() -> void:
	super()
	var file_name := line_edit.text.strip_edges()
	var path := Variables.projects_dir.path_join("%s.mdj" % file_name)
	path_picked.emit(path)
