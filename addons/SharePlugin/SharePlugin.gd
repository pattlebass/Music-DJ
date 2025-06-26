#
# © 2024-present https://github.com/cengiz-pz
#

@tool
extends EditorPlugin

const PLUGIN_NODE_TYPE_NAME = "Share"
const PLUGIN_PARENT_NODE_TYPE = "Node"
const PLUGIN_NAME: String = "SharePlugin"
const PLUGIN_PACKAGE: String = "org.godotengine.plugin.android.share"
const PLUGIN_DEPENDENCIES: Array = [ "androidx.appcompat:appcompat:1.7.0" ]

const PROVIDER_TAG = """
<provider android:name="%s.ShareFileProvider"
		android:exported="false"
		android:authorities="%s.sharefileprovider"
		android:grantUriPermissions="true">
	<meta-data android:name="android.support.FILE_PROVIDER_PATHS" android:resource="@xml/file_provider_paths"/>
</provider>
"""

var android_export_plugin: AndroidExportPlugin
var ios_export_plugin: IosExportPlugin


func _enter_tree() -> void:
	add_custom_type(PLUGIN_NODE_TYPE_NAME, PLUGIN_PARENT_NODE_TYPE, preload("%s.gd" % PLUGIN_NODE_TYPE_NAME), preload("icon.png"))
	android_export_plugin = AndroidExportPlugin.new()
	add_export_plugin(android_export_plugin)
	ios_export_plugin = IosExportPlugin.new()
	add_export_plugin(ios_export_plugin)


func _exit_tree() -> void:
	remove_custom_type(PLUGIN_NODE_TYPE_NAME)
	remove_export_plugin(android_export_plugin)
	android_export_plugin = null
	remove_export_plugin(ios_export_plugin)
	ios_export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	var _plugin_name = PLUGIN_NAME


	func _supports_platform(platform: EditorExportPlatform) -> bool:
		if platform is EditorExportPlatformAndroid:
			return true
		return false


	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug:
			return PackedStringArray(["%s/bin/debug/%s-debug.aar" % [_plugin_name, _plugin_name]])
		else:
			return PackedStringArray(["%s/bin/release/%s-release.aar" % [_plugin_name, _plugin_name]])


	func _get_name() -> String:
		return _plugin_name


	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(PLUGIN_DEPENDENCIES)


	func _get_android_manifest_application_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
		return PROVIDER_TAG % [PLUGIN_PACKAGE, get_option("package/unique_name")]


class IosExportPlugin extends EditorExportPlugin:
	var _plugin_name = PLUGIN_NAME


	func _supports_platform(platform: EditorExportPlatform) -> bool:
		if platform is EditorExportPlatformIOS:
			return true
		return false


	func _get_name() -> String:
		return _plugin_name


	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		add_ios_framework("Foundation.framework")
		add_ios_framework("UIKit.framework")

		add_ios_linker_flags("-ObjC")
