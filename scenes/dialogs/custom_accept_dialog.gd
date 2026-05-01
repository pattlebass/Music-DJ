class_name CustomAcceptDialog
extends CustomDialog


@export var _ok_button: Button
@export var _cancel_button: Button


func _ready() -> void:
	super()
	var button_container := _ok_button.get_parent()
	
	if DisplayServer.get_swap_cancel_ok():
		button_container.move_child(_ok_button, 0)
		button_container.move_child(_cancel_button, button_container.get_child_count())
	else:
		button_container.move_child(_cancel_button, 0)
		button_container.move_child(_ok_button, button_container.get_child_count())
