class_name ContextMenu
extends CustomDialog


@onready var copy_button: Button = %CopyButton
@onready var paste_button: Button = %PasteButton
@onready var clear_button: Button = %ClearButton


func _ready() -> void:
	copy_button.pressed.connect(popup_hide)
	paste_button.pressed.connect(popup_hide)
	clear_button.pressed.connect(popup_hide)


func popup_hide() -> void:
	super()
	queue_free()
