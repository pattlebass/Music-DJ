class_name Column
extends PanelContainer

@onready var column_button: GestureButton = %ColumnButton
@onready var tiles: Array[GestureButton] = [%Button1, %Button2, %Button3, %Button4]
@onready var drag_overlay: Panel = %DragOverlay # Hopefully temporary

var column_no: int
var is_dragged := false

signal tile_pressed(instrument: int)
signal column_button_pressed
signal drag_started
signal drag_ended
signal tile_drag_started
signal tile_drag_ended
signal tile_swipe_started
signal tile_swipe_ended


func _ready() -> void:
	column_button.gui_input.connect(_on_column_button_gui_input)
	column_button.long_pressed.connect(_start_drag)
	column_button.pressed.connect(column_button_pressed.emit)
	for i in tiles.size():
		tiles[i].gui_input.connect(_on_tile_gui_input.bind(i))
		tiles[i].long_pressed.connect(_on_tile_long_pressed.bind(i))
		tiles[i].pressed.connect(tile_pressed.emit.bind(i))
		tiles[i].swiped.connect(_on_tile_swiped.bind(i))
		tiles[i].swipe_released.connect(_on_tile_swipe_released.bind(i))


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
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
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


func cut_tile(instrument: int) -> void:
	copy_tile(instrument)
	if not BoomBox.is_playing:
		BoomBox.song.set_tile(instrument, column_no, 0)


func paste_tile() -> void:
	if Clipboard.has_tile() and not BoomBox.is_playing:
		BoomBox.song.set_tile(Clipboard.get_tile().instrument, column_no, Clipboard.get_tile().sample)


func move_tile_relative(delta: int) -> void:
	if BoomBox.is_playing:
		return
	var new_column_no := clampi(column_no + delta, 0, BoomBox.song.get_length() - 1)
	BoomBox.song.move_column(column_no, new_column_no)


func show_context_menu(instrument: int, pos: Vector2) -> void:
	var sample: int = BoomBox.song.data[instrument][column_no]
	
	var context_menu := ContextMenu.new()
	add_child(context_menu)
	
	context_menu.copy_button.disabled = sample == 0
	context_menu.cut_button.disabled = sample == 0
	context_menu.paste_button.disabled = not Clipboard.has_tile()
	context_menu.clear_button.disabled = sample == 0
	
	context_menu.copy_button.pressed.connect(copy_tile.bind(instrument))
	context_menu.cut_button.pressed.connect(cut_tile.bind(instrument))
	context_menu.paste_button.pressed.connect(paste_tile)
	context_menu.clear_button.pressed.connect(BoomBox.song.set_tile.bind(instrument, column_no, 0))
	
	context_menu.position = pos
	
	context_menu.open()


func _start_drag() -> void:
	if BoomBox.is_playing or Utils.show_focus:
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
	if sample == 0 or BoomBox.is_playing or Utils.show_focus:
		return
	
	tile_drag_started.emit()
	
	Input.vibrate_handheld(Variables.VIBRATION_MS)
	
	var preview := Control.new()
	var duplicate_tile := tiles[instrument].duplicate()
	var stylebox := duplicate_tile.get_theme_stylebox(&"normal").duplicate() as StyleBoxFlat
	stylebox.shadow_color = Color("00000039")
	stylebox.shadow_size = 10
	duplicate_tile.add_theme_stylebox_override(&"normal", stylebox)
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


func _quick_edit_tile(instrument: int, delta: int) -> void:
	if BoomBox.is_playing:
		return
	
	Input.vibrate_handheld(Variables.VIBRATION_MS)
	
	var new_sample: int = BoomBox.song.data[instrument][column_no] + delta
	new_sample = clampi(new_sample, 0, 32)
	BoomBox.song.set_tile(instrument, column_no, new_sample)
	BoomBox.play_preview_sample(instrument, new_sample)


func _check_common_shortcuts(event: InputEvent) -> void:
	if event.is_action_pressed(&"column_move_left", true):
		move_tile_relative(-1)
		accept_event()
	elif event.is_action_pressed(&"column_move_right", true):
		move_tile_relative(1)
		accept_event()
	elif event.is_action_pressed(&"column_duplicate"):
		if not BoomBox.is_playing:
			BoomBox.song.duplicate_column(column_no)
		accept_event()


func _on_column_button_gui_input(event: InputEvent) -> void:
	# Slight HACK
	if event is InputEventMouseButton and not event.is_pressed() and is_dragged:
		_end_drag()
	
	if not Utils.show_focus:
		return
	
	if event.is_action_pressed(&"column_clear"):
		if not BoomBox.is_playing:
			BoomBox.song.clear_column(column_no)
		accept_event()
	elif event.is_action_pressed(&"column_remove"):
		if not BoomBox.is_playing and BoomBox.song.get_length() > Variables.MINIMUM_COLUMNS:
			BoomBox.song.remove_column(column_no)
		accept_event()
	else:
		_check_common_shortcuts(event)


func _on_tile_gui_input(event: InputEvent, instrument: int) -> void:
	if event.is_action_pressed(&"right_click") or event.is_action_pressed(&"ui_menu"):
		var tile_button := tiles[instrument]
		var pos := tile_button.global_position + tile_button.size / 2
		if event is InputEventMouseButton:
			pos = event.global_position
		show_context_menu(instrument, pos)
	
	elif event.is_action_pressed(&"tile_increment"):
		_quick_edit_tile(instrument, 1)
		accept_event()
	elif event.is_action_pressed(&"tile_decrement"):
		_quick_edit_tile(instrument, -1)
		accept_event()
	
	elif Utils.show_focus:
		if event.is_action_pressed(&"ui_copy"):
			copy_tile(instrument)
			accept_event()
		elif event.is_action_pressed(&"ui_cut"):
			cut_tile(instrument)
			accept_event()
		elif event.is_action_pressed(&"ui_paste"):
			paste_tile()
			accept_event()
		else:
			_check_common_shortcuts(event)


var _emulate_touch: bool = ProjectSettings.get_setting_with_override("input_devices/pointing/emulate_touch_from_mouse")
func _on_tile_long_pressed(instrument: int) -> void:
	if Input.is_action_pressed(&"left_click") and not _emulate_touch:
		return
	_start_tile_drag(instrument)


func _on_tile_swiped(direction: int, instrument: int) -> void:
	tile_swipe_started.emit()
	tiles[instrument].set_meta(&"is_swiping", true)
	_quick_edit_tile(instrument, direction)


func _on_tile_swipe_released(instrument: int) -> void:
	if tiles[instrument].get_meta(&"is_swiping", false):
		tile_swipe_ended.emit()


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
			var sample_index: int = BoomBox.song.data[instrument][column_no]
			set_tile(instrument, sample_index)
	elif what == NOTIFICATION_DRAG_END:
		# HUGE HACK
		if not get_viewport().gui_is_drag_successful() and column_no == 0:
			_end_tile_drag()
