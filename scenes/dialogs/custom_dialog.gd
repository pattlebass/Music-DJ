class_name CustomDialog
extends PopupPanel

const POPUP_TIME = 0.15

@export var container: Container
var dim_background := true
var animation_running := false

signal popup_hidden


func _ready() -> void:
	transient = true
	exclusive = true


func _on_about_to_popup() -> void:
	if animation_running:
		return
	if dim_background:
		Utils.exclusive_popup_visible.emit()
	play_popup_animation()


func _on_popup_hide() -> void:
	return
	if animation_running:
		return
	
	visible = true
	animation_running = true
	print("hide")
	if dim_background:
		Utils.exclusive_popup_hidden.emit()
	await play_hide_animation().finished
	popup_hidden.emit()
	visible = false
	animation_running = false
	print("done")


func popup2() -> void:
	popup()
	if dim_background:
		Utils.exclusive_popup_visible.emit()
	play_popup_animation()


func popup_hide2() -> void:
	var exclusive_before = exclusive
	exclusive = false
	if dim_background:
		Utils.exclusive_popup_hidden.emit()
	await play_hide_animation().finished
	popup_hidden.emit()
	exclusive = exclusive_before


func play_hide_animation() -> Tween:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(container, ^"modulate:a", 0.2, POPUP_TIME / 2)
	tween.tween_callback(hide)
	return tween


func play_popup_animation() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(container, ^"modulate:a", 1, POPUP_TIME)\
			.from(0.2).set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(self, ^"position:y", position.y, POPUP_TIME)\
			.from(position.y - 10).set_trans(Tween.TRANS_BACK)


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		theme_type_variation = "CustomDialog"
		about_to_popup.connect(_on_about_to_popup)
		popup_hide.connect(_on_popup_hide)
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("close req")

# HACK: Temporary
func _input(event: InputEvent) -> void:
	Utils._input(event)
