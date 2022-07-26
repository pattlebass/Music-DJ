extends Node2D

onready var main = get_parent()

var instrument
var sample

signal released

func _input(event: InputEvent) -> void:
	print(event)
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		global_position = get_global_mouse_position()
	elif event.is_action_released("left_click"):
		if $Area2D.get_overlapping_areas():
			var collided_tile = $Area2D.get_overlapping_areas()[0].get_parent()
			var collided_column = collided_tile.get_parent()
			
			if collided_tile.get_meta("instrument") != instrument:
				emit_signal("released")
				queue_free()
				return
			collided_column.set_tile(instrument, sample)
			main.set_tile(instrument, collided_column.column_no, sample)
			
		emit_signal("released")
		queue_free()
	else:
		emit_signal("released")
		queue_free()
