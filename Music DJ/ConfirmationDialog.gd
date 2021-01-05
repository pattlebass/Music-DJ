extends PopupDialog

onready var main = get_parent()
signal chose

func ready():
	theme = load("res://assets/themes/%s/theme.tres" % GlobalVariables.options.theme)


func alert(_title, _subtitle):
	$VBoxContainer/Title.text = _title
	$VBoxContainer/Subtitle.text = _subtitle
	popup_centered()


func _on_OKButton_pressed():
	emit_signal("chose", true)
	hide()


func _on_CancelButton_pressed():
	emit_signal("chose", false)
	hide()


func _on_ConfirmationDialog_about_to_show():
	$AnimationPlayer.play("fade_in")


func _on_ConfirmationDialog_popup_hide():
	visible = true
	# Animation
	$AnimationPlayer.play_backwards("fade_in")
	yield(get_tree().create_timer(0.1), "timeout")
	
	$VBoxContainer/HBoxContainer/OKButton.pressed = false
	$VBoxContainer/HBoxContainer/CancelButton.pressed = false
	
	visible = false
	queue_free()
