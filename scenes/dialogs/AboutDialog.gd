extends CustomDialog


onready var rich_text = $VBoxContainer/ScrollContainer/RichTextLabel
onready var scroll_container = $VBoxContainer/ScrollContainer

var open_meta := true


func _ready() -> void:
	# RichTextLabel.append_bbcode() doesn't work
	# See https://github.com/godotengine/godot/issues/18413
	rich_text.bbcode_text = "Version: %s\n\n" % Variables.VERSION + rich_text.bbcode_text


func _on_RichTextLabel_meta_clicked(meta) -> void:
	if open_meta:
		OS.shell_open(meta)


func about_to_show() -> void:
	scroll_container.scroll_vertical = 0
	.about_to_show()


func _on_CloseButton_pressed() -> void:
	hide()


func _on_ScrollContainer_scroll_started() -> void:
	open_meta = false


func _on_ScrollContainer_scroll_ended() -> void:
	open_meta = true


func _on_ScrollContainer_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_page_down", true):
		scroll_container.scroll_vertical += 2000 * get_process_delta_time()
	elif event.is_action_pressed("ui_up", true) or event.is_action_pressed("ui_page_up", true):
		scroll_container.scroll_vertical -= 2000 * get_process_delta_time()
