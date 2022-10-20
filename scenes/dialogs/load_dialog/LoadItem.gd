extends VBoxContainer


onready var button = $Button
onready var open_button = $ActionsContainer/OpenButton
onready var download_button = $ActionsContainer/DownloadButton
onready var share_button = $ActionsContainer/ShareButton
onready var delete_button = $ActionsContainer/DeleteButton

signal expanded


func _ready() -> void:
	var theme_path = "res://assets/themes/%s/" % Variables.options.theme
	
	open_button.get_node("VBox/Icon").texture = load(theme_path + "open_file.svg")
	download_button.get_node("VBox/Icon").texture = load(theme_path + "download.svg")
	share_button.get_node("VBox/Icon").texture = load(theme_path + "share.svg")
	delete_button.get_node("VBox/Icon").texture = load(theme_path + "delete.svg")


func _on_Button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		$ActionsContainer.modulate = Color.transparent
		var tween = create_tween()
		tween.tween_property(
			self,
			"rect_min_size:y",
			button.rect_size.y + get("custom_constants/separation") + $ActionsContainer.rect_size.y,
			0.1
		)
		tween.tween_callback($ActionsContainer, "show")
		tween.tween_callback(self, "emit_signal", ["expanded"])
		tween.tween_property($ActionsContainer, "modulate", Color.white, 0.1)
	else:
		var tween = create_tween()
		tween.tween_property($ActionsContainer, "modulate", Color.transparent, 0.1)
		tween.tween_callback($ActionsContainer, "hide")
		tween.tween_property(self, "rect_min_size:y", 0.0, 0.1)
