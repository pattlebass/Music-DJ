extends CustomDialog

var title := "Title"
var entered_name := ""
var last_name := ""
var type_of_save := "project"
var effect = AudioServer.get_bus_effect(0, 0)
var is_cancelled = false

onready var line_edit = $VBoxContainer/VBoxContainer/HBoxContainer/LineEdit
onready var ok_button = $VBoxContainer/HBoxContainer/OkButton
onready var label_error = $VBoxContainer/VBoxContainer/LabelError


func _ready() -> void:
	if !OS.is_ok_left_and_cancel_right():
		$VBoxContainer/HBoxContainer.move_child(
			$VBoxContainer/HBoxContainer/CancelButton,
			0
		)


func save():
	entered_name = entered_name.strip_edges()
	if type_of_save == "project":
		# Project save
		var path = Variables.user_dir.plus_file("Projects/%s.mdj" % entered_name)
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
		var path = Variables.user_dir.plus_file("Exports/%s.wav" % entered_name)
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
		
		last_name = entered_name


func _on_OkButton_pressed():
	hide()
	save()

func _on_CancelButton_pressed():
	hide()


func about_to_show():
	if !Variables.has_storage_perms():
		hide()
	
	$VBoxContainer/VBoxContainer/Label.text = title
	
	# Changing the text this way doesn't emit the signal
	line_edit.text = last_name if last_name else get_default_name()
	_on_LineEdit_text_changed(line_edit.text)
	
	line_edit.caret_position = line_edit.text.length()
	
	.about_to_show()


func _on_LineEdit_text_changed(new_text):
	if not new_text.strip_edges().is_valid_filename() or new_text[0] == ".":
		ok_button.disabled = true
		
		if new_text:
			label_error.text = "Invalid file name: / \\ ? * \" | % < > :"
		
		return
	
	entered_name = new_text
	ok_button.disabled = false
	label_error.text = ""


func _process(_delta):
	if OS.get_virtual_keyboard_height() == 0:
		rect_position.y = get_viewport().get_visible_rect().size.y / 2 - rect_size.y / 2
	else:
		rect_position.y = get_viewport().get_visible_rect().size.y/2 - rect_size.y / 2 - OS.get_virtual_keyboard_height()/4


func get_default_name() -> String:
	return "Song " + str(randi() % 1000)


func _on_LineEdit_text_entered(_new_text: String) -> void:
	# Kinda hacky, but this is not an AcceptDialog so it doesn't have
	# the register_text_enter() method
	if ok_button.disabled:
		return
	yield(get_tree().create_timer(0.1), "timeout")
	ok_button.emit_signal("pressed")
