class_name CustomConfirmDialog
extends CustomAcceptDialog

@onready var title_label: Label = %Title
@onready var body_label: RichTextLabel = %Body

signal chose


func _ready() -> void:
	super()
	dim = false


func alert(title: String, subtitle: String) -> void:
	title_label.text = title
	body_label.text = subtitle
	popup_centered()


func _on_OKButton_pressed() -> void:
	chose.emit(true)
	hide()


func _on_CancelButton_pressed() -> void:
	chose.emit(false)
	hide()


func popup_hide() -> void:
	super()
	await get_tree().create_timer(0.1).timeout
	queue_free()
