class_name Column
extends VBoxContainer

const CONTEXT_MENU = preload("res://scenes/dialogs/context_menu/context_menu.tscn")

var column_no: int

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var column_button: Button = $ColumnButton
@onready var tiles: Array[Button] = [$Button1, $Button2, $Button3, $Button4]

signal removed


func _ready() -> void:
	for i in tiles.size():
		tiles[i].set_meta(&"instrument", i)
		tiles[i].set_meta(&"sample_index", 0)
		tiles[i].gui_input.connect(_on_tile_gui_input.bind(tiles[i]))


func set_tile(instrument: int, sample_index: int) -> void:
	var tile := tiles[instrument]
	
	if sample_index == 0:
		clear_tile(instrument)
		return
	
	tile.text = str(sample_index)
	tile.set_meta(&"sample_index", sample_index)
	
	var category := (sample_index - 1) / 8
	var style_box := get_theme_stylebox(Variables.CATEGORY_NAMES[category], &"Tile")
	tile.add_theme_stylebox_override(&"normal", style_box)
	tile.add_theme_stylebox_override(&"pressed", style_box)
	tile.add_theme_stylebox_override(&"disabled", style_box)
	tile.add_theme_stylebox_override(&"hover", style_box)


func clear() -> void:
	for i in 4:
		clear_tile(i)


func clear_tile(instrument: int) -> void:
	var tile := tiles[instrument]
	
	tile.set_meta(&"sample_index", 0)
	
	tile.text = ""
	tile.remove_theme_stylebox_override(&"normal")
	tile.remove_theme_stylebox_override(&"pressed")
	tile.remove_theme_stylebox_override(&"disabled")
	tile.remove_theme_stylebox_override(&"hover")


func start_play() -> void:
	column_button.add_theme_color_override(&"font_color", Color.RED)
	column_button.add_theme_color_override(&"font_focus_color", Color.RED)
	column_button.add_theme_color_override(&"font_hover_color", Color.RED)
	column_button.add_theme_color_override(&"font_pressed_color", Color.RED)


func end_play() -> void:
	column_button.remove_theme_color_override(&"font_color")
	column_button.remove_theme_color_override(&"font_focus_color")
	column_button.remove_theme_color_override(&"font_hover_color")
	column_button.remove_theme_color_override(&"font_pressed_color")


func fade_in() -> void:
	anim_player.play(&"fade_in")


func add(p_column_no: int) -> void:
	column_no = p_column_no
	column_button.text = str(p_column_no + 1)


func remove() -> void:
	removed.emit()
	anim_player.play_backwards(&"fade_in")
	await anim_player.animation_finished
	queue_free()


func _on_tile_gui_input(event: InputEvent, button: Button) -> void:
	var instrument: int = button.get_meta("instrument")
	if event.is_action_pressed("right_click") or event.is_action_pressed("ui_menu"):
		var context_menu: ContextMenu = CONTEXT_MENU.instantiate()
		context_menu.top_level = true
		add_child(context_menu)
		
		context_menu.copy_button.disabled = !button.get_meta("sample_index")
		context_menu.paste_button.disabled = !Clipboard.has_tile()
		context_menu.clear_button.disabled = !button.get_meta("sample_index")
		
		context_menu.copy_button.pressed.connect(copy_tile.bind(instrument))
		context_menu.paste_button.pressed.connect(paste_tile)
		context_menu.clear_button.pressed.connect(
			func():
				BoomBox.song.set_tile(instrument, column_no, 0)
				clear_tile(instrument)
		)
		
		if event is InputEventMouseButton:
			context_menu.global_position = event.global_position
		else:
			context_menu.global_position = button.global_position + button.size / 2
		
		context_menu.popup()
		context_menu.copy_button.grab_focus()
	elif event.is_action_pressed("copy") and Utils.show_focus:
		copy_tile(instrument)
	elif event.is_action_pressed("paste") and Utils.show_focus:
		paste_tile()


func copy_tile(instrument: int) -> void:
	var sample_index: int = tiles[instrument].get_meta("sample_index")
	Clipboard.set_tile(instrument, sample_index)


func paste_tile() -> void:
	if Clipboard.has_tile():
		BoomBox.song.set_tile(Clipboard.get_tile().instrument, column_no, Clipboard.get_tile().sample)
		set_tile(Clipboard.get_tile().instrument, Clipboard.get_tile().sample)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		if tiles.is_empty():
			return
		for instrument in 4:
			var sample_index := 0
			if get_child(instrument + 1).has_meta(&"sample_index"):
				sample_index = get_child(instrument + 1).get_meta(&"sample_index")
			set_tile(instrument, sample_index)
