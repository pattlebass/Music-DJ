class_name CustomPopupMenu
extends CustomDialog

var items_container := VBoxContainer.new()
var items := 0

signal item_pressed(id: int)


func _ready() -> void:
	add_child(items_container)


func popup() -> void:
	show()
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, ^"modulate:a", 1, POPUP_TIME)\
			.from(0.2).set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(self, ^"scale", Vector2(1, 1), POPUP_TIME)\
			.from(Vector2(0.8, 0.8)).set_trans(Tween.TRANS_QUINT)


func add_item(text: String, id := items) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.theme_type_variation = "CustomPopupMenuButton"
	button.pressed.connect(
		func():
			item_pressed.emit(id)
			popup_hide()
	)
	items_container.add_child(button)
	
	items += 1
	
	return button
