extends CustomDialog

var column
var column_no


func _ready() -> void:
	Variables.connect("theme_changed", self, "on_theme_changed")


func on_theme_changed(new_theme):
	var path = "res://assets/themes/%s/" % new_theme
	$Sprite.texture = load(path.plus_file("column_tear.png"))


func on_Column_Button_pressed(_column_no, _column):
	column = _column
	column_no = _column_no
	
#	var sprite = get_node("Sprite")
#	var sprite_pos_x = _column.column_button.rect_global_position.x + \
#		_column.column_button.rect_size.x/2
#	sprite.global_position.x = sprite_pos_x
	
	popup()


func about_to_show():
	# Make buttons visible
	if column_no != BoomBox.column_index - 1 or BoomBox.column_index == 15:
		$VBoxContainer/HBoxContainer/RemoveButton.disabled = true
	else:
		$VBoxContainer/HBoxContainer/RemoveButton.disabled = false
	
	
	var has_tiles_set := false
	for i in 4:
		if BoomBox.song[i][column.column_no]:
			has_tiles_set = true
			break
	$VBoxContainer/HBoxContainer/PlayButton.disabled = !has_tiles_set || BoomBox.is_playing
	$VBoxContainer/HBoxContainer/ClearButton.disabled = !has_tiles_set
	
	set_as_minsize()
	
	# TODO: Clean-up
	var pos = column.column_button.rect_global_position
	pos.x -= rect_size.x/2 - column.column_button.rect_size.x/2
	pos.y += column.column_button.rect_size.x
	var viewport_size = get_viewport().get_visible_rect().size
	var pos_plus_size = pos+rect_size+Vector2(16,16)
	if pos_plus_size.x > viewport_size.x:
		pos.x -= pos_plus_size.x - viewport_size.x
	elif pos.x < 0:
		pos.x = 0 + 16
		
	rect_global_position = pos
	
	var sprite_pos_x = column.column_button.rect_global_position.x + \
		column.column_button.rect_size.x/2
	$Sprite.global_position.x = sprite_pos_x
	
	.about_to_show()
	
	rect_pivot_offset = Vector2(sprite_pos_x - pos.x, 0)


func _on_ClearButton_pressed():
	column.clear()
	BoomBox.clear_column(column.column_no)
	
	hide()


func _on_RemoveButton_pressed():
	column.remove()
	main.remove_column(column.column_no)
	
	hide()


func _on_PlayButton_pressed():
	BoomBox.play_column(column_no)
	hide()
