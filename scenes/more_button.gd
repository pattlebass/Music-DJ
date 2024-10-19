extends CustomMenuButton


func _ready() -> void:
	super()
	
	Utils.theme_changed.connect(_on_theme_changed)
	
	popup_menu.add_item("BTN_SETTINGS")
	popup_menu.add_item("BTN_TUTORIAL")
	popup_menu.add_item("BTN_SEND_BUG")
	popup_menu.add_item("BTN_SEND_PROPOSAL")
	popup_menu.add_item("BTN_ABOUT")


func _on_theme_changed(new_theme: String) -> void:
	icon = load("res://assets/themes/%s/more.svg" % new_theme)
