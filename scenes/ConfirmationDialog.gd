extends "res://scenes/DialogScript.gd"

signal chose


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
	theme = GlobalVariables.theme_resource
	about_to_show()


func _on_ConfirmationDialog_popup_hide():
	popup_hide()
	yield(get_tree().create_timer(0.1), "timeout")
	queue_free()
