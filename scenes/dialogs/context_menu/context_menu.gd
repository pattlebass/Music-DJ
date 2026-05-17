class_name ContextMenu
extends CustomPopupMenu

@onready var copy_button: Button
@onready var cut_button: Button
@onready var paste_button: Button
@onready var clear_button: Button


func _ready() -> void:
	super()
	
	size = Vector2()
	theme_type_variation = &"ContextMenu"
	
	copy_button = add_item("BTN_COPY")
	cut_button = add_item("BTN_CUT")
	paste_button = add_item("BTN_PASTE")
	clear_button = add_item("BTN_CLEAR")
	
	copy_button.pressed.connect(close)
	cut_button.pressed.connect(close)
	paste_button.pressed.connect(close)
	clear_button.pressed.connect(close)


func _populate() -> void:
	copy_button.grab_focus()


func _cleanup() -> void:
	queue_free()
