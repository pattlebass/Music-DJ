extends VBoxContainer

var column_no: int

onready var anim_player = $AnimationPlayer
onready var column_button = $ColumnButton
onready var tiles := [$Button1, $Button2, $Button3, $Button4]

func _ready() -> void:
	for i in tiles.size():
		tiles[i].set_meta("instrument", i)
		tiles[i].set_meta("sample_index", 0)
		tiles[i].connect("gui_input", self, "on_tile_gui_input", [tiles[i]])


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


func clear() -> void:
	for i in 4:
		clear_tile(i)


func clear_tile(instrument: int) -> void:
	var tile = get_node("Button" + str(instrument + 1))
	
	tile.set_meta("sample_index", 0)
	
	tile.text = ""
	tile.set("custom_styles/normal", null)
	tile.set("custom_styles/pressed", null)
	tile.set("custom_styles/disabled", null)
	tile.set("custom_styles/hover", null)


func on_play_started() -> void:
	column_button.set("custom_colors/font_color", Color.red)
	column_button.set("custom_colors/font_color_focus", Color.red)
	column_button.set("custom_colors/font_color_hover", Color.red)
	column_button.set("custom_colors/font_color_pressed", Color.red)


func on_play_ended() -> void:
	column_button.set("custom_colors/font_color", null)
	column_button.set("custom_colors/font_color_focus", null)
	column_button.set("custom_colors/font_color_hover", null)
	column_button.set("custom_colors/font_color_pressed", null)


func fade_in() -> void:
	anim_player.play("fade_in")

func add(_column_no: int) -> void:
	column_no = _column_no
	column_button.text = str(_column_no + 1)


func remove() -> void:
	anim_player.play_backwards("fade_in")
	yield(anim_player, "animation_finished")
	queue_free()


func on_tile_gui_input(event: InputEvent, button: Button) -> void:
	var instrument = button.get_meta("instrument")
	var sample_index = button.get_meta("sample_index")
	if event.is_action_pressed("right_click") or event.is_action_pressed("ui_menu"):
		var menu = PopupMenu.new()
		menu.add_item("Copy")
		menu.add_item("Paste")
		menu.add_item("BTN_CLEAR")
		
		if not Variables.clipboard:
			menu.set_item_disabled(1, true)
		if not button.get_meta("sample_index"):
			menu.set_item_disabled(0, true)
			menu.set_item_disabled(2, true)
		
		if event.get("global_position"):
			menu.rect_position = event.global_position
		else:
			menu.rect_position = button.rect_global_position + button.rect_size / 2
		menu.theme_type_variation = "ContextMenu"
		menu.script = preload("res://scenes/dialogs/custom_dialog/DialogScript.gd")
		menu.dim = false
		menu.rect_pivot_offset = Vector2.ZERO
		menu.pivot_manual = true
		
		menu.connect("id_pressed", self, "context_menu_pressed", [instrument, sample_index])
		menu.connect("visibility_changed", self, "context_menu_visibility_changed", [menu, instrument])
		menu.connect("popup_hide", menu, "queue_free")
		
		add_child(menu)
		menu.popup()
	elif event.is_action_pressed("copy") and Variables.show_focus:
		if sample_index:
			Variables.clipboard = {"instrument": instrument, "sample": sample_index}
	elif event.is_action_pressed("paste") and Variables.show_focus:
		if Variables.clipboard:
			set_tile(Variables.clipboard.instrument, Variables.clipboard.sample)


func context_menu_pressed(id: int, instrument: int, sample_index: int) -> void:
	match id:
		0: # Copy
			Variables.clipboard = {"instrument": instrument, "sample": sample_index}
		1: # Paste
			if Variables.clipboard:
				Variables.main.set_tile(Variables.clipboard.instrument, column_no, Variables.clipboard.sample)
				set_tile(Variables.clipboard.instrument, Variables.clipboard.sample)
		2: # Clear
			Variables.main.set_tile(instrument, column_no, 0)
			clear_tile(instrument)


# Work-around until https://github.com/godotengine/godot-proposals/issues/2663
func context_menu_visibility_changed(menu: Control, instrument: int) -> void:
	if not Variables.show_focus:
		return
	
	if menu.visible:
		menu.grab_focus()
		var e := InputEventAction.new()
		e.action = "ui_down"
		e.pressed = true
		Input.parse_input_event(e)
		accept_event()
	else:
		tiles[instrument].grab_focus()


func _notification(what) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		for instrument in 4:
			var sample_index = 0
			if get_child(instrument + 1).has_meta("sample_index"):
				sample_index = get_child(instrument + 1).get_meta("sample_index")
			set_tile(instrument, sample_index)
