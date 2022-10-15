extends CustomDialog

var title := "Title"
var entered_name := ""
var last_name := ""
var type_of_save := "project"
var effect = AudioServer.get_bus_effect(0, 0)
var is_cancelled = false

onready var line_edit = $VBoxContainer/VBoxContainer/HBoxContainer/LineEdit
onready var ok_button = $VBoxContainer/HBoxContainer/OkButton
onready var label_title = $VBoxContainer/VBoxContainer/Label
onready var label_error = $VBoxContainer/VBoxContainer/LabelError


func _ready() -> void:
	if !OS.is_ok_left_and_cancel_right():
		$VBoxContainer/HBoxContainer.move_child(
			$VBoxContainer/HBoxContainer/CancelButton,
			0
		)
	Variables.connect("virtual_keyboard_visible", self, "_on_virtual_kb_visible")
	Variables.connect("virtual_keyboard_hidden", self, "_on_virtual_kb_hidden")


func save():
	entered_name = entered_name.strip_edges()
	if type_of_save == "project":
		# Project save
		var path = Variables.projects_dir.plus_file("%s.mdj" % entered_name)
		var file = File.new()
		var err = file.open(path, File.WRITE)
		file.store_string(to_json(BoomBox.song))
		file.close()
		
		# ProgressDialog
		main.get_node("ProgressDialog").path = path
		main.get_node("ProgressDialog").after_saving = "close"
		main.get_node("ProgressDialog").type_of_save = type_of_save
		main.get_node("ProgressDialog").progress_bar.max_value = 0.2
		main.get_node("ProgressDialog").popup_centered()
		
		if err:
			main.get_node("ProgressDialog").error(err)
		
		last_name = entered_name
	else:
		is_cancelled = false
		last_name = entered_name
		main.get_node("SoundDialog/AudioStreamPlayer").stop()
		
		# ProgressDialog
		var path = Variables.exports_dir.plus_file("%s.wav" % entered_name)
		
		main.get_node("ProgressDialog").path = path
		main.get_node("ProgressDialog").after_saving = "stay"
		main.get_node("ProgressDialog").type_of_save = type_of_save
		main.get_node("ProgressDialog").progress_bar.max_value = 3*(BoomBox.used_columns.max()+1) + 0.5
		main.get_node("ProgressDialog").popup_centered()
		
		# Export
		effect.set_recording_active(true)
		BoomBox.play_song()
		yield(BoomBox, "play_ended")
		effect.set_recording_active(false)
		
		# Saving
		var recording = effect.get_recording()
		if not recording or is_cancelled:
			print("Canceled recording.")
			return
		
		# HACK: Save directly to path when bug is fixed
		# https://github.com/godotengine/godot/issues/63949
		var dir = Directory.new()
		dir.make_dir("user://_temp/")
		var err = recording.save_to_wav("user://_temp/".plus_file(path.get_file()))
		
		if err:
			main.get_node("ProgressDialog").error(err)
			print("Recording failed. Code: %s" % err)
		else:
			if OS.get_name() == "Android":
				var download_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS).plus_file("MusicDJ")
				dir.make_dir(download_dir)
				
				print("Android export-----------")
				print(recording.save_to_wav(download_dir.plus_file("Song.wav")))
				print(dir.file_exists(download_dir.plus_file("Song.wav")))
				print(dir.rename(download_dir.plus_file("Song.wav"), path))
				print("Android export end-----------")
				
				if not dir.file_exists(path):
					main.get_node("ProgressDialog").error(1234)
					print("Exporting didn't work.")
			else:
				var err2 = dir.rename("user://_temp/".plus_file(path.get_file()), path)
				if err2:
					main.get_node("ProgressDialog").error(4321)
					print("Non Android export failed: %s" % err2)
			dir.remove("user://_temp/".plus_file(path.get_file()))


func _on_OkButton_pressed() -> void:
	hide()
	save()


func _on_CancelButton_pressed() -> void:
	hide()


func about_to_show() -> void:
	if !Variables.has_storage_perms():
		hide()
	
	label_title.text = title
	
	# Changing the text this way doesn't emit the signal
	line_edit.text = last_name if last_name else get_default_name()
	_on_LineEdit_text_changed(line_edit.text)
	
	line_edit.caret_position = line_edit.text.length()
	
	.about_to_show()


func popup_hide() -> void:
	.popup_hide()
	var dir = Directory.new()
	if OS.get_name() == "HTML5":
		for path in Variables.list_files_in_directory(Variables.exports_dir, ["wav"]):
			print("Removing %s. Code: %s" % [
				"user://_temp".plus_file(path),
				dir.remove("user://_temp".plus_file(path))
			])
		# HACK: Until https://github.com/godotengine/godot/issues/63995 is fixed
		Variables.save_options(0)


func _on_virtual_kb_visible() -> void:
	# Hide title above viewport to make more space
	rect_position.y = -label_title.rect_size.y 


func _on_virtual_kb_hidden() -> void:
	yield(get_tree().create_timer(0.2), "timeout")
	rect_position.y = (get_viewport().get_visible_rect().size.y - rect_size.y) / 2


func _on_LineEdit_text_changed(new_text):
	if not new_text.strip_edges().is_valid_filename() or new_text[0] == ".":
		ok_button.disabled = true
		
		if new_text:
			label_error.text = "Invalid file name: / \\ ? * \" | % < > :"
		
		return
	
	entered_name = new_text
	ok_button.disabled = false
	label_error.text = ""


func get_default_name() -> String:
	return "Song " + str(randi() % 1000)


func _on_LineEdit_text_entered(_new_text: String) -> void:
	# Kinda hacky, but this is not an AcceptDialog so it doesn't have
	# the register_text_enter() method
	if ok_button.disabled:
		return
	yield(get_tree().create_timer(0.1), "timeout")
	ok_button.emit_signal("pressed")
