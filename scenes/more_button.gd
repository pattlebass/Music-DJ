extends CustomMenuButton


@export var settings_dialog: CustomDialog
@export var about_dialog: AboutDialog
@export var tutorial_dialog: TutorialDialog

var undo_button: Button
var redo_button: Button


func _ready() -> void:
	super()
	
	Utils.theme_changed.connect(_on_theme_changed)
	popup_menu.item_pressed.connect(_on_item_pressed)
	build_menu()


func build_menu() -> void:
	undo_button = popup_menu.add_item("BTN_UNDO", false)
	redo_button = popup_menu.add_item("BTN_REDO", false)
	_on_history_changed()
	BoomBox.history_changed.connect(_on_history_changed)
	
	popup_menu.add_separator()
	
	popup_menu.add_item("BTN_SETTINGS")
	popup_menu.add_item("BTN_TUTORIAL")
	popup_menu.add_item("BTN_SEND_BUG")
	popup_menu.add_item("BTN_SEND_PROPOSAL")
	popup_menu.add_item("BTN_DONATE")
	popup_menu.add_item("BTN_ABOUT")


func _on_history_changed() -> void:
	undo_button.disabled = not BoomBox.can_undo()
	redo_button.disabled = not BoomBox.can_redo()


func _on_item_pressed(id: int) -> void:
	match id:
		0:
			BoomBox.undo()
		1:
			BoomBox.redo()
		2:
			settings_dialog.open()
		3:
			tutorial_dialog.open()
		4:
			var link := "https://github.com/pattlebass/Music-DJ/issues/new?labels=bug&template=bug_report.yaml&version={version}&device={device}"
			link = link.format(
				{
					"version": ProjectSettings.get_setting("application/config/version"),
					"device": OS.get_model_name().uri_encode() if OS.get_name() == "Android" else ""
				}
			)
			OS.shell_open(link)
		5:
			OS.shell_open("https://github.com/pattlebass/Music-DJ/issues/new?labels=enhancement&template=feature_request.yaml")
		6:
			OS.shell_open("https://ko-fi.com/fabians")
		7:
			about_dialog.open()


func _on_theme_changed(new_theme: String) -> void:
	icon = load("res://assets/themes/%s/more.svg" % new_theme)
