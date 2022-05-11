extends VBoxContainer

var column_no := 0

onready var anim_player = $AnimationPlayer
onready var column_button = $ColumnButton


func set_tile(instrument: int, sample_category: int, text: String) -> void:
	var tile = get_node("Button" + str(instrument + 1))
	
	var style_box = preload("res://assets/button_stylebox.tres").duplicate()
	
	style_box.bg_color = get_theme().get_color(
		Variables.category_names[sample_category],
		"Tile"
	)
	tile.set("custom_styles/normal", style_box)
	tile.set("custom_styles/pressed", style_box)
	tile.set("custom_styles/disabled", style_box)
	tile.set("custom_styles/hover", style_box)
	tile.set("custom_styles/focus", StyleBoxEmpty)
	
	tile.text = text


func clear() -> void:
	for i in 4:
		clear_tile(i)


func clear_tile(instrument: int) -> void:
	var tile = get_node("Button" + str(instrument + 1))
	tile.text = ""
	tile.set("custom_styles/normal", null)
	tile.set("custom_styles/pressed", null)
	tile.set("custom_styles/disabled", null)
	tile.set("custom_styles/hover", null)


func on_play_started() -> void:
	column_button.set("custom_colors/font_color", Color.red)


func on_play_ended() -> void:
	column_button.set("custom_colors/font_color", null)


func fade_in() -> void:
	anim_player.play("fade_in")

func add(_column_no: int):
	column_no = _column_no
	column_button.text = str(_column_no + 1)


func remove() -> void:
	anim_player.play_backwards("fade_in")
	yield(anim_player, "animation_finished")
	queue_free()


func get_theme():
	var control = self
	var theme = null
	while control != null && "theme" in control:
		theme = control.theme
		if theme != null: break
		control = control.get_parent()
	return theme
