class_name ColumnDialog
extends CustomDialog

@onready var play_button: Button = %PlayButton
@onready var play_column_button: Button = %PlayColumnButton
@onready var clear_button: Button = %ClearButton
@onready var remove_button: Button = %RemoveButton
@onready var tear: TextureRect = %Tear

var column: Column

signal removed_column


func _ready() -> void:
	super()
	dim_background = false
	
	Utils.theme_changed.connect(_on_theme_changed)


func _on_theme_changed(new_theme: String):
	var path := "res://assets/themes/%s/" % new_theme
	tear.texture = load(path.path_join("column_tear.png"))


func popup_on_column(p_column: Column):
	column = p_column
	popup2()


func popup2():
	var is_column_empty := BoomBox.song.is_column_empty(column.column_no)
	remove_button.disabled = column.column_no != BoomBox.song.get_length() - 1 \
			or column.column_no < Variables.MINIMUM_COLUMNS
	play_button.disabled = is_column_empty or BoomBox.is_playing
	play_column_button.disabled = is_column_empty or BoomBox.is_playing
	clear_button.disabled = is_column_empty
	
	# Positioning
	var new_pos := column.column_button.global_position
	new_pos.x -= (size.x - column.column_button.size.x) / 2
	new_pos.y += column.column_button.size.y
	position = new_pos
	
	# TODO: Wait for offset transforms
	#var local_target_pos := column.column_button.global_position - new_pos
	#tear.position.x = local_target_pos.x + column.column_button.size.x / 2
	
	play_button.grab_focus.call_deferred()
	
	super()
	
	#pivot_offset = Vector2(tear.global_position.x - global_position.x, 0)


func _on_clear_button_pressed():
	column.clear()
	BoomBox.song.clear_column(column.column_no)
	
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
