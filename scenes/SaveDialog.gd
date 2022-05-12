extends "res://scenes/DialogScript.gd"

var title := "Title"
var entered_name := ""
var last_name := ""
var type_of_save := "project"
var effect = AudioServer.get_bus_effect(0, 0)
var is_cancelled = false

onready var line_edit = $VBoxContainer/VBoxContainer/HBoxContainer/LineEdit

var once := false

#var regex = RegEx.new()


func _ready():
	pass
	
	#regex.compile('[\\/:"*?<>|]+')


func save():
	if type_of_save == "project":
		# Project save
		var path = Variables.user_dir.plus_file("Projects/%s.mdj" % entered_name.strip_edges())
		var file = File.new()
		file.open(path, File.WRITE)
		file.store_string(to_json(main.song))
		file.close()
		
		# ProgressDialog
		main.get_node("ProgressDialog").path_text = path
		main.get_node("ProgressDialog").after_saving = "close"
		main.get_node("ProgressDialog").progress_bar.max_value = 0.2
		main.get_node("ProgressDialog").popup_centered()
		
		last_name = entered_name
	else:
		is_cancelled = false
		main.get_node("SoundDialog/AudioStreamPlayer").stop()
		
		# ProgressDialog
		var path = Variables.user_dir.plus_file("Exports/%s.wav" % entered_name.strip_edges())
		main.get_node("ProgressDialog").path_text = path
		main.get_node("ProgressDialog").after_saving = "stay"
		main.get_node("ProgressDialog").progress_bar.max_value = 3*(main.used_columns.max()+1) + 0.5
		main.get_node("ProgressDialog").popup_centered()
		
		# Export
		effect.set_recording_active(true)
		yield(main.play_song(), "completed")
		effect.set_recording_active(false)
		
		# Saving
		var recording = effect.get_recording()
		if recording and not is_cancelled:
			recording.save_to_wav(path)
			print("Save successful!")
		else:
			print("Save failed!")
		
		is_cancelled = false


func _on_OkButton_pressed():
	hide()
	save()

func _on_CancelButton_pressed():
	hide()


func about_to_show(dim := true):
	if !Variables.has_storage_perms():
		hide()
	
	$VBoxContainer/VBoxContainer/Label.text = title
	
	# Changing the text this way doesn't emit the signal
	line_edit.text = last_name if last_name else get_default_name()
	_on_LineEdit_text_changed(line_edit.text)
	
	line_edit.caret_position = line_edit.text.length()
	
	.about_to_show()


func validate_filename(text: String) -> String:
	var invalid_chars = ["<", ">", ":", "\"", "/", ")", "\\", "|", "?", "*", "#"]
	
	for i in invalid_chars:
		text = text.replace(i, "")
	
	return text


func _on_LineEdit_text_changed(new_text):
	new_text = validate_filename(new_text)
	
	var line_edit = $VBoxContainer/VBoxContainer/HBoxContainer/LineEdit
	line_edit.text = new_text
	line_edit.caret_position = line_edit.text.length()
	
	var ok_button = $VBoxContainer/HBoxContainer/OkButton
	if new_text == "" or new_text[0] == ".":
		ok_button.disabled = true
	else:
		entered_name = new_text
		ok_button.disabled = false


func _process(delta):
	if OS.get_virtual_keyboard_height() == 0:
		rect_position.y = get_viewport().get_visible_rect().size.y / 2 - rect_size.y / 2
	else:
		rect_position.y = get_viewport().get_visible_rect().size.y/2 - rect_size.y / 2 - OS.get_virtual_keyboard_height()/4


func get_default_name() -> String:
	return "Song " + str(randi() % 1000)


func download_file(_file_path, _file_name):
	var file = File.new()
	file.open(_file_path, File.READ)
	var file_data_raw = file.get_buffer(file.get_len())
	var file_data_64 = Marshalls.raw_to_base64(file_data_raw)
	file.close()
	
	var mime_type
	if _file_name.ends_with(".wav"):
		mime_type = "audio/wav"
	elif _file_name.ends_with(".mdj"):
		mime_type = "text/plain"

	JavaScript.eval("""
	var a = document.createElement('a');
	a.download = '%s';
	a.href = 'data:%s;base64,%s';
	a.target = '_blank'
	a.click();
	""" % [_file_name, mime_type, file_data_64])


func _on_HTMLButton_pressed():
	yield(get_tree(), "idle_frame")
	var entered_text = JavaScript.eval("prompt('Save as...', '');")
	line_edit.text = entered_text
	_on_LineEdit_text_changed(entered_text)


func _on_LineEdit_text_entered(new_text: String) -> void:
	# Kinda hacky, but this is not an AcceptDialog so it doesn't have
	# the register_text_enter() method
	yield(get_tree().create_timer(0.1), "timeout")
	$VBoxContainer/HBoxContainer/OkButton.emit_signal("pressed")
