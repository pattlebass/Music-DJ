class_name FloatButton
extends Node2D

var instrument: int
var sample: int

@onready var area: Area2D = $Area2D

signal released


func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		global_position = get_global_mouse_position()
		return
	
	if area.has_overlapping_areas():
		var collided_tile: Button = area.get_overlapping_areas()[0].get_parent()
		var collided_column: Column = collided_tile.get_parent()
		
		if collided_tile.get_meta(&"instrument") != instrument:
			released.emit()
			queue_free()
			return
		collided_column.set_tile(instrument, sample)
		BoomBox.song.set_tile(instrument, collided_column.column_no, sample)
	
	released.emit()
	queue_free()
