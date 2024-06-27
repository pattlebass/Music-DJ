class_name LoadDialog
extends CustomDialog

const LOAD_ITEM = preload("res://scenes/dialogs/load_dialog/load_item/load_item.tscn")

@onready var project_container: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var new_project_button: Button = %NewProjectButton
@onready var open_folder_button: Button = %OpenFolderButton
@onready var file_picker_button: Button = %FilePickerButton
@onready var no_projects_label: Label = %NoProjectsLabel

var selected_file := ""

signal project_selected(path: String)
signal new_project


func _ready() -> void:
	Utils.theme_changed.connect(_on_theme_changed)
	Utils.file_picked.connect(_on_file_picked)
	
	open_folder_button.visible = OS.get_name() != "Web"
	file_picker_button.visible = Utils.has_file_picker()


func load_song(path: String) -> void:
	project_selected.emit(path)
	hide()


func popup() -> void:
	if not Utils.has_storage_perms():
		return
	
	selected_file = ""
	
	var projects := Utils.list_files_in_directory("user://saves/Projects/", ["mdj"])
	
	for i in projects:
		create_item(i)
	
	no_projects_label.visible = projects.is_empty()
	
	super()


func create_item(project_path: String) -> void:
	var item: LoadItem = LOAD_ITEM.instantiate()
	project_container.add_child(item)
	
	item.expanded.connect(scroll_container.ensure_control_visible.bind(item))
	item.button.text = project_path
	item.open_button.pressed.connect(load_song.bind(Variables.projects_dir.path_join(project_path)))
	item.delete_button.pressed.connect(_on_delete_pressed.bind(item, project_path))
	item.download_button.pressed.connect(_on_download_pressed.bind(project_path))
	item.share_button.pressed.connect(_on_share_pressed.bind(project_path))
	item.link_button.pressed.connect(_on_link_pressed.bind(project_path))
	item.download_button.visible = OS.get_name() == "Web" or OS.get_name() == "Android"
	item.share_button.visible = Utils.can_share()


func popup_hide() -> void:
	super()
	for i in project_container.get_children():
		if i is LoadItem:
			i.queue_free()


func _on_file_picked(path: String, _mime_type: String) -> void:
	if not path.get_extension() in ["mdj", "mdjt", "mid"]:
		DirAccess.remove_absolute(path)
		Utils.toast("%s is not a valid project" % path.get_file())
		return
	
	var new_path := "user://saves/Projects".path_join(path.get_file())
	
	if FileAccess.file_exists(new_path):
		# Match file name with bracket numbering
		# From stackoverflow.com/questions/7846389
		var regex := RegEx.new()
		regex.compile("^(.*?)(?:\\((\\d+)\\))?\\.(.+)$")
		var result := regex.search(path.get_file())
		
		var groups := {
				"file_name": result.strings[1],
				"number": int(result.strings[2]) + 1 if result.strings[2] else 1,
				"extension": result.strings[3]
			}
		var new_file_name := "{file_name} ({number}).{extension}".format(groups)
		
		while FileAccess.file_exists(new_path):
			groups.number += 1
			new_file_name = "{file_name} ({number}).{extension}".format(groups)
			new_path = "user://saves/Projects".path_join(new_file_name)
	
	if path.get_extension() == "mid":
		new_path += ".mdj"
		
		var file := FileAccess.open(new_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(MidiFile.to_mdj(path)))
		file.close()
		
		DirAccess.remove_absolute(path)
	else:
		if DirAccess.copy_absolute(path, new_path) == OK:
			DirAccess.remove_absolute(path)
	
	load_song(new_path)


func _on_delete_pressed(item: LoadItem, file_name: String) -> void:
	#modulate = Color.TRANSPARENT
	
	var body = tr("DIALOG_CONFIRMATION_BODY_DELETE") % "[color=#4ecca3]%s[/color]" % Utils.truncate(file_name, 22)
	
	if await Utils.confirm_popup("DIALOG_CONFIRMATION_TITLE_DELETE", body):
		var path := Variables.projects_dir.path_join("%s" % file_name)
		
		if OS.move_to_trash(ProjectSettings.globalize_path(path)) != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		
		# HACK: Until https://github.com/godotengine/godot/issues/63995 is fixed
		if OS.get_name() == "Web":
			Options.save(0)
		
		item.queue_free()
	
	#modulate = Color.WHITE


func _on_share_pressed(file_name: String) -> void:
	Utils.share_file(
		"user://saves/Projects/".path_join(file_name), "", "", "", "application/json"
	)


func _on_link_pressed(file_name: String) -> void:
	var file := FileAccess.open("user://saves/Projects/".path_join(file_name), FileAccess.READ)
	var project_string := file.get_as_text()
	file.close()
	
	var url := "https://pattlebass.itch.io/musicdj?song=" + project_string.uri_encode()
	DisplayServer.clipboard_set(url)
	Utils.toast("Copied link to clipboard", Toast.Length.LENGTH_SHORT)


func _on_download_pressed(file_name: String) -> void:
	Utils.download_file(
		Variables.saves_dir.path_join("Projects/%s" % file_name),
		file_name
	)


func _on_new_project_button_pressed() -> void:
	new_project.emit()


func _on_cancel_button_pressed() -> void:
	hide()


func _on_open_button_pressed() -> void:
	if OS.get_name() == "Android":
		OS.alert(ProjectSettings.globalize_path(Variables.saves_dir), "Folder location")
	else:
		OS.shell_open(ProjectSettings.globalize_path(Variables.saves_dir))


func _on_pick_file_button_pressed() -> void:
	Utils.open_file_picker("*/*")


func _on_theme_changed(new_theme: String) -> void:
	file_picker_button.icon = load("res://assets/themes/%s/open_file.svg" % new_theme)
	open_folder_button.icon = load("res://assets/themes/%s/open_folder.svg" % new_theme)
	new_project_button.icon = load("res://assets/themes/%s/add.svg" % new_theme)
