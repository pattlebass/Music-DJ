extends CustomDialog


func _ready() -> void:
	$VBoxContainer/LabelVersion.text = Variables.VERSION


func _on_RichTextLabel_meta_clicked(meta) -> void:
	OS.shell_open(meta)


func about_to_show() -> void:
	$VBoxContainer/RichTextLabel.scroll_to_line(0)
	.about_to_show()
