extends CustomDialog

@onready var lang_container: VBoxContainer = %LangContainer
@onready var theme_container: VBoxContainer = %ThemeContainer
@onready var label_version: Label = %LabelVersion
@onready var check_updates: CheckBox = %CheckUpdates
@onready var settings_container: VBoxContainer = %SettingsContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var lang_auto: CheckBox = %LangAuto

# HACK: for https://github.com/godotengine/godot-proposals/issues/2378
var locale_names := {
	"en": "English",
	"ro": "Română",
	"id": "Bahasa Indonesia",
	"pl": "Polski",
}


func _ready() -> void:
	# Theme
	for i in theme_container.get_children():
		if i.has_meta("theme_name"):
			i.toggled.connect(_on_theme_chosen.bind(i.get_meta("theme_name")))
			i.set_pressed_no_signal(i.get_meta("theme_name") == Options.theme)
	
	label_version.text = ProjectSettings.get_setting("application/config/version")
	check_updates.set_pressed_no_signal(Options.check_updates)
	
	# Languages
	var lang_btn_group := ButtonGroup.new()
	
	lang_auto.button_group = lang_btn_group
	lang_auto.pressed.connect(_on_lang_chosen.bind(""))
	lang_auto.set_pressed(Options.language == "")
	
	for i in TranslationServer.get_loaded_locales():
		var check_box = CheckBox.new()
		check_box.text = locale_names[i]
		check_box.button_group = lang_btn_group
		check_box.mouse_filter = Control.MOUSE_FILTER_PASS
		check_box.pressed.connect(_on_lang_chosen.bind(i))
		check_box.set_pressed(Options.language == i)
		
		if lang_container.get_child_count() > 0:
			check_box.focus_neighbor_top = lang_container.get_child(-1).get_path()
		
		lang_container.add_child(check_box)
	
	if OS.get_name() == "Web":
		# Hide Check for update
		check_updates.hide()
		
		# Warning for Web
		var label_web_disable := Label.new()
		label_web_disable.text = "SETTING_WEB_WARNING"
		label_web_disable.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label_web_disable.theme_type_variation = "LabelSubtitle"
		settings_container.add_child(label_web_disable)
		settings_container.move_child(label_web_disable, -2)


func popup() -> void:
	$"%ThemeContainer/Dark".grab_focus.call_deferred()
	scroll_container.scroll_vertical = 0
	lang_auto.text = tr("SETTING_LANG_AUTO") % locale_names[OS.get_locale_language()]
	super()


func _on_theme_chosen(button_pressed: bool, theme_name: String) -> void:
	if button_pressed:
		Options.theme = theme_name
		Options.save()


func _on_lang_chosen(lang: String) -> void:
	Options.language = lang
	Options.save()


func _on_check_updates_toggled(button_pressed: bool) -> void:
	Options.check_updates = button_pressed
	Options.save()


func _on_close_button_pressed() -> void:
	hide()
