#
# © 2024-present https://github.com/cengiz-pz
#

@tool
class_name Share
extends Node

const PLUGIN_SINGLETON_NAME: String = "SharePlugin"
const PLUGIN_TARGET_OS: String = "android"

const MIME_TYPE_TEXT: String = "text/plain"
const MIME_TYPE_IMAGE: String = "image/*"

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
		elif OS.has_feature(PLUGIN_TARGET_OS):
			printerr("%s singleton not found!" % PLUGIN_SINGLETON_NAME)
		#else:
			#printerr("%s plugin should be run on %s!" % [PLUGIN_SINGLETON_NAME, PLUGIN_TARGET_OS])


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
		printerr("%s plugin not initialized" % PLUGIN_SINGLETON_NAME)


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
		printerr("%s plugin not initialized" % PLUGIN_SINGLETON_NAME)
