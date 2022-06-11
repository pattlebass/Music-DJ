extends CustomDialog

signal chose

func _ready():
	if !OS.is_ok_left_and_cancel_right():
		$VBoxContainer/HBoxContainer.move_child(
			$VBoxContainer/HBoxContainer/CancelButton,
			0
		)
	dim = false

func alert(_title, _subtitle):
	$VBoxContainer/Title.text = _title
	$VBoxContainer/Subtitle.bbcode_text = _subtitle
	popup_centered()


func _on_OKButton_pressed():
	emit_signal("chose", true)
	hide()


func _on_CancelButton_pressed():
	emit_signal("chose", false)
	hide()


func _on_ConfirmationDialog_about_to_show():
	about_to_show()
	$BackPanel.modulate = Color(1, 1, 1, 1)


func _on_ConfirmationDialog_popup_hide():
	popup_hide()
	yield(get_tree().create_timer(0.1), "timeout")
	queue_free()
