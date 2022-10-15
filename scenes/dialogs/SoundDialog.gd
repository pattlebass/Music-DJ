extends CustomDialog

var instrument
var pressed_button_index = 0

var column
var column_no

onready var button_container = $VBoxContainer/ScrollContainer/VBoxContainer
onready var audio_player = $AudioStreamPlayer
onready var ok_button = $VBoxContainer/HBoxContainer/OkButton
onready var cancel_button = $VBoxContainer/HBoxContainer/CancelButton
var button_group = ButtonGroup.new()

func _ready() -> void:
	if !OS.is_ok_left_and_cancel_right():
		$VBoxContainer/HBoxContainer.move_child(
			cancel_button,
			0
		)
		$VBoxContainer/HBoxContainer.move_child(
			ok_button,
			2
		)
	
	# Create list
	var text = ["Groove 1", "Groove 2", "Salsa 1", "Salsa 2", "Reggae 1", "Reggae 2", "Techno 1", "Techno 2"]
	var category = [
		"SAMPLE_CAT_INTRODUCTION",
		"SAMPLE_CAT_VERSE",
		"SAMPLE_CAT_CHORUS",
		"SAMPLE_CAT_SOLO"
	]
	var button_index = -1
	var buttons = []
	
	for i in 4:
		var separator = HSeparator.new()
		separator.set("custom_constants/separation", 10)
		separator.modulate = Color(1, 1, 1, 0.01)
		button_container.add_child(separator)
		
		var label = Label.new()
		label.text = category[i]
		label.theme_type_variation = "LabelSubtitle"
		button_container.add_child(label)
		
		var separator2 = HSeparator.new()
		button_container.add_child(separator2)
		
		# Icon
		var image = load("res://assets/mask.png")
		var texture = ImageTexture.new()
		var color = get_color(
			Variables.category_names[i],
			"Tile"
		)
		image.lock()
		for y in 32:
			for x in 32:
				var current_pixel = image.get_pixel(x, y)
				image.set_pixel(x, y, color * current_pixel)
		image.unlock()
		texture.create_from_image(image)
		
		# Buttons
		for g in 8:
			button_index += 1
			var button_in_list = Button.new()
			button_in_list.text = " "+text[g]
			button_in_list.theme_type_variation = "ListItem"
			button_in_list.icon = texture
			button_in_list.align = Button.ALIGN_LEFT
			button_in_list.mouse_filter = Button.MOUSE_FILTER_PASS
			button_in_list.connect("pressed", self, "on_Button_selected", [button_index])
			button_in_list.connect("focus_entered", self, "on_Button_focused", [button_index])
			button_in_list.name = str(button_index)
			button_in_list.focus_mode = Control.FOCUS_ALL
			button_in_list.toggle_mode = true
			button_in_list.group = button_group
			buttons.append(button_in_list)
			button_container.add_child(button_in_list)
	
	# Keyboard focus
	for i in buttons.size():
		if i != 0:
			buttons[i].focus_neighbour_top = buttons[i - 1].get_path()
		else:
			buttons[i].focus_neighbour_top = buttons[-1].get_path()
		if i + 1 != buttons.size():
			buttons[i].focus_neighbour_bottom = buttons[i + 1].get_path()
		else:
			buttons[i].focus_neighbour_bottom = buttons[0].get_path()
		
		buttons[i].focus_neighbour_right = ok_button.get_path()
		buttons[i].focus_neighbour_left = cancel_button.get_path()
	
	BoomBox.connect("play_started", audio_player, "stop")


func about_to_show():
	column_no = column.column_no
	
	# Set title
	var instrument_name = tr(Variables.instrument_names[instrument])
	$VBoxContainer/Label.text = tr("DIALOG_SOUND_TITLE") % [instrument_name, column_no + 1]
	
	# Set button states
	var clear_button = get_node("VBoxContainer/HBoxContainer/ClearButton")
	
	if BoomBox.song[instrument][column_no]:
		var selected_button = button_container.get_node(
			str(BoomBox.song[instrument][column_no] - 1)
		)
		selected_button.pressed = true
		clear_button.disabled = false
		ok_button.disabled = false
		
		yield(get_tree(), "idle_frame")
		selected_button.grab_focus()
	else:
		clear_button.disabled = true
		ok_button.disabled = true
	
	.about_to_show()


func on_Button_selected(index):
	if index == pressed_button_index:
		button_container.get_node(str(pressed_button_index)).pressed = true
	
	ok_button.disabled = false
	pressed_button_index = index
	
	if Variables.show_focus:
		_on_OkButton_pressed()
	else:
		audio_player.stream = BoomBox.sounds[instrument][index + 1]
		audio_player.play()


func on_Button_focused(sample_index):
	if not Variables.show_focus:
		return
	audio_player.stream = BoomBox.sounds[instrument][sample_index + 1]
	audio_player.play()


func _on_OkButton_pressed():
	if BoomBox.song[instrument][column_no] - 1 == pressed_button_index:
		hide()
		return
	
	BoomBox.set_tile(instrument, column_no, pressed_button_index + 1)
	column.set_tile(
		instrument,
		pressed_button_index+1
	)
	
	column_no = 0
	
	hide()


func _on_ClearButton_pressed():
	column.clear_tile(instrument)
	BoomBox.set_tile(instrument, column.column_no, 0)

	hide()


func _on_CancelButton_pressed():
	hide()


func popup_hide():
	$VBoxContainer/ScrollContainer.scroll_vertical = 0
	
	if button_group.get_pressed_button():
		button_group.get_pressed_button().pressed = false
	
	.popup_hide()
