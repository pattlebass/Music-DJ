class_name FloatButton
extends Node2D

signal released(collided_instrument: int, collided_column_no: int)


func _ready() -> void:
	global_position = get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		# Still dragging
		global_position = get_global_mouse_position()
		return
	
	if not (event is InputEventMouseButton and event.is_released()):
		# Capture any other event besides releasing the mouse button
		return
	
	var space_state := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.collide_with_areas = true
	params.position = get_global_mouse_position()
	var result := space_state.intersect_point(params)
	var collided_instrument := 0
	var collided_column: Column = null
	
	if not result.is_empty():
		var collided_tile: Button = result[0].collider.get_parent()
		collided_column = collided_tile.get_parent()
		collided_instrument = collided_tile.get_meta(&"instrument")
	
	released.emit(collided_instrument, collided_column)
	queue_free()


func add_fake_tile(fake_tile: Button) -> void:
	fake_tile.pivot_offset = fake_tile.size / 2
	fake_tile.scale *= 1.5
	fake_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in fake_tile.get_children():
		i.queue_free()
	add_child(fake_tile)
	fake_tile.position = -fake_tile.size * fake_tile.scale / 2
