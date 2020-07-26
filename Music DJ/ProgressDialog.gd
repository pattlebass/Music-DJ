extends PopupDialog

onready var main = get_parent()
onready var progress_bar = get_node("VBoxContainer/HBoxContainer2/VBoxContainer/ProgressBar")

func _on_ProgressDialog_about_to_show():
	progress_bar.max_value = main.last_columns.back()+1
	loading()


func _on_ProgressDialog_popup_hide():
	progress_bar.value = 1


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
