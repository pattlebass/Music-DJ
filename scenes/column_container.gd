class_name ColumnContainer
extends Container

const COLUMN = preload("res://scenes/column/column.tscn")

const MOVE_DURATION = 0.1
var separation := 8

var columns: Array[Column] = []
var do_animation := true
var moving_column: Column
var column_size := Vector2()

signal column_added(column: Column)


func _ready() -> void:
	BoomBox.song_loaded.connect(_on_song_loaded)
	BoomBox.column_play_started.connect(_on_column_play_started)
	BoomBox.column_play_ended.connect(_on_column_play_ended)


func add_column(column_no: int, fade := true) -> Column:
	var column: Column = COLUMN.instantiate()
	add_child(column)
	column.position.x = compute_position(column_no) - 50
	move_child(column, column_no)
	column.add(column_no)
	
	column_size = column.size # Kinda hacky
	
	# Signals
	column.drag_started.connect(_on_column_drag_started.bind(column))
	column.drag_ended.connect(_on_column_drag_ended.bind(column))
	if fade:
		column.fade_in()
	
	columns.insert(column_no, column)
	
	# Renumber columns
	for i in range(column_no + 1, columns.size()):
		columns[i].add(i)
	
	column_added.emit(column)
	
	return column


func _on_tile_changed(instrument: int, column_no: int, sample_index: int) -> void:
	columns[column_no].set_tile(instrument, sample_index)


func remove_column(column_no: int) -> void:
	await columns[column_no].remove()
	columns.remove_at(column_no)
	
	# Renumber columns
	for i in columns.size():
		columns[i].add(i)


func move_column(from_no: int, to_no: int) -> void:
	var column := columns[from_no]
	columns.remove_at(from_no)
	columns.insert(to_no, column)
	
	move_child(column, to_no)
	
	for i in columns.size():
		columns[i].add(i)


func _on_song_loaded() -> void:
	do_animation = false
	
	for column in columns:
		column.queue_free()
	columns.clear()
	
	for instrument in BoomBox.song.data.size():
		for column_no in BoomBox.song.data[instrument].size():
			if column_no >= columns.size():
				add_column(column_no, false)
			
			var column := columns[column_no]
			var sample: int = BoomBox.song.data[instrument][column_no]
			column.set_tile(instrument, sample)
	
	sort_children.connect(func(): do_animation = true) # Otherwise sort() gets called first
	
	# Signals
	BoomBox.song.added_column.connect(add_column)
	BoomBox.song.removed_column.connect(remove_column)
	BoomBox.song.moved_column.connect(move_column)
	# We do this here instead of inside Column just for performance reasons
	BoomBox.song.tile_changed.connect(_on_tile_changed)


func _on_column_play_started(column_no: int) -> void:
	columns[column_no].start_play()


func _on_column_play_ended(column_no: int) -> void:
	columns[column_no].end_play()


#region Cotainer stuff

func _process(delta: float) -> void:
	if moving_column != null:
		moving_column.global_position.x = get_global_mouse_position().x - column_size.x / 2
		var new_column_no := compute_index_from_position(moving_column.position.x)
		if new_column_no != moving_column.column_no:
			BoomBox.song.move_column(moving_column.column_no, new_column_no)


func _on_column_drag_started(column: Column) -> void:
	moving_column = column


func _on_column_drag_ended(column: Column) -> void:
	moving_column = null
	var new_pos: float = compute_position(column.column_no)
	create_tween().tween_property(column, ^"position:x", new_pos, MOVE_DURATION)


func sort() -> void:
	var i := 0
	var total_width := 0.0
	var tween := create_tween().set_parallel(true)
	
	for column in columns:
		var new_pos: float = compute_position(i)
		
		if column != moving_column:
			var duration := MOVE_DURATION if do_animation else 0.0
			tween.tween_property(column, ^"position:x", new_pos, duration)
		
		total_width = new_pos + column.size.x
		i += 1
	
	custom_minimum_size.x = total_width


func compute_position(index: int) -> float:
	return index * (column_size.x + separation)


func compute_index_from_position(pos: float) -> int:
	return clampi(roundi(pos / (column_size.x + separation)), 0, columns.size() - 1)

#endregion


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		sort()
	#elif what == NOTIFICATION_THEME_CHANGED:
		#separation = get_theme_constant(&"separation")
