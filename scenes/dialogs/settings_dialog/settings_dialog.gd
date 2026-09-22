extends CustomDialog

@onready var lang_container: VBoxContainer = %LangContainer
@onready var theme_container: VBoxContainer = %ThemeContainer
@onready var label_version: Label = %LabelVersion
@onready var check_updates: CheckBox = %CheckUpdates
@onready var settings_container: VBoxContainer = %SettingsContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var lang_auto: CheckBox = %LangAuto
@onready var sf_container_anchor: Control = %SFContainerAnchor
var sf_container: Control

# HACK: for https://github.com/godotengine/godot-proposals/issues/2378
var locale_names := {
	"en": "English",
	"ro": "Română",
	"id": "Bahasa Indonesia",
	"pl": "Polski",
	"ru": "Русский"
}

# TODO: Refactor


func _ready() -> void:
	super()
	build()


func build() -> void:
	# Theme
	%ThemeContainer/Dark.focus_entered.connect(func(): scroll_container.scroll_vertical = 0)
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
	
	# Version label focus
	@warning_ignore("narrowing_conversion")
	check_updates.focus_entered.connect(func(): scroll_container.scroll_vertical = scroll_container.size.y)
	
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


func _populate() -> void:
	%ThemeContainer/Dark.grab_focus.call_deferred()
	scroll_container.scroll_vertical = 0
	lang_auto.text = tr("SETTING_LANG_AUTO") % locale_names[OS.get_locale_language()]
	
	_refresh_sf_list()


func _refresh_sf_list() -> void:
	if sf_container != null:
		sf_container.queue_free()
	sf_container = build_soundfonts()
	sf_container_anchor.add_child(sf_container)


func build_soundfonts() -> Control:
	var label = Label.new()
	label.text = "SETTING_SF"
	label.theme_type_variation = &"LabelSubtitle"
	
	var default_btn := CheckBox.new()
	default_btn.text = "SETTING_DEFAULT"
	default_btn.mouse_filter = Control.MOUSE_FILTER_PASS
	default_btn.button_group = ButtonGroup.new()
	default_btn.set_pressed_no_signal(Options.custom_soundfont_path.is_empty())
	default_btn.toggled.connect(
		func(button_pressed: bool):
			if button_pressed:
				Options.custom_soundfont_path = ""
	)
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(label)
	vbox.add_child(default_btn)
	
	var theme_path = "res://assets/themes/%s/" % Options.theme
	for custom_path in Options.get_custom_soundfont_list():
		var checkbox := CheckBox.new()
		checkbox.text = Utils.truncate(custom_path.get_file().get_basename(), 28) # I hate this...
		checkbox.button_group = default_btn.button_group
		checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		checkbox.set_pressed_no_signal(Options.custom_soundfont_path == custom_path)
		checkbox.toggled.connect(
			func(button_pressed: bool):
				if button_pressed:
					Options.custom_soundfont_path = custom_path
		)
		
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var delete_btn := Button.new()
		delete_btn.icon = load(theme_path.path_join("delete.svg"))
		delete_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		delete_btn.theme_type_variation = &"ListItem"
		delete_btn.pressed.connect(
			func():
				var err := DirAccess.remove_absolute(custom_path)
				if Options.custom_soundfont_path == custom_path:
					Options.custom_soundfont_path = ""
				_refresh_sf_list()
				if err:
					Utils.toast("Error: %s (%s)" % [error_string(err), err])
		)
		
		var item := HBoxContainer.new()
		item.add_child(checkbox)
		#item.add_child(spacer)
		item.add_child(delete_btn)
		
		vbox.add_child(item)
	
	var import_dialog := FileDialog.new()
	import_dialog.use_native_dialog = true
	import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	import_dialog.filters = ["*.sf2;SoundFont files;audio/soundfont"]
	import_dialog.files_selected.connect(
		func(files: PackedStringArray):
			for file in files:
				var err := Options.import_soundfont(file)
				if err:
					Utils.toast("Error for '%s': %s (%s)" % [file.get_file(), error_string(err), err])
			_refresh_sf_list()
	)
	vbox.add_child(import_dialog)
	
	var import_button := Button.new()
	import_button.text = "SETTING_SF_BTN_IMPORT"
	import_button.icon = load(theme_path.path_join("add.svg"))
	import_button.mouse_filter = Control.MOUSE_FILTER_PASS
	import_button.theme_type_variation = &"ListItem"
	import_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	import_button.pressed.connect(import_dialog.popup_file_dialog)
	
	vbox.add_child(import_button)
	
	return vbox


func build_separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.add_theme_constant_override(&"separation", 10)
	return separator


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
	close()
