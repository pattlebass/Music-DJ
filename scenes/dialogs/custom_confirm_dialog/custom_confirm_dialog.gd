class_name CustomConfirmDialog
extends CustomAcceptDialog

@onready var title_label: Label = %Title
@onready var body_label: RichTextLabel = %Body

signal chose


func _ready() -> void:
	super()
	dim_background = false
	popup_window = false


func alert(p_title: String, subtitle: String) -> void:
	title_label.text = p_title
	body_label.text = subtitle
	popup2()


func _on_OKButton_pressed() -> void:
	popup_hide2()
	chose.emit(true)


func _on_CancelButton_pressed() -> void:
	popup_hide2()
	chose.emit(false)


func popup_hide2() -> void:
	super()
	await get_tree().create_timer(0.1).timeout
	queue_free()
