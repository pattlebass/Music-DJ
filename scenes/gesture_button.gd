class_name GestureButton
extends Button

const LONG_PRESS_TIME = 0.5 # seconds
@onready var SWIPE_THRESHOLD = ProjectSettings.get_setting("gui/common/default_scroll_deadzone")

signal long_pressed
signal swiped(direction: int)
signal swipe_released # Needed only because accept_event() doesn't work for touch + scroll


func _ready() -> void:
	button_down.connect(_on_button_down)


func _gui_input(event: InputEvent) -> void:
	_process_swipe(event)


var _press_id := 0
# Why isn't there a virtual method for this?
func _on_button_down() -> void:
	_press_id += 1
	if await _check_long_press():
		cancel_pressed_signal()
		long_pressed.emit()


var _swipe_start_pos := Vector2()
var _has_swiped := false
func _process_swipe(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start_pos = event.position
		else:
			_has_swiped = false
			swipe_released.emit()
	
	if event is InputEventScreenDrag and button_pressed:
		var horizontal_distance: float = event.position.x - _swipe_start_pos.x
		var vertical_distance: float = event.position.y - _swipe_start_pos.y
		var vertical_direction := int(signf(vertical_distance))
		
		if absf(vertical_distance) < SWIPE_THRESHOLD or abs(horizontal_distance) > SWIPE_THRESHOLD:
			return
		
		if not _has_swiped:
			_has_swiped = true
			swiped.emit(vertical_direction)
			cancel_pressed_signal()
		accept_event() # Probably does nothing


func _check_long_press() -> bool:
	var current_press := _press_id
	
	if _has_swiped:
		return false
	
	await get_tree().create_timer(LONG_PRESS_TIME).timeout
	
	if not button_pressed or current_press != _press_id:
		return false
	
	return true


func cancel_pressed_signal() -> void:
	disabled = true
	disabled = false
