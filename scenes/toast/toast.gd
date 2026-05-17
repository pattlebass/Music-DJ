class_name Toast
extends PopupPanel

enum Length {
	LENGTH_SHORT,
	LENGTH_LONG
}

var duration: Length
var text: String

var container: Container


func _ready() -> void:
	unfocusable = true
	initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	build()


func build() -> void:
	container = MarginContainer.new()
	container.material = CanvasItemMaterial.new()
	container.material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	container.add_theme_constant_override(&"margin_top", 10)
	container.add_theme_constant_override(&"margin_right", 10)
	container.add_theme_constant_override(&"margin_bottom", 10)
	container.add_theme_constant_override(&"margin_left", 10)
	add_child(container)
	
	var panel_container = PanelContainer.new()
	panel_container.theme_type_variation = &"Toast"
	panel_container.use_parent_material = true
	container.add_child(panel_container)
	
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"Text"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel_container.add_child(label)
	
	size.y = 0
	add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	var window_size := DisplayServer.window_get_size()
	position.x = window_size.x / 2 - size.x / 2
	position.y = window_size.y * 3 / 4


func open() -> void:
	popup()
	
	var tween := create_tween()
	tween.tween_property(container, ^"modulate:a", 1.0, 0.1).from(0)
	match duration:
		Length.LENGTH_SHORT:
			tween.tween_interval(2)
		Length.LENGTH_LONG:
			tween.tween_interval(4)
	tween.tween_property(container, ^"modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
