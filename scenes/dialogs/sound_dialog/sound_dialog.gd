class_name SoundDialog
extends CustomAcceptDialog

@onready var sample_btn_container: VBoxContainer = %SampleContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var title_label: Label = %TitleLabel
@onready var ok_button: Button = %OkButton
@onready var clear_button: Button = %ClearButton
@onready var cancel_button: Button = %CancelButton

var instrument: int
var pressed_button_index := 0
var column: Column

var button_group := ButtonGroup.new()


func _ready() -> void:
	super()
	
	# Create list
	var category_titles := [
		"SAMPLE_CAT_INTRODUCTION",
		"SAMPLE_CAT_VERSE",
		"SAMPLE_CAT_CHORUS",
		"SAMPLE_CAT_SOLO"
	]
	var button_index := -1
	
	for category in 4:
		sample_btn_container.add_spacer(false).custom_minimum_size.y = 10
		
		var category_label := Label.new()
		category_label.text = category_titles[category]
		category_label.theme_type_variation = &"LabelSubtitle"
		sample_btn_container.add_child(category_label)
		
		sample_btn_container.add_child(HSeparator.new())
		
		# Buttons
		var category_icon := get_category_icon(category)
		for sample_type in 8:
			button_index += 1
			create_sample_button(sample_type, button_index, category_icon)
	
	# Keyboard focus
	var buttons := button_group.get_buttons()
	buttons[0].focus_neighbor_top = buttons[-1].get_path()
	buttons[-1].focus_neighbor_bottom = buttons[0].get_path()
	
	for i in range(1, buttons.size() - 1):
		buttons[i].focus_neighbor_top = buttons[i - 1].get_path()
		buttons[i].focus_neighbor_bottom = buttons[i + 1].get_path()
	
	BoomBox.play_started.connect(audio_player.stop)
	BoomBox.bpm_changed.connect(_on_BPM_changed)


func popup() -> void:
	# Set title
	var instrument_name := tr(Variables.INSTRUMENT_NAMES[instrument])
	title_label.text = tr(&"DIALOG_SOUND_TITLE") % [instrument_name, column.column_no + 1]
	
	scroll_container.scroll_vertical = 0
	
	# Set button states
	
	if button_group.get_pressed_button():
		button_group.get_pressed_button().button_pressed = false
	
	var selected_sample: int = BoomBox.song.data[instrument][column.column_no]
	if selected_sample:
		var selected_button: Button = button_group.get_buttons()[selected_sample - 1]
		selected_button.button_pressed = true
		clear_button.disabled = false
		ok_button.disabled = false
		
		selected_button.grab_focus.call_deferred()
	else:
		clear_button.disabled = true
		ok_button.disabled = true
		button_group.get_buttons()[0].grab_focus.call_deferred()
	
	super()


func create_sample_button(sample_type: int, index: int, texture: Texture2D) -> void:
	var names: Array[String] = ["Groove 1", "Groove 2", "Salsa 1", "Salsa 2", "Reggae 1", "Reggae 2", "Techno 1", "Techno 2"]
	
	var button_in_list := Button.new()
	button_in_list.text = " " + names[sample_type]
	button_in_list.theme_type_variation = "ListItem"
	button_in_list.icon = texture
	button_in_list.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button_in_list.mouse_filter = Button.MOUSE_FILTER_PASS
	button_in_list.pressed.connect(_on_sample_selected.bind(index, button_in_list))
	button_in_list.focus_entered.connect(_on_sample_focused.bind(index))
	button_in_list.focus_mode = Control.FOCUS_ALL
	button_in_list.toggle_mode = true
	button_in_list.button_group = button_group
	sample_btn_container.add_child(button_in_list)


func get_category_icon(category: int) -> Texture2D:
	var icon: Image = load("res://assets/mask.png")
	var color := get_theme_color(Variables.CATEGORY_NAMES[category], &"Tile")
	
	for y in icon.get_height():
		for x in icon.get_width():
			icon.set_pixel(x, y, color * icon.get_pixel(x, y))
	
	return ImageTexture.create_from_image(icon)


func _on_sample_selected(index: int, button: Button) -> void:
	if index == pressed_button_index:
		button.button_pressed = true
	
	ok_button.disabled = false
	pressed_button_index = index
	
	if Utils.show_focus:
		_on_ok_button_pressed()
	else:
		audio_player.stream = BoomBox.sounds[instrument][index + 1]
		audio_player.play()


func _on_sample_focused(sample_index) -> void:
	if not Utils.show_focus:
		return
	audio_player.stream = BoomBox.sounds[instrument][sample_index + 1]
	audio_player.play()


func _on_ok_button_pressed() -> void:
	if BoomBox.song.data[instrument][column.column_no] - 1 == pressed_button_index:
		hide()
		return
	
	BoomBox.song.set_tile(instrument, column.column_no, pressed_button_index + 1)
	column.set_tile(
		instrument,
		pressed_button_index + 1
	)
	
	hide()


func _on_clear_button_pressed() -> void:
	column.clear_tile(instrument)
	BoomBox.song.set_tile(instrument, column.column_no, 0)
	popup_hide()


func _on_cancel_button_pressed() -> void:
	popup_hide()


func _on_BPM_changed() -> void:
	audio_player.pitch_scale = BoomBox.song.bpm / 80.0
