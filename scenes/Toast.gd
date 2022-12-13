extends Popup

class_name Toast

enum {
	LENGTH_SHORT,
	LENGTH_LONG
}
const scene_path := "res://scenes/Toast.tscn"
var duration: int
var text: String


func popup(bounds := Rect2(0, 0, 0, 0)) -> void:
	$"%Label".text = text
	.popup(bounds)
	
	modulate.a = 0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.1)
	
	match duration:
		LENGTH_SHORT:
			yield(get_tree().create_timer(2), "timeout")
		LENGTH_LONG:
			yield(get_tree().create_timer(4), "timeout")
	
	yield(create_tween().tween_property(self, "modulate:a", 0.0, 0.1), "finished")
	queue_free()
