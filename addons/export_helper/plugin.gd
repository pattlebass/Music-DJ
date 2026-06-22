@tool
extends EditorPlugin

var export_plugin = load("res://addons/export_helper/export_plugin.gd").new()


func _enter_tree():
	add_export_plugin(export_plugin)


func _exit_tree():
	remove_export_plugin(export_plugin)
