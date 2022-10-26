extends CustomDialog

var selected_file = ""

onready var project_container: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
onready var new_project: Button = $"%NewProjectButton"
onready var open_folder: Button = $"%OpenFolderButton"

var dir := Directory.new()

var android_picker
var share_service

signal project_selected(path)
signal new_project


func _ready() -> void:
	Variables.connect("theme_changed", self, "on_theme_changed")
	if !OS.is_ok_left_and_cancel_right():
		$VBoxContainer/HBoxContainer.move_child(
			$VBoxContainer/HBoxContainer/CancelButton,
			0
		)
	
	if Engine.has_singleton("GodotFilePicker"):
		android_picker = Engine.get_singleton("GodotFilePicker")
		android_picker.connect("file_picked", self, "_on_file_picked")
	
	# DEPRECATED v1.0-stable: Move projects on Android to internal app storage
	if OS.get_name() == "Android":
		var old_dir := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).plus_file("MusicDJ/Projects")
		if dir.file_exists(old_dir):
			for project in Variables.list_files_in_directory(old_dir, ["mdj", "mdjt"]):
				var old_project := old_dir.plus_file(project)
				var new_project := "user://saves/Projects/".plus_file(project)
				if dir.copy(old_project, new_project) == OK:
					print("Copied project (%s) from old location" % project)
					dir.remove(old_project)


func load_song(path):
	emit_signal("project_selected", path)
	hide()


func on_theme_changed(new_theme):
	if android_picker:
		open_folder.icon = load("res://assets/themes/%s/open_file.svg" % new_theme)
	else:
		open_folder.icon = load("res://assets/themes/%s/open_folder.svg" % new_theme)
	new_project.icon = load("res://assets/themes/%s/add.svg" % new_theme)


func about_to_show():
	if !Variables.has_storage_perms():
		hide()
	
	if OS.get_name() == "HTML5":
		open_folder.hide()
	
	selected_file = ""
	
	var projects = Variables.list_files_in_directory(
		"user://saves/Projects/",
		["mdj", "mdjt"]
	)
	
	var theme_path = "res://assets/themes/%s/" % Variables.options.theme
	
	if projects.empty():
		$"%NoProjectsLabel".show()
	else:
		$"%NoProjectsLabel".hide()
	
	var btn_group = ButtonGroup.new()
	
	for i in projects.size():
		var project_path: String = projects[i]
		
		var item = preload("res://scenes/dialogs/load_dialog/LoadItem.tscn").instance()
		project_container.add_child(item)
		item.connect("expanded", scroll_container, "ensure_control_visible", [item])
		item.button.text = Variables.truncate(project_path, 25)
		item.open_button.connect("pressed", self, "load_song", [Variables.projects_dir.plus_file(project_path)])
		item.delete_button.connect("pressed", self, "_on_Delete_pressed", [item, project_path])
		item.download_button.connect("pressed", self, "_on_Download_pressed", [project_path])
		item.share_button.connect("pressed", self, "_on_Share_pressed", [project_path])
		connect("popup_hide", item, "queue_free")
		item.download_button.visible = OS.get_name() == "HTML5" or OS.get_name() == "Android"
		item.share_button.visible = share_service != null
	
	$VBoxContainer.rect_size = rect_size
	.about_to_show()


func _on_CancelButton_pressed():
	hide()


func _on_OpenButton_pressed():
	if OS.get_name() == "Android":
		if android_picker:
			android_picker.openFilePicker("*/*")
		else:
			OS.alert(ProjectSettings.globalize_path(Variables.saves_dir), "Folder location")
	else:
		OS.shell_open(ProjectSettings.globalize_path(Variables.saves_dir))


func _on_file_picked(path: String, _mime_type: String) -> void:
	if not path.get_extension() in ["mdj", "mdjt", "mid"]:
		dir.remove(path)
		print("%s is not a valid project" % path.get_file())
		return
	
	var new_path := "user://saves/Projects".plus_file(path.get_file())
	
	if path.get_extension() == "mid":
		new_path += ".mdj"
	
	if dir.file_exists(new_path):
		# Match file name with bracket numbering
		# From stackoverflow.com/questions/7846389
		var regex = RegEx.new()
		regex.compile("^(.*?)(?:\\((\\d+)\\))?\\.(.+)$")
		var result = regex.search(path.get_file())
		
		var groups = {
				"file_name": result.strings[1],
				"number": int(result.strings[2]) + 1 if result.strings[2] else 1,
				"extension": result.strings[3]
			}
		var new_file_name = "{file_name} ({number}).{extension}".format(groups)
		
		while dir.file_exists(new_path):
			groups.number += 1
			new_file_name = "{file_name} ({number}).{extension}".format(groups)
			new_path = "user://saves/Projects".plus_file(new_file_name)
	
	if path.get_extension() == "mid":
		var file = File.new()
		file.open(new_path, File.WRITE)
		file.store_string(to_json(MidiFile.to_mdj(path)))
		file.close()
		
		dir.remove(path)
	else:
		if dir.copy(path, new_path) == OK:
			dir.remove(path)
	
	load_song(new_path)


func _on_Delete_pressed(item, file_name):
	modulate = Color.transparent
	
	var body = tr("DIALOG_CONFIRMATION_BODY_DELETE") % "[color=#4ecca3]%s[/color]" % Variables.truncate(file_name, 22)
	
	if yield(Variables.confirm_popup("DIALOG_CONFIRMATION_TITLE_DELETE", body), "completed"):
		var path := Variables.projects_dir.plus_file("%s" % file_name)
		
		if OS.move_to_trash(ProjectSettings.globalize_path(path)) != OK:
			dir.remove(ProjectSettings.globalize_path(path))
		
		# HACK: Until https://github.com/godotengine/godot/issues/63995 is fixed
		if OS.get_name() == "HTML5":
			Variables.save_options(0)
		
		item.queue_free()
	
	modulate = Color.white


func _on_Share_pressed(file_name) -> void:
	Variables.share_file(
		"user://saves/Projects/".plus_file(file_name), "", "", "", "application/json"
	)


func _on_Download_pressed(file_name):
	Variables.download_file(
		Variables.saves_dir.plus_file("Projects/%s" % file_name),
		file_name
	)


func _on_NewProjectButton_pressed() -> void:
	emit_signal("new_project")
