class_name CustomMenuButton
extends Button

@onready var popup_menu = CustomPopupMenu.new()


func _ready() -> void:
	add_child(popup_menu)
	popup_menu.top_level = true
	popup_menu.hide()
	
	pressed.connect(_on_about_to_popup)


func _on_about_to_popup() -> void:
	if OS.has_feature("pc"):
		popup_menu.global_position.y = global_position.y + int(size.y)
	popup_menu.global_position.x = global_position.x + int(size.x - popup_menu.size.x)
	popup_menu.pivot_offset.x = popup_menu.size.x
	
	popup_menu.popup()


func get_popup() -> CustomPopupMenu:
	return popup_menu
