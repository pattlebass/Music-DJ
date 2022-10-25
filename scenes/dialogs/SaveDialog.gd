extends CustomDialog

var type_of_save := "project"

onready var line_edit = $VBoxContainer/VBoxContainer/HBoxContainer/LineEdit
onready var ok_button = $VBoxContainer/HBoxContainer/OkButton
onready var label_title = $VBoxContainer/VBoxContainer/Label
onready var label_error = $VBoxContainer/VBoxContainer/LabelError

signal project_name_picked(file_name)
signal song_name_picked(file_name)


func _ready() -> void:
	if !OS.is_ok_left_and_cancel_right():
		$VBoxContainer/HBoxContainer.move_child(
			$VBoxContainer/HBoxContainer/CancelButton,
			0
		)
	Variables.connect("virtual_keyboard_visible", self, "_on_virtual_kb_visible")
	Variables.connect("virtual_keyboard_hidden", self, "_on_virtual_kb_hidden")


func _on_OkButton_pressed() -> void:
	if type_of_save == "project":
		emit_signal("project_name_picked", line_edit.text)
	elif type_of_save == "export":
		emit_signal("song_name_picked", line_edit.text)
	
	hide()


func _on_CancelButton_pressed() -> void:
	hide()


func about_to_show() -> void:
	if !Variables.has_storage_perms():
		hide()
		return
	
	if type_of_save == "project":
		label_title.text = "DIALOG_SAVE_TITLE_PROJECT"
	elif type_of_save == "export":
		label_title.text = "DIALOG_SAVE_TITLE_EXPORT"
	
	# Changing the text this way doesn't emit the signal
	line_edit.text = Variables.opened_file if Variables.opened_file else get_default_name()
	_on_LineEdit_text_changed(line_edit.text)
	
	line_edit.caret_position = line_edit.text.length()
	
	.about_to_show()


func popup_hide() -> void:
	.popup_hide()
	var dir = Directory.new()
	if OS.get_name() == "HTML5":
		for path in Variables.list_files_in_directory(Variables.exports_dir, ["wav"]):
			print("Removing %s. Code: %s" % [
				"user://_temp".plus_file(path),
				dir.remove("user://_temp".plus_file(path))
			])
		# HACK: Until https://github.com/godotengine/godot/issues/63995 is fixed
		Variables.save_options(0)


func _on_virtual_kb_visible() -> void:
	# Hide title above viewport to make more space
	rect_position.y = -label_title.rect_size.y 


func _on_virtual_kb_hidden() -> void:
	yield(get_tree().create_timer(0.2), "timeout")
	rect_position.y = (get_viewport().get_visible_rect().size.y - rect_size.y) / 2


func _on_LineEdit_text_changed(new_text):
	if not new_text.strip_edges().is_valid_filename() or new_text[0] == ".":
		ok_button.disabled = true
		
		if new_text:
			label_error.text = "Invalid file name: / \\ ? * \" | % < > :"
		
		return
	
	ok_button.disabled = false
	label_error.text = ""


func get_default_name() -> String:
	return "Song " + str(randi() % 1000)


func _on_LineEdit_text_entered(_new_text: String) -> void:
	# Kinda hacky, but this is not an AcceptDialog so it doesn't have
	# the register_text_enter() method
	if ok_button.disabled:
		return
	yield(get_tree().create_timer(0.1), "timeout")
	ok_button.emit_signal("pressed")
