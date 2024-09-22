class_name FilenameDialog
extends CustomAcceptDialog

var title := "Save":
	set(val):
		if val == title:
			return
		title = val
		label_title.text = title

@onready var ok_button = %OkButton
@onready var label_title: Label = %Title
@onready var line_edit: LineEdit = %LineEdit
@onready var label_error: Label = %Error

signal name_picked(file_name)


func _ready() -> void:
	super()
	
	Utils.virtual_keyboard_visible.connect(_on_virtual_kb_visible)
	Utils.virtual_keyboard_hidden.connect(_on_virtual_kb_hidden)


func popup() -> void:
	if not Utils.has_storage_perms():
		popup_hide()
		return
	
	line_edit.text = Variables.opened_file if Variables.opened_file else get_default_name()
	line_edit.caret_column = line_edit.text.length()
	_on_LineEdit_text_changed(line_edit.text) # Manually call the callback
	
	super()


func popup_hide() -> void:
	super()
	Utils.signal_disconnect_all(name_picked)


func get_default_name() -> String:
	return "Song " + str(randi() % 1000)


func _on_OkButton_pressed() -> void:
	name_picked.emit(line_edit.text.strip_edges())
	popup_hide()


func _on_CancelButton_pressed() -> void:
	popup_hide()


func _on_virtual_kb_visible() -> void:
	# Hide title above viewport to make more space
	position.y = -label_title.size.y 


func _on_virtual_kb_hidden() -> void:
	await get_tree().create_timer(0.2).timeout
	position.y = (get_viewport().get_visible_rect().size.y - size.y) / 2


func _on_LineEdit_text_changed(new_text: String) -> void:
	var invalid_filename := not new_text.strip_edges().is_valid_filename() or new_text[0] == "."
	ok_button.disabled = invalid_filename
	label_error.visible = invalid_filename and not new_text.is_empty()


func _on_LineEdit_text_entered(new_text: String) -> void:
	# Substitute AcceptDialog's register_text_enter()
	if ok_button.disabled:
		return
	ok_button.pressed.emit()
