class_name TutorialDialog
extends CustomDialog


var all_panels := [
	{
		"key": "TUTORIAL_HOLD_TILE",
		"video":"res://assets/tutorial/hold_tile.ogv",
		"condition": OS.has_feature("mobile") or OS.has_feature("web"),
	},
	{"key": "TUTORIAL_COLUMN_BTN", "video":"res://assets/tutorial/column_btn.ogv"},
	{
		"key": "TUTORIAL_DRAG_FILE",
		"video":"res://assets/tutorial/drag_file.ogv",
		"condition": OS.has_feature("pc") or OS.has_feature("web"),
	},
	{
		"key": "TUTORIAL_RIGHT_CLICK",
		"video": "res://assets/tutorial/right_click_tile.ogv",
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
var current_tutorial_version := 1

@onready var video_player: VideoStreamPlayer = %VideoStreamPlayer
@onready var texture_rect: TextureRect = %TextureRect
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var previous_button: Button = %PreviousButton
@onready var next_button: Button = %NextButton
@onready var body: RichTextLabel = %RichTextLabel
@onready var page_label: Label = %PageLabel


func _ready() -> void:
	if current_tutorial_version > Options.last_seen_tutorial:
		popup_centered.call_deferred()
	
	if OS.has_feature("standalone"):
		for panel in all_panels:
			if panel.has("condition") and not panel.condition:
				continue
			panels.append(panel)
	else:
		panels = all_panels


func popup() -> void:
	current = 0
	change_panel(0, 0)
	super()


func previous_panel() -> void:
	if current == 0:
		return
	current -= 1
	change_panel(current, current + 1)


func next_panel() -> void:
	current += 1
	change_panel(current, current - 1)


func change_panel(_panel_no: int, _previous_panel_no: int) -> void:
	if _panel_no >= panels.size():
		if current_tutorial_version > Options.last_seen_tutorial:
			Options.last_seen_tutorial = current_tutorial_version
			Options.save()
		hide()
		return
	
	previous_button.disabled = _panel_no == 0
	
	# Note: You can think of "backwards" as "opposite"
	# e.g.: `fade_in_next` backwards is `fade_out_previous`
	if _panel_no >= _previous_panel_no:
		animation.play(&"fade_out_next")
	else:
		animation.play_backwards(&"fade_in_next")
	
	await animation.animation_finished
	
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
		body.text = tr(panel.key) % panel.placeholders
	else:
		body.text = tr(panel.key)
	page_label.text = "%s/%s" % [_panel_no + 1, panels.size()]
	
	if _panel_no >= _previous_panel_no:
		animation.play(&"fade_in_next")
	else:
		animation.play_backwards(&"fade_out_next")


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		previous_panel()
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		next_panel()


func _on_VideoPlayer_finished() -> void:
	video_player.play()


func _on_rich_text_label_meta_clicked(meta: String) -> void:
	OS.shell_open(meta)


# Swipe logic ------------------------

var swipe_start: Vector2

func _on_v_box_media_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.get_position()
		else:
			_calculate_swipe(event.get_position())


func _calculate_swipe(swipe_end: Vector2):
	if swipe_start == null: 
		return
	var swipe := swipe_end - swipe_start
	if absf(swipe.x) > Variables.MINIMUM_DRAG:
		if swipe.x > 0:
			previous_panel()
		else:
			next_panel()
