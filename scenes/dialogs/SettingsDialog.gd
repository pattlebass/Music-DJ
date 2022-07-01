extends CustomDialog

onready var lang_container = $"%LangContainer"

func _ready() -> void:
	get_node("VBoxContainer/ScrollContainer/SettingsContainer/ThemeContainer/"+ \
		Variables.options.theme.capitalize()).pressed = true
	$VBoxContainer/ScrollContainer/SettingsContainer/LabelVersion.text = Variables.VERSION
	
	if Variables.options.check_updates != null:
		$"%CheckUpdates".set_pressed_no_signal(Variables.options.check_updates)
	
	var lang_btn_group = ButtonGroup.new()
	
	var lang_auto_btn = lang_container.get_node("Auto")
	lang_auto_btn.text = tr("SETTING_LANG_AUTO") % TranslationServer.get_locale()
	lang_auto_btn.group = lang_btn_group
	lang_auto_btn.connect("pressed", self, "on_lang_chosen", [""])
	
	if Variables.options.language == "":
		lang_auto_btn.set_pressed_no_signal(true)
	
	for i in TranslationServer.get_loaded_locales():
		var check_box = CheckBox.new()
		check_box.text = i
		check_box.group = lang_btn_group
		check_box.mouse_filter = Control.MOUSE_FILTER_PASS
		check_box.connect("pressed", self, "on_lang_chosen", [i])
		
		if Variables.options.language == i:
			check_box.set_pressed_no_signal(true)
		
		lang_container.add_child(check_box)


func _on_CloseButton_pressed():
	hide()


func about_to_show():
	$VBoxContainer/ScrollContainer.scroll_vertical = 0
	.about_to_show()


func _on_theme_chosen(button_pressed, theme_name):
	if button_pressed and visible:
		Variables.change_theme(theme_name)
		Variables.options.theme = theme_name
		Variables.save_options()


func on_lang_chosen(lang):
	Variables.options.language = lang
	Variables.save_options()
	
	if lang:
		TranslationServer.set_locale(lang)
	else:
		TranslationServer.set_locale(OS.get_locale_language())


func _on_CheckUpdates_toggled(button_pressed: bool) -> void:
	Variables.options.check_updates = button_pressed
	Variables.save_options()
