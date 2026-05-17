class_name CustomDialog
extends PopupPanel

const DISPLAY_DURATION = 0.15
const HIDE_DURATION = 0.05

@export var container: Container
@export var dim_background := true
@export var hide_on_unfocus := true

var dialog_hidden := true

signal popup_hidden


func _ready() -> void:
	transient = true
	transient_to_focused = true
	popup_window = false
	focus_exited.connect(
		func():
			if hide_on_unfocus:
				close()
	)
	
	# HACK: https://github.com/godotengine/godot/issues/99715 AHHHHHH
	ready.connect(
		func():
			var material = CanvasItemMaterial.new()
			material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
			container.material = material
			for child in get_children():
				if &"material" in child:
					child.material = material
	)


func open() -> void:
	dialog_hidden = false
	gui_disable_input = false
	_populate()
	popup()
	Utils.notify_dialog_visibility(true, dim_background)
	await play_popup_animation()


func close() -> void:
	_cleanup()
	
	if dialog_hidden:
		return
	
	dialog_hidden = true
	gui_disable_input = true
	Utils.notify_dialog_visibility(false, dim_background)
	
	play_hide_animation().connect(popup_hidden.emit)


func _populate() -> void:
	pass


func _cleanup() -> void:
	pass


var _display_tween: Tween
func play_hide_animation() -> Signal:
	if _display_tween:
		_display_tween.finished.emit()
		_display_tween.kill()
	
	_display_tween = create_tween()
	_display_tween.set_ease(Tween.EASE_OUT)
	_display_tween.parallel().tween_property(container, ^"modulate:a", 0.2, HIDE_DURATION)
	_display_tween.tween_callback(hide)
	
	return _display_tween.finished


func play_popup_animation() -> Signal:
	if _display_tween:
		_display_tween.finished.emit()
		_display_tween.kill()
	
	_display_tween = create_tween()
	_display_tween.set_ease(Tween.EASE_OUT)
	_display_tween.parallel().tween_property(container, ^"modulate:a", 1, DISPLAY_DURATION)\
			.from(0.2).set_trans(Tween.TRANS_QUART)
	_display_tween.parallel().tween_property(self, ^"position:y", position.y, DISPLAY_DURATION)\
			.from(position.y - 10).set_trans(Tween.TRANS_BACK)
	
	return _display_tween.finished


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		theme_type_variation = "CustomDialog"


# HACK: Temporary
func _input(event: InputEvent) -> void:
	Utils._input(event)
