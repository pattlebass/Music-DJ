extends VBoxContainer

var column_no: int

onready var anim_player = $AnimationPlayer
onready var column_button = $ColumnButton


func _ready() -> void:
	$Button1.set_meta("instrument", 0)
	$Button2.set_meta("instrument", 1)
	$Button3.set_meta("instrument", 2)
	$Button4.set_meta("instrument", 3)


func set_tile(instrument: int, sample_index: int) -> void:
	var tile = get_node("Button" + str(instrument + 1))
	
	if sample_index == 0:
		clear_tile(instrument)
		return
	
	var text := ""
	var category: int
	
	if sample_index in range(1, 9):
		text = str(sample_index)
		category = 0
	elif sample_index in range(9, 17):
		text = str(sample_index - 8)
		category = 1
	elif sample_index in range(17, 25):
		text = str(sample_index - 16)
		category = 2
	elif sample_index in range(25, 33):
		text = str(sample_index - 24)
		category = 3
	
	tile.text = text
	tile.set_meta("sample_index", sample_index)
	
	var style_box = get_stylebox(Variables.category_names[category], "Tile")

	tile.set("custom_styles/normal", style_box)
	tile.set("custom_styles/pressed", style_box)
	tile.set("custom_styles/disabled", style_box)
	tile.set("custom_styles/hover", style_box)
#	tile.set("custom_styles/focus", StyleBoxEmpty)


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

func add(_column_no: int) -> void:
	column_no = _column_no
	column_button.text = str(_column_no + 1)


func remove() -> void:
	anim_player.play_backwards("fade_in")
	yield(anim_player, "animation_finished")
	queue_free()


func _notification(what) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		for instrument in 4:
			var sample_index = 0
			if get_child(instrument + 1).has_meta("sample_index"):
				sample_index = get_child(instrument + 1).get_meta("sample_index")
			set_tile(instrument, sample_index)
