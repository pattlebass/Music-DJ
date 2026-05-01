#
# © 2024-present https://github.com/cengiz-pz
#

@tool
@icon("icon.png")
class_name Share extends Node

const PLUGIN_SINGLETON_NAME: String = "SharePlugin"

signal share_completed(activity_type: String)
signal share_failed(error_message: String)
signal share_canceled()

const MIME_TYPE_TEXT: String = "text/plain"
const MIME_TYPE_IMAGE: String = "image/*"

const SIGNAL_NAME_SHARE_COMPLETED: String = "share_completed";
const SIGNAL_NAME_SHARE_FAILED: String = "share_failed";
const SIGNAL_NAME_SHARE_CANCELED: String = "share_canceled";

@onready var _temp_image_path: String = OS.get_user_data_dir() + "/tmp_share_img_path.png"

var _plugin_singleton: Object


func _ready() -> void:
	_update_plugin()


func _notification(a_what: int) -> void:
	if a_what == NOTIFICATION_APPLICATION_RESUMED:
		_update_plugin()


func _update_plugin() -> void:
	if _plugin_singleton == null:
		if Engine.has_singleton(PLUGIN_SINGLETON_NAME):
			_plugin_singleton = Engine.get_singleton(PLUGIN_SINGLETON_NAME)
			_connect_signals()
		elif not OS.has_feature("editor_hint"):
			log_error("%s singleton not found!" % PLUGIN_SINGLETON_NAME)


func _connect_signals() -> void:
	_plugin_singleton.connect(SIGNAL_NAME_SHARE_COMPLETED, _on_share_completed)
	_plugin_singleton.connect(SIGNAL_NAME_SHARE_FAILED, _on_share_failed)
	_plugin_singleton.connect(SIGNAL_NAME_SHARE_CANCELED, _on_share_canceled)


func share_text(a_title: String, a_subject: String, a_content: String) -> void:
	if _plugin_singleton != null:
		_plugin_singleton.share(
			SharedData.new()
				.set_title(a_title)
				.set_subject(a_subject)
				.set_content(a_content)
				.set_mime_type(MIME_TYPE_TEXT)
				.get_raw_data()
		)
	else:
		log_error("%s plugin not initialized" % PLUGIN_SINGLETON_NAME)


func share_image(a_path: String, a_title: String, a_subject: String, a_content: String) -> void:
	share_file(a_path, MIME_TYPE_IMAGE, a_title, a_subject, a_content)


func share_texture(a_texture: Texture2D, a_title: String, a_subject: String, a_content: String) -> void:
	var __image: Image = a_texture.get_image()
	__image.save_png(_temp_image_path)
	share_file(_temp_image_path, MIME_TYPE_IMAGE, a_title, a_subject, a_content)


func share_viewport(a_viewport: Viewport, a_title: String, a_subject: String, a_content: String, a_flip_y: bool = false) -> void:
	var __image: Image = a_viewport.get_texture().get_image()
	if a_flip_y:
		__image.flip_y()
	__image.save_png(_temp_image_path)
	share_file(_temp_image_path, MIME_TYPE_IMAGE, a_title, a_subject, a_content)


func share_file(a_path: String, a_mime_type: String, a_title: String, a_subject: String, a_content: String) -> void:
	if _plugin_singleton != null:
		_plugin_singleton.share(
			SharedData.new()
				.set_title(a_title)
				.set_subject(a_subject)
				.set_content(a_content)
				.set_mime_type(a_mime_type)
				.set_file_path(a_path)
				.get_raw_data()
		)
	else:
		log_error("%s plugin not initialized" % PLUGIN_SINGLETON_NAME)


func _on_share_completed(a_activity_type: String) -> void:
	emit_signal(SIGNAL_NAME_SHARE_COMPLETED, a_activity_type)


func _on_share_failed(a_error_message: String) -> void:
	emit_signal(SIGNAL_NAME_SHARE_FAILED, a_error_message)


func _on_share_canceled() -> void:
	emit_signal(SIGNAL_NAME_SHARE_CANCELED)


static func log_error(a_description: String) -> void:
	push_error(a_description)


static func log_info(a_description: String) -> void:
	print_rich("[color=cyan]INFO: %s[/color]" % a_description)
