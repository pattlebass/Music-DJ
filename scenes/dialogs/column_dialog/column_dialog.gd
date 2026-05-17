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
	
	Utils.theme_changed.connect(_on_theme_changed)


func _on_theme_changed(new_theme: String):
	var path := "res://assets/themes/%s/" % new_theme
	tear.texture = load(path.path_join("column_tear.png"))


func open_on_column(p_column: Column):
	column = p_column
	open()


func _populate() -> void:
	var is_column_empty := BoomBox.song.is_column_empty(column.column_no)
	play_column_button.disabled = is_column_empty or BoomBox.is_playing
	play_button.disabled = is_column_empty or BoomBox.is_playing
	duplicate_button.disabled = is_column_empty or BoomBox.is_playing
	new_button.disabled = BoomBox.is_playing
	clear_button.disabled = is_column_empty or BoomBox.is_playing
	remove_button.disabled = (
		BoomBox.song.get_length() <= Variables.MINIMUM_COLUMNS or BoomBox.is_playing
	)
	
	# Positioning
	var new_pos := column.column_button.global_position
	new_pos.x -= (size.x - column.column_button.size.x) / 2
	new_pos.y += column.column_button.size.y
	position = new_pos
	
	# TODO: Wait for offset transforms
	#var local_target_pos := column.column_button.global_position - new_pos
	#tear.position.x = local_target_pos.x + column.column_button.size.x / 2
	
	play_button.grab_focus.call_deferred()
	
	#pivot_offset = Vector2(tear.global_position.x - global_position.x, 0)


func _on_play_button_pressed():
	BoomBox.play_from_column(column.column_no)
	close()


func _on_play_column_button_pressed():
	BoomBox.play_column(column.column_no)
	close()


func _on_duplicate_button_pressed() -> void:
	BoomBox.song.duplicate_column(column.column_no)
	close()


func _on_new_button_pressed() -> void:
	BoomBox.song.add_column(column.column_no + 1)
	close()


func _on_clear_button_pressed():
	BoomBox.song.clear_column(column.column_no)
	close()


func _on_remove_button_pressed():
	BoomBox.song.remove_column(column.column_no)
	close()
