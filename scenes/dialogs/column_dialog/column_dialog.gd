class_name ColumnDialog
extends CustomDialog

@onready var play_button: Button = %PlayButton
@onready var play_column_button: Button = %PlayColumnButton
@onready var duplicate_button: Button = %DuplicateButton
@onready var new_button: Button = %NewButton
@onready var clear_button: Button = %ClearButton
@onready var remove_button: Button = %RemoveButton
@onready var tear: TextureRect = %Tear

var column: Column

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
	remove_button.disabled = BoomBox.song.get_length() <= 1
	play_column_button.disabled = is_column_empty or BoomBox.is_playing
	play_button.disabled = is_column_empty or BoomBox.is_playing
	clear_button.disabled = is_column_empty
	duplicate_button.disabled = is_column_empty or BoomBox.is_playing
	new_button.disabled = BoomBox.is_playing
	
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
	Variables.main.remove_column(column.column_no)
	BoomBox.song.remove_column(column.column_no)
	
	hide()


func _on_play_button_pressed():
	BoomBox.play_from_column(column.column_no)
	hide()


func _on_play_column_button_pressed():
	BoomBox.play_column(column.column_no)
	hide()


func _on_duplicate_button_pressed() -> void:
	BoomBox.song.add_column(column.column_no + 1)
	var new_column: Column = Variables.main.add_column(column.column_no + 1)
	
	for instrument in BoomBox.song.data.size():
		var sample: int = BoomBox.song.data[instrument][column.column_no]
		BoomBox.song.set_tile(instrument, column.column_no + 1, sample)
		new_column.set_tile(instrument, sample)
	
	hide()


func _on_new_button_pressed() -> void:
	BoomBox.song.add_column(column.column_no + 1)
	Variables.main.add_column(column.column_no + 1)
	hide()
