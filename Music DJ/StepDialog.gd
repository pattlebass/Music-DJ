extends PopupDialog

onready var main = get_parent()

var step
var column

func _on_StepDialog_about_to_show():
	# Set title
	var title = "Column " + str(column+1)
	$VBoxContainer/VBoxContainer/Label.text = title
	
	# Make buttons visible
	if column != main.step_index - 1 or main.step_index == 1:
		$VBoxContainer/HBoxContainer/RemoveButton.disabled = true
	else:
		$VBoxContainer/HBoxContainer/RemoveButton.disabled = false
	
	var falses = -1
	for i in step.get_children():
		if i.text != "":
			falses += 1
	if falses == 0:
		$VBoxContainer/HBoxContainer/ClearButton.disabled = true
	else:
		$VBoxContainer/HBoxContainer/ClearButton.disabled = false


func _on_ClearButton_pressed():
	# Loop through all buttons
	for button in step.get_children():
		if button.name == "Label":
			continue
		button.text = ""
		button.set("custom_styles/normal", null)
		button.set("custom_styles/pressed", null)
		button.set("custom_styles/disabled", null)
		button.set("custom_styles/hover", null)
	
	# Clear from song
	main.last_columns.erase(column)
	for i in 4:
		main.song[i][column] = 0

	hide()


func _on_CancelButton_pressed():
	hide()


func _on_RemoveButton_pressed():
	step.queue_free()
	
	# Clear from song
	main.last_columns.erase(column)
	for i in 4:
		main.song[i][column] = 0
	main.step_index -= 1
	
	hide()
