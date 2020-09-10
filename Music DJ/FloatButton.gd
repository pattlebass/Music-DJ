extends Node2D

onready var main = get_parent()

var instrument
var column_no
var pos_y

func _input(event):
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		global_position = get_global_mouse_position()
	else:
		if $Area2D.get_overlapping_areas():
			var collided_button = $Area2D.get_overlapping_areas()[0].get_parent()
			var copied_button = get_child(1)
			
			if collided_button.rect_global_position.y != pos_y:
				queue_free()
				return
			
			collided_button.text = copied_button.text
			
			# Styles
			var style_box = copied_button.get("custom_styles/normal")
			collided_button.set("custom_styles/normal", style_box)
			collided_button.set("custom_styles/pressed", style_box)
			collided_button.set("custom_styles/disabled", style_box)
			collided_button.set("custom_styles/hover", style_box)
			collided_button.set("custom_styles/focus", StyleBoxEmpty)
			
			# Add to play list
			var collided_column_no = int(collided_button.get_parent().get_node("Label").text)-1
			main.song[instrument][collided_column_no] = main.song[instrument][column_no]
			if collided_column_no > main.last_columns.back():
				main.last_columns.append(collided_column_no)
			
		get_parent().get_node("HBoxContainer/StepContainer").mouse_filter = Control.MOUSE_FILTER_STOP
		queue_free()
