class_name CustomDialog
extends PanelContainer

var dim := true

const POPUP_TIME = 0.15


# Hide on click outside of the popup
func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		popup_hide()
		get_viewport().set_input_as_handled()
	
	if not &"global_position" in event:
		return
	
	if not get_global_rect().has_point(event.global_position):
		if event is InputEventMouseButton \
		and event.is_pressed() \
		and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
			popup_hide()
		get_viewport().set_input_as_handled()


func popup() -> void:
	show()
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, ^"modulate:a", 1, POPUP_TIME)\
			.from(0.2).set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(self, ^"position:y", position.y, POPUP_TIME)\
			.from(position.y - 10).set_trans(Tween.TRANS_BACK)


func popup_centered(bound: Rect2 = get_viewport_rect()) -> void:
	global_position = bound.position + (bound.size - size) / 2
	popup()


func popup_hide() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, ^"modulate:a", 0.2, POPUP_TIME / 2)
	tween.tween_callback(hide)


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		theme_type_variation = "CustomDialog"
