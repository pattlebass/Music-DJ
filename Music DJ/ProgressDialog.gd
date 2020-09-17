extends PopupDialog

onready var main = get_parent()
onready var progress_bar = get_node("VBoxContainer/HBoxContainer2/VBoxContainer/ProgressBar")

var path_text = ""


func _on_ProgressDialog_about_to_show():
	progress_bar.max_value = main.last_columns.back()+1
	loading()
	$VBoxContainer/Label2.text = path_text.replace("user://", "%APPDATA%/Godot/app_userdata/Music DJ/saves/Exports/")
	$AnimationPlayer.play("fade_in")


func _on_ProgressDialog_popup_hide():
	visible = true
	# Animation
	$AnimationPlayer.play_backwards("fade_in")
	yield(get_tree().create_timer(0.1), "timeout")
	
	progress_bar.value = 1
	
	visible = false


func loading():
	yield(get_tree().create_timer(3), "timeout")
	
	progress_bar.value += 1

	if progress_bar.value >= progress_bar.max_value:
		yield(get_tree().create_timer(3.5), "timeout")
		hide()
		return
	else:
		loading()
		return
		


func _on_CancelButton_pressed():
	hide()
	main.can_play = false
	main.get_node("SaveDialog").is_cancelled = true
