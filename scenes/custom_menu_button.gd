class_name CustomMenuButton
extends Button

@onready var popup_menu = CustomPopupMenu.new()


func _ready() -> void:
	add_child(popup_menu)
	popup_menu.container.pivot_offset_ratio = Vector2(1, 0)
	#popup_menu.top_level = true
	#popup_menu.hide()
	
	pressed.connect(_on_about_to_popup)


func _on_about_to_popup() -> void:
	popup_menu.popup2()
	if OS.has_feature("pc"):
		popup_menu.position.y = global_position.y + int(size.y)
	popup_menu.position.x = global_position.x + int(size.x - popup_menu.size.x)


func get_popup() -> CustomPopupMenu:
	return popup_menu
