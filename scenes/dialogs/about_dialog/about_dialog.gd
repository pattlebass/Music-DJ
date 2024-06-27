class_name AboutDialog
extends CustomDialog

const SCROLL_MULTIPLIER = 2000

@onready var rich_text: RichTextLabel = %RichTextLabel
@onready var scroll_container: ScrollContainer = %ScrollContainer

var open_meta := true


func _ready() -> void:
	rich_text.text = "Version: %s\n\n" % ProjectSettings.get_setting("application/config/version") + rich_text.text


func popup() -> void:
	scroll_container.scroll_vertical = 0
	scroll_container.grab_focus()
	super()


func _on_close_button_pressed() -> void:
	hide()


func _on_rich_text_label_meta_clicked(meta: String) -> void:
	if open_meta:
		OS.shell_open(meta)


func _on_scroll_container_scroll_started() -> void:
	open_meta = false


func _on_scroll_container_scroll_ended() -> void:
	open_meta = true


func _on_scroll_container_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_down", true) or event.is_action_pressed(&"ui_page_down", true):
		scroll_container.scroll_vertical += int(SCROLL_MULTIPLIER * get_process_delta_time())
	elif event.is_action_pressed(&"ui_up", true) or event.is_action_pressed(&"ui_page_up", true):
		scroll_container.scroll_vertical -= int(SCROLL_MULTIPLIER * get_process_delta_time())
