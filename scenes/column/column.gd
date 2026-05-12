class_name Column
extends PanelContainer

@onready var column_button: Button = %ColumnButton
@onready var tiles: Array[Button] = [%Button1, %Button2, %Button3, %Button4]
@onready var drag_overlay: Panel = %DragOverlay # Hopefully temporary

var column_no: int
var is_dragged := false

signal tile_pressed(instrument: int)
signal column_button_pressed
signal drag_started
signal drag_ended
signal tile_drag_started
signal tile_drag_ended


func _ready() -> void:
	column_button.gui_input.connect(_on_column_button_gui_input)
	column_button.button_down.connect(_on_column_button_down)
	column_button.pressed.connect(column_button_pressed.emit)
	for i in tiles.size():
		tiles[i].gui_input.connect(_on_tile_gui_input.bind(i))
		tiles[i].button_down.connect(_on_tile_button_down.bind(i))
		tiles[i].pressed.connect(tile_pressed.emit.bind(i))


func set_tile(instrument: int, sample_index: int) -> void:
	var tile := tiles[instrument]
	
	if sample_index == 0:
		clear_tile(instrument)
		return
	
	tile.text = str(sample_index)
	
	var category := (sample_index - 1) / 8
	var style_box := get_theme_stylebox(Variables.CATEGORY_NAMES[category], &"Tile")
	tile.add_theme_stylebox_override(&"normal", style_box)
	tile.add_theme_stylebox_override(&"pressed", style_box)
	tile.add_theme_stylebox_override(&"disabled", style_box)
	tile.add_theme_stylebox_override(&"hover", style_box)


func clear_tile(instrument: int) -> void:
	var tile := tiles[instrument]
	
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


func fade_in() -> Signal:
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 1, 0.1).from(0)
	return tween.finished


func fade_out() -> Signal:
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0, 0.1)
	return tween.finished


func add(p_column_no: int) -> void:
	column_no = p_column_no
	column_button.text = str(p_column_no + 1)


func remove() -> void:
	await fade_out()
	queue_free()


func copy_tile(instrument: int) -> void:
	var sample: int = BoomBox.song.data[instrument][column_no]
	Clipboard.set_tile(instrument, sample)


func paste_tile() -> void:
	if Clipboard.has_tile():
		BoomBox.song.set_tile(Clipboard.get_tile().instrument, column_no, Clipboard.get_tile().sample)


func _start_drag() -> void:
	if BoomBox.is_playing:
		return
	
	is_dragged = true
	drag_started.emit()
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	scale = Vector2.ONE * 1.03
	
	Input.vibrate_handheld(Variables.VIBRATION_MS)
	drag_overlay.show()


func _end_drag() -> void:
	is_dragged = false
	drag_ended.emit()
	z_index = 0
	scale = Vector2.ONE
	drag_overlay.hide()


func _start_tile_drag(instrument: int) -> void:
	var sample: int = BoomBox.song.data[instrument][column_no]
	if sample == 0 or BoomBox.is_playing:
		return
	
	tile_drag_started.emit()
	
	Input.vibrate_handheld(Variables.VIBRATION_MS)
	
	var preview := Control.new()
	var duplicate_tile := tiles[instrument].duplicate()
	preview.add_child(duplicate_tile)
	duplicate_tile.position -= tiles[instrument].size / 2
	
	force_drag(SongTileData.new(instrument, sample), preview)


func _end_tile_drag() -> void:
	# HACK: Using force_drag() bugs ScrollContainer
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position *= Vector2(10**10, 10**10)
	Input.parse_input_event(event)
	
	tile_drag_ended.emit()


func _on_column_button_down() -> void:
	await get_tree().create_timer(Variables.HOLD_TIME_S).timeout
	
	if not column_button.button_pressed:
		return # Released before threshold
	
	# Prevent button from emitting pressed
	column_button.disabled = true
	column_button.disabled = false
	
	_start_drag()


func _on_column_button_gui_input(event: InputEvent) -> void:
	# Slight HACK
	if event is InputEventMouseButton and not event.is_pressed() and is_dragged:
		_end_drag()


# It should ideally be part of Button, but oh well
func _on_tile_button_down(instrument: int) -> void:
	await get_tree().create_timer(Variables.HOLD_TIME_S).timeout
	
	var button := tiles[instrument]
	if not button.button_pressed:
		return # Released before threshold
	
	# Prevent button from emitting pressed
	button.disabled = true
	button.disabled = false
	
	_start_tile_drag(instrument)


func _on_tile_gui_input(event: InputEvent, instrument: int) -> void:
	var tile_button := tiles[instrument]
	var sample: int = BoomBox.song.data[instrument][column_no]
	if event.is_action_pressed("right_click") or event.is_action_pressed("ui_menu"):
		var context_menu := ContextMenu.new()
		add_child(context_menu)
		
		context_menu.copy_button.disabled = sample == 0
		context_menu.paste_button.disabled = not Clipboard.has_tile()
		context_menu.clear_button.disabled = sample == 0
		
		context_menu.copy_button.pressed.connect(copy_tile.bind(instrument))
		context_menu.paste_button.pressed.connect(paste_tile)
		context_menu.clear_button.pressed.connect(BoomBox.song.set_tile.bind(instrument, column_no, 0))
		
		if event is InputEventMouseButton:
			context_menu.position = event.global_position
		else:
			context_menu.position = tile_button.global_position + tile_button.size / 2
		
		context_menu.popup()
		context_menu.copy_button.grab_focus()
	elif event.is_action_pressed("copy") and Utils.show_focus:
		copy_tile(instrument)
	elif event.is_action_pressed("paste") and Utils.show_focus:
		paste_tile()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is not SongTileData:
		return false
	
	var i = 0
	for tile_button in tiles:
		if tile_button.get_rect().has_point(at_position) and data.instrument == i:
			return true
		i += 1
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	_end_tile_drag()
	BoomBox.song.set_tile(data.instrument, column_no, data.sample)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		if tiles.is_empty():
			return
		for instrument in 4:
			var sample_index := 0
			set_tile(instrument, sample_index)
	elif what == NOTIFICATION_DRAG_END:
		# HUGE HACK
		if not get_viewport().gui_is_drag_successful() and column_no == 0:
			_end_tile_drag()
