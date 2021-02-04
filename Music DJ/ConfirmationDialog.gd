extends "res://DialogScript.gd"

signal chose


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
	theme = load("res://assets/themes/%s/theme.tres" % GlobalVariables.options.theme)
	about_to_show()


func _on_ConfirmationDialog_popup_hide():
	popup_hide()
	yield(get_tree(), "idle_frame")
	queue_free()
