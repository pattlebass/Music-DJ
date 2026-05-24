extends FilenameDialog

@onready var native_file_dialog: FileDialog = %NativeFileDialog


func _ready() -> void:
	super()
	native_file_dialog.file_selected.connect(path_picked.emit)


func open() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		native_file_dialog.current_file = Variables.opened_file if Variables.opened_file else get_default_name()
		native_file_dialog.popup_file_dialog()
		return
	super()


func _on_OkButton_pressed() -> void:
	super()
	var file_name := line_edit.text.strip_edges()
	var path := Variables.projects_dir.path_join("%s.wav" % file_name)
	path_picked.emit(path)
