class_name LoadItem
extends VBoxContainer

@onready var button: Button = $Button
@onready var open_button: Button = $ActionsContainer/OpenButton
@onready var download_button: Button = $ActionsContainer/DownloadButton
@onready var share_button: Button = $ActionsContainer/ShareButton
@onready var link_button: Button = $ActionsContainer/LinkButton
@onready var delete_button: Button = $ActionsContainer/DeleteButton
@onready var actions_container: HBoxContainer = $ActionsContainer

signal expanded


func _ready() -> void:
	var theme_path = "res://assets/themes/%s/" % Options.theme
	
	open_button.get_node("VBox/Icon").texture = load(theme_path + "open_file.svg")
	download_button.get_node("VBox/Icon").texture = load(theme_path + "download.svg")
	share_button.get_node("VBox/Icon").texture = load(theme_path + "share.svg")
	link_button.get_node("VBox/Icon").texture = load(theme_path + "link.svg")
	delete_button.get_node("VBox/Icon").texture = load(theme_path + "delete.svg")
	
	actions_container.hide()


func _on_Button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		actions_container.modulate = Color.TRANSPARENT
		var tween := create_tween()
		tween.tween_property(
			self,
			^"custom_minimum_size:y",
			button.size.y + get("theme_override_constants/separation") + actions_container.size.y,
			0.1
		)
		tween.tween_callback(actions_container.show)
		tween.tween_callback(func(): expanded.emit())
		tween.tween_property(actions_container, ^"modulate", Color.WHITE, 0.1)
		
		open_button.grab_focus.call_deferred()
	else:
		var tween := create_tween()
		tween.tween_property(actions_container, ^"modulate", Color.TRANSPARENT, 0.1)
		tween.tween_callback(actions_container.hide)
		tween.tween_property(self, ^"custom_minimum_size:y", 0.0, 0.1)
