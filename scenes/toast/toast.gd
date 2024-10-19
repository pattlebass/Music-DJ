class_name Toast
extends CustomDialog

enum Length {
	LENGTH_SHORT,
	LENGTH_LONG
}
var duration: Length
var text: String


func _ready() -> void:
	dim_background = false


func popup() -> void:
	super()
	
	%Label.text = text
	
	create_tween().tween_property(self, ^"modulate:a", 1.0, 0.1)
	
	match duration:
		Length.LENGTH_SHORT:
			await get_tree().create_timer(2).timeout
		Length.LENGTH_LONG:
			await get_tree().create_timer(4).timeout
	
	await create_tween().tween_property(self, ^"modulate:a", 0.0, 0.1).finished
	queue_free()
