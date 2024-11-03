class_name ColumnDialog
extends CustomDialog

@onready var play_button: Button = %PlayButton
@onready var play_column_button: Button = %PlayColumnButton
@onready var clear_button: Button = %ClearButton
@onready var remove_button: Button = %RemoveButton
@onready var tear: Sprite2D = %Tear

var column: Column

signal removed_column


func _ready() -> void:
	dim_background = false
	
	Utils.theme_changed.connect(_on_theme_changed)


func _on_theme_changed(new_theme: String):
	var path := "res://assets/themes/%s/" % new_theme
	tear.texture = load(path.path_join("column_tear.png"))


func _on_column_button_pressed(p_column: Column):
	column = p_column
	popup()


func popup():
	var is_column_empty := BoomBox.song.is_column_empty(column.column_no)
	remove_button.disabled = column.column_no != BoomBox.song.get_length() - 1 \
			or column.column_no < Variables.MINIMUM_COLUMNS
	play_button.disabled = is_column_empty or BoomBox.is_playing
	play_column_button.disabled = is_column_empty or BoomBox.is_playing
	clear_button.disabled = is_column_empty
	
	# Positioning
	var new_pos := column.column_button.global_position
	new_pos.x -= (size.x - column.column_button.size.x) / 2
	new_pos.y += column.column_button.size.x
	
	var viewport_size := get_viewport().get_visible_rect().size
	if new_pos.x + size.x > viewport_size.x:
		new_pos.x = viewport_size.x - size.x
	if new_pos.x < 0:
		new_pos.x = 0
	
	global_position = new_pos
	tear.global_position.x = column.column_button.global_position.x + column.column_button.size.x / 2
	
	play_button.grab_focus.call_deferred()
	
	super()
	
	pivot_offset = Vector2(tear.global_position.x - global_position.x, 0)


func _on_clear_button_pressed():
	column.clear()
	BoomBox.song.remove_column(column.column_no)
	
	hide()


func _on_remove_button_pressed():
	column.remove()
	removed_column.emit()
	
	hide()


func _on_play_button_pressed():
	BoomBox.play_from_column(column.column_no)
	hide()


func _on_play_column_button_pressed():
	BoomBox.play_column(column.column_no)
	hide()
