class_name CustomAcceptDialog
extends CustomDialog


@export var _ok_button: Button
@export var _cancel_button: Button


func _ready() -> void:
	var container := _ok_button.get_parent()
	
	if DisplayServer.get_swap_cancel_ok():
		container.move_child(_ok_button, 0)
		container.move_child(_cancel_button, container.get_child_count())
	else:
		container.move_child(_cancel_button, 0)
		container.move_child(_ok_button, container.get_child_count())
