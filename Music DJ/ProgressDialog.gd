extends PopupDialog

onready var main = get_parent()


func _on_ProgressDialog_about_to_show():
	$VBoxContainer/ProgressBar.max_value = main.last_columns.back()+1
	loading()


func _on_ProgressDialog_popup_hide():
	$VBoxContainer/ProgressBar.value = 1


func loading():
	yield(get_tree().create_timer(3), "timeout")
	
	$VBoxContainer/ProgressBar.value += 1

	if $VBoxContainer/ProgressBar.value >= $VBoxContainer/ProgressBar.max_value:
		yield(get_tree().create_timer(3.5), "timeout")
		hide()
		return
	else:
		loading()
		return
		
