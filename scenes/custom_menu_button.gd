class_name CustomMenuButton
extends Button

@onready var popup_menu = CustomPopupMenu.new()


func _ready() -> void:
	add_child(popup_menu)
	popup_menu.container.pivot_offset_ratio = Vector2(1, 0)


func _pressed() -> void:
	popup_menu.open()
	popup_menu.position.y = global_position.y
	popup_menu.position.x = global_position.x + int(size.x - popup_menu.size.x)
	if OS.has_feature("pc"):
		popup_menu.position.y += int(size.y)


func get_popup() -> CustomPopupMenu:
	return popup_menu
