class_name CustomConfirmDialog
extends CustomAcceptDialog

@onready var title_label: Label = %Title
@onready var body_label: RichTextLabel = %Body

signal chose


func alert(p_title: String, subtitle: String) -> void:
	title_label.text = p_title
	body_label.text = subtitle
	open()


func _populate() -> void:
	_cancel_button.grab_focus.call_deferred()


func _cleanup() -> void:
	await get_tree().create_timer(0.1).timeout
	queue_free()


func _on_ok_button_pressed() -> void:
	close()
	chose.emit(true)


func _on_cancel_button_pressed() -> void:
	close()
	chose.emit(false)
