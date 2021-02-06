extends "res://DialogScript.gd"

var title = "Title"
var entered_name = ""
var last_name
var type_of_save = "project"
var effect = AudioServer.get_bus_effect(0, 0)
var is_cancelled = false

var once = false


func _ready():
	$VBoxContainer/VBoxContainer/HBoxContainer/LineEdit.theme = load("res://assets/themes/%s/theme.tres" % GlobalVariables.options.theme)


func save():
	if type_of_save == "project":
		# Project save
		var path = main.user_dir+"Projects/"+entered_name+".mdj"
		var file = File.new()
		file.open(path, File.WRITE)
		file.store_var(main.song)
		file.close()
		
		# ProgressDialog
		main.get_node("ProgressDialog").path_text = path
		main.get_node("ProgressDialog").after_saving = "close"
		main.get_node("ProgressDialog").progress_bar.max_value = 0.2
		main.get_node("ProgressDialog").popup_centered()
		
		last_name = entered_name
	else:
		main.get_node("SoundDialog/AudioStreamPlayer").stop()
		
		# ProgressDialog
		var path = main.user_dir+"Exports/"+entered_name+".wav"
		main.get_node("ProgressDialog").path_text = path
		main.get_node("ProgressDialog").after_saving = "stay"
		main.get_node("ProgressDialog").progress_bar.max_value = 3*(main.last_columns.back()+1) + 0.5
		main.get_node("ProgressDialog").popup_centered()
		
		# Export
		effect.set_recording_active(true)
		yield(main.play_song(), "completed")
		effect.set_recording_active(false)
		
		# Saving
		var recording = effect.get_recording()
		if recording and not is_cancelled:
			recording.save_to_wav(path)
		
		is_cancelled = false


func _on_OkButton_pressed():
	save()
	hide()

func _on_CancelButton_pressed():
	hide()

func _on_OverwriteButton_pressed():
	entered_name = last_name
	save()
	hide()


func about_to_show():
	# Check for permissions
	OS.request_permissions()
	yield(get_tree(), "idle_frame")
	if OS.get_granted_permissions().empty() && OS.get_name() == "Android":
		hide()
	
	$VBoxContainer/VBoxContainer/Label.text = title
	$VBoxContainer/HBoxContainer/OkButton.disabled = true
	$VBoxContainer/VBoxContainer/HBoxContainer/LineEdit.clear()
	if last_name and type_of_save == "project":
		$VBoxContainer/HBoxContainer/OverwriteButton.show()
	else:
		$VBoxContainer/HBoxContainer/OverwriteButton.hide()
	OS.show_virtual_keyboard("")
	rect_position.x = get_viewport().get_visible_rect().size.x/2 - 200
	
	.about_to_show()


func _on_LineEdit_text_changed(new_text):
	
	# TODO: Figure out Regex
	var invalid_chars = ["<", ">", ":", "\"", "/", ")", "\\", "|", "?", "*"]
	
	for i in invalid_chars:
		if i in new_text:
			$VBoxContainer/VBoxContainer/HBoxContainer/LineEdit.text = entered_name
			return
	
	if new_text != "":
		entered_name = new_text
		$VBoxContainer/HBoxContainer/OkButton.disabled = false
	else:
		$VBoxContainer/HBoxContainer/OkButton.disabled = true


func _process(delta):
	if OS.get_virtual_keyboard_height() == 0:
		rect_position.y = get_viewport().get_visible_rect().size.y/2 - 100
	else:
		rect_position.y = get_viewport().get_visible_rect().size.y/2 - 100 - OS.get_virtual_keyboard_height()/4



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
var a = document.createElement('a')
a.download = '%s'
a.href = 'data:%s;base64,%s';
a.target = '_blank'
a.click();
	""" % [_file_name, mime_type, file_data_64])

