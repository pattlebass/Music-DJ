extends CustomDialog


var all_panels := [
	{
		"key": "TUTORIAL_HOLD_TILE",
		"video":"res://assets/tutorial/hold-tile.webm",
		"condition": OS.has_feature("mobile") or OS.has_feature("web"),
	},
	{"key": "TUTORIAL_COLUMN_BTN", "video":"res://assets/tutorial/column-btn.webm"},
	{
		"key": "TUTORIAL_DRAG_FILE",
		"video":"res://assets/tutorial/drag-file.webm",
		"condition": OS.has_feature("pc") or OS.has_feature("web"),
	},
	{
		"key": "TUTORIAL_RIGHT_CLICK",
		"video": "res://assets/tutorial/right-click-tile.webm",
		"condition": OS.has_feature("pc") or OS.has_feature("web"),
	},
	{
		"key": "TUTORIAL_FOLLOW",
		"image":"res://assets/tutorial/follow.jpg",
		"placeholders": ["[color=#4ecca3][url=https://twitter.com/pattlebass_dev]@pattlebass_dev[/url][/color]"],
	},
]

var panels := []

var current := 0

onready var video_player = $"%VideoPlayer"
onready var texture_rect = $"%TextureRect"
onready var animation = $AnimationPlayer2
onready var previous_button = $"%PreviousButton"
onready var next_button = $"%NextButton"
onready var body: RichTextLabel = $"%RichTextLabel"


func _ready() -> void:
	if Variables.current_tutorial_version > Variables.options["last_seen_tutorial"]:
		call_deferred("popup_centered")
	
	if OS.has_feature("standalone"):
		for panel in all_panels:
			if panel.has("condition") and not panel.condition:
				continue
			panels.append(panel)
	else:
		panels = all_panels


func about_to_show() -> void:
	current = 0
	change_panel(0, 0)
	.about_to_show()


func _on_NextButton_pressed() -> void:
	current += 1
	change_panel(current, current - 1)


func _on_PreviousButton_pressed() -> void:
	if current == 0:
		return
	current -= 1
	change_panel(current, current + 1)


func change_panel(_panel_no: int, _previous_panel_no: int) -> void:
	if _panel_no >= panels.size():
		if Variables.current_tutorial_version > Variables.options["last_seen_tutorial"]:
			Variables.options["last_seen_tutorial"] = Variables.current_tutorial_version
			Variables.save_options()
		hide()
		return
	
	previous_button.disabled = _panel_no == 0
	
	# Note for future me:
	# You can think backwards = opposite
	# eg: fade_in_right_to_left backwards is fade_out_left_to_right
	# I know it's confusing but it's easier to change
	if _panel_no >= _previous_panel_no:
		animation.play("fade_out_right_to_left")
	else:
		animation.play_backwards("fade_in_right_to_left")
	
	yield(get_tree().create_timer(0.1), "timeout")
	animation.stop(false)
	
	var panel = panels[_panel_no]
	
	
	if panel.has("video"):
		texture_rect.hide()
		video_player.show()
		video_player.stream = load(panel["video"])
		video_player.play()
	else:
		video_player.hide()
		texture_rect.show()
		texture_rect.texture = load(panel.image)
	
	if panel.has("placeholders"):
		body.bbcode_text = tr(panel.key) % panel.placeholders
	else:
		body.bbcode_text = tr(panel.key)
	$VBoxContainer/PageLabel.text = str(_panel_no + 1)+"/"+str(panels.size())
	
	if _panel_no >= _previous_panel_no:
		animation.play("fade_in_right_to_left")
	else:
		animation.play_backwards("fade_out_right_to_left")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_on_PreviousButton_pressed()
	elif event.is_action_pressed("ui_right"):
		_on_NextButton_pressed()


func _on_VideoPlayer_finished() -> void:
	video_player.play()


func _on_RichTextLabel_meta_clicked(meta: String) -> void:
	OS.shell_open(meta)


# Swipe logic ------------------------

var swipe_start: Vector2

func _on_VBoxMedia_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.get_position()
		else:
			_calculate_swipe(event.get_position())


func _calculate_swipe(swipe_end):
	if swipe_start == null: 
		return
	var swipe = swipe_end - swipe_start
	if abs(swipe.x) > Variables.MINIMUM_DRAG:
		if swipe.x > 0:
			_on_PreviousButton_pressed()
		else:
			_on_NextButton_pressed()
