class_name CustomPopupMenu
extends CustomDialog

var items_container := VBoxContainer.new()
var items := 0

signal item_pressed(id: int)


func _ready() -> void:
	super()
	
	dim_background = false
	build()


func play_popup_animation() -> Signal:
	if _display_tween:
		_display_tween.kill()
	
	_display_tween = create_tween()
	_display_tween.set_ease(Tween.EASE_OUT)
	_display_tween.parallel().tween_property(container, ^"modulate:a", 1, DISPLAY_DURATION)\
			.from(0.2).set_trans(Tween.TRANS_QUART)
	_display_tween.parallel().tween_property(container, ^"scale", Vector2(1, 1), DISPLAY_DURATION)\
			.from(Vector2(0.8, 0.8)).set_trans(Tween.TRANS_QUINT)
	
	return _display_tween.finished


func build() -> void:
	add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	
	var margin_container := MarginContainer.new()
	margin_container.add_theme_constant_override(&"margin_top", 10)
	margin_container.add_theme_constant_override(&"margin_right", 10)
	margin_container.add_theme_constant_override(&"margin_bottom", 10)
	margin_container.add_theme_constant_override(&"margin_left", 10)
	add_child(margin_container)
	
	container = PanelContainer.new()
	container.theme_type_variation = &"CustomDialog"
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(items_container)
	margin_container.add_child(container)


func add_item(text: String, auto_close := true, id := items) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.theme_type_variation = "CustomPopupMenuButton"
	button.pressed.connect(
		func():
			if auto_close:
				close()
			item_pressed.emit(id)
	)
	items_container.add_child(button)
	
	items += 1
	
	return button


func add_separator() -> void:
	var separator := HSeparator.new()
	items_container.add_child(separator)


func _populate() -> void:
	if items_container.get_children().size() != 0:
		items_container.get_child(0).grab_focus.call_deferred()
