class_name Toast
extends Window

enum Length {
	LENGTH_SHORT,
	LENGTH_LONG
}

@onready var label: Label = %Label

var duration: Length
var text: String

@onready var container: Control = $PanelContainer

func _ready() -> void:
	#super()
	popup_window = false
	#dim_background = false


func popup2() -> void:
	#super()
	
	label.text = text
	
	var tween := create_tween()
	tween.tween_property(container, ^"modulate:a", 1.0, 0.1)
	match duration:
		Length.LENGTH_SHORT:
			tween.tween_interval(2)
		Length.LENGTH_LONG:
			tween.tween_interval(4)
	tween.tween_property(container, ^"modulate:a", 0.0, 0.1)
	#tween.tween_callback(queue_free)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_home"):
		queue_free()
