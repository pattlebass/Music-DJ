extends PopupDialog

onready var main = get_parent()

var column
var column_no

func _on_ColumnDialog_about_to_show():
	# Set title
	var title = "Column " + str(column_no+1)
	$VBoxContainer/VBoxContainer/Label.text = title
	
	# Make buttons visible
	if column_no != main.column_index - 1 or main.column_index == 15:
		$VBoxContainer/HBoxContainer/RemoveButton.disabled = true
	else:
		$VBoxContainer/HBoxContainer/RemoveButton.disabled = false
	
	var falses = -1
	for i in column.get_children():
		if i is Button and i.text != "":
			falses += 1
	if falses == 0:
		$VBoxContainer/HBoxContainer/ClearButton.disabled = true
	else:
		$VBoxContainer/HBoxContainer/ClearButton.disabled = false
	
	$AnimationPlayer.play("fade_in")

func _on_ClearButton_pressed():
	# Loop through all buttons
	for button in column.get_children():
		if not button is Button or button.name == "Label":
			continue
		button.text = ""
		button.set("custom_styles/normal", null)
		button.set("custom_styles/pressed", null)
		button.set("custom_styles/disabled", null)
		button.set("custom_styles/hover", null)
	
	# Clear from song
	main.last_columns.erase(column_no)
	for i in 4:
		main.song[i][column_no] = 0

	hide()


func _on_CancelButton_pressed():
	hide()


func _on_RemoveButton_pressed():
	# Animation
	column.get_node("AnimationPlayer").play_backwards("fade_in")
	yield(get_tree().create_timer(0.1), "timeout")
	
	column.queue_free()
	
	# Clear from song
	main.last_columns.erase(column_no)
	for i in 4:
		main.song[i][column_no] = 0
	main.column_index -= 1
	
	hide()


func _on_ColumnDialog_popup_hide():
	visible = true
	# Animation
	$AnimationPlayer.play_backwards("fade_in")
	yield(get_tree().create_timer(0.1), "timeout")
	
	visible = false
