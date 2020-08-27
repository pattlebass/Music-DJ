extends Node2D

func _input(event):
	if Input.is_action_pressed("touch") or event.is_pressed():
		global_position = get_global_mouse_position()
	else:
		if 1 == 2:
			pass
		else:
			get_parent().get_node("HBoxContainer/StepContainer").mouse_filter = Control.MOUSE_FILTER_STOP
			queue_free()
