class_name ContextMenu
extends CustomPopupMenu

@onready var copy_button: Button
@onready var paste_button: Button
@onready var clear_button: Button


func _ready() -> void:
	super()
	
	size = Vector2()
	theme_type_variation = &"ContextMenu"
	
	copy_button = add_item("BTN_COPY")
	paste_button = add_item("BTN_PASTE")
	clear_button = add_item("BTN_CLEAR")
	
	copy_button.pressed.connect(popup_hide)
	paste_button.pressed.connect(popup_hide)
	clear_button.pressed.connect(popup_hide)


func popup_hide() -> void:
	super()
	queue_free()
