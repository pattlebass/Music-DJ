extends Node

const CUSTOM_CONFIRM_DIALOG = preload("res://scenes/dialogs/custom_confirm_dialog/custom_confirm_dialog.tscn")
const TOAST = preload("res://scenes/toast/toast.tscn")

var share_plugin := Share.new()

signal virtual_keyboard_visible
signal virtual_keyboard_hidden
signal theme_changed(new_theme: String)
signal dim_dialog_shown
signal dim_dialog_hidden
signal input_block_dialog_shown
signal input_block_dialog_hidden


func _ready() -> void:
	get_tree().node_added.connect(_node_added)
	get_tree().node_removed.connect(_node_removed)
	
	if Variables.main:
		traverse(Variables.main)
	
	if can_share():
		add_child(share_plugin)
	
	clean_temp()


func change_theme(new_theme: String) -> void:
	theme_changed.emit(new_theme)


func download_file(file_path: String, file_name: String):
	var file := FileAccess.open(file_path, FileAccess.READ)
	var file_data_raw := file.get_buffer(file.get_length())
	file.close()
	
	var mime_type: String
	if file_name.ends_with(".wav"):
		mime_type = "audio/wav"
	elif file_name.ends_with(".mdj"):
		mime_type = "application/octet-stream"
	
	JavaScriptBridge.download_buffer(file_data_raw, file_name, mime_type)


func can_share() -> bool:
	return Engine.has_singleton(share_plugin.PLUGIN_SINGLETON_NAME)


func share_file(path: String, title: String, subject: String, text: String, mime_type: String) -> void:
	clean_temp()
	
	if not can_share():
		return
	
	var real_path := path
	if not (path.begins_with("res://") or path.begins_with("user://")):
		real_path = "user://_temp/".path_join(path.get_file())
		DirAccess.copy_absolute(path, real_path)
	share_plugin.share_file(ProjectSettings.globalize_path(real_path), mime_type, title, subject, text)
	
	# TODO: Clean copied file here


func clean_temp() -> void:
	var dir := DirAccess.open("user://_temp")
	if dir:
		for file in dir.get_files():
			dir.remove(file)


func toast(text: String, duration: Toast.Length = Toast.Length.LENGTH_LONG) -> void:
	var toast_node: Toast = Toast.new()
	toast_node.text = text
	toast_node.duration = duration
	
	Variables.main.add_child(toast_node)
	toast_node.open()


func confirm_popup(title: String, body: String, parent: Node = Variables.main) -> bool:
	var dialog: CustomConfirmDialog = CUSTOM_CONFIRM_DIALOG.instantiate()
	
	parent.add_child(dialog)
	dialog.alert(title, body)
	
	return await dialog.chose


func truncate(string: String, max_length: int) -> String:
	if string.length() > max_length:
		return string.left(max_length - 3) + "..."
	return string


func list_files_in_directory(path: String, extensions := [""]) -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	
	while true:
		var file: String = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.get_extension() in extensions:
				files.append(file)
	
	dir.list_dir_end()
	
	return files


func has_storage_perms() -> bool:
	if OS.get_granted_permissions().is_empty() && OS.get_name() == "Android":
		return OS.request_permissions()
	return true


var _dim_dialog_count := 0
var _block_dialog_count := 0
func notify_dialog_visibility(shown: bool, dim_background: bool) -> void:
	if shown:
		_block_dialog_count += 1
		if dim_background:
			_dim_dialog_count += 1
	else:
		_block_dialog_count -= 1
		if dim_background:
			_dim_dialog_count -= 1
	
	if _dim_dialog_count == 1:
		dim_dialog_shown.emit()
	elif _dim_dialog_count == 0:
		dim_dialog_hidden.emit()
	
	if _block_dialog_count == 1:
		input_block_dialog_shown.emit()
	elif _block_dialog_count == 0:
		input_block_dialog_hidden.emit()


# Virtual keyboard signals
var virtual_kb_up := false
var _has_virtual_keyboard := DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD)
func _process(_delta):
	if not _has_virtual_keyboard:
		return
	if DisplayServer.virtual_keyboard_get_height() == 0:
		if virtual_kb_up:
			virtual_kb_up = false
			virtual_keyboard_hidden.emit()
	else:
		if not virtual_kb_up:
			virtual_kb_up = true
			virtual_keyboard_visible.emit()


func signal_disconnect_all(s: Signal) -> void:
	for i in s.get_connections():
		s.disconnect(i.callable)


# Keyboard focus
var buttons: Array[Button] = []
var show_focus := false

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_focus_next")
		or event.is_action_pressed("ui_focus_prev")
		or event.is_action_pressed("ui_left")
		or event.is_action_pressed("ui_right")
		or event.is_action_pressed("ui_up")
		or event.is_action_pressed("ui_down")):
		
		show_focus = true
		for i in buttons:
			i.set("theme_override_styles/focus", null)
		
		if not Variables.main.get_viewport().gui_get_focus_owner():
			Variables.main.play_button.grab_focus.call_deferred()
		
	elif event.is_action_pressed("left_click"):
		show_focus = false
		for i in buttons:
			i.set("theme_override_styles/focus", StyleBoxEmpty.new())


func _node_added(node: Node) -> void:
	if node is Button:
		if not show_focus and node.focus_mode == Control.FOCUS_ALL:
			node.set("theme_override_styles/focus", StyleBoxEmpty.new())
		buttons.append(node)


func _node_removed(node: Node) -> void:
	if node is Button and node in buttons:
		buttons.erase(node)


func traverse(child: Node) -> void:
	for i in child.get_children():
		traverse(i)
	_node_added(child)
