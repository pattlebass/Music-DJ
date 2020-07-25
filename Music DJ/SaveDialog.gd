extends PopupDialog

onready var main = get_parent()
var title = "Title"
var entered_name = "Song"
var type_of_save = "project"
var effect = AudioServer.get_bus_effect(0, 0)

func _on_OkButton_pressed():
	hide()
	if type_of_save == "project":
		# Project save
		var file = File.new()
		file.open("res://saves/"+entered_name+".mdj", File.WRITE)
		file.store_var(main.song)
	else:
		main.get_node("SoundDialog/AudioStreamPlayer").stop()
		main.get_node("ProgressDialog").popup_centered()
		
		# Export
		effect.set_recording_active(true)
		yield(main.play(), "completed")
		effect.set_recording_active(false)
		
		# Saving
		var recording = effect.get_recording()
		if recording:
			recording.save_to_wav("res://saves/"+entered_name+".wav")


func _on_CancelButton_pressed():
	hide()


func _on_SaveDialog_about_to_show():
	$VBoxContainer/VBoxContainer/Label.text = title
	$VBoxContainer/HBoxContainer/OkButton.disabled = true


func _on_SaveDialog_popup_hide():
	$VBoxContainer/VBoxContainer/HBoxContainer/LineEdit.clear()


func _on_LineEdit_text_changed(new_text):
	if new_text != "":
		entered_name = new_text
		$VBoxContainer/HBoxContainer/OkButton.disabled = false
	else:
		$VBoxContainer/HBoxContainer/OkButton.disabled = true
