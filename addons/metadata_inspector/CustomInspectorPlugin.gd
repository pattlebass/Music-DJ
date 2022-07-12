tool
extends EditorInspectorPlugin


# this faux EditorInspectorPlugin is necessary to update the real EditorPlugin at the right time
func can_handle(object):
	if object.is_class("Node"):
		var metadata_inspector
		for n0 in object.get_tree().get_root().get_children():
			for n1 in n0.get_children():
				if n1.is_class("EditorPlugin"):
					if "is_metadata_inspector" in n1:
						 metadata_inspector = n1
		if object.get_filename().length() > 0 and object.get_filename() != object.get_tree().edited_scene_root.filename:
			metadata_inspector.set_nonodelabel("Please edit the metadata from inside the scene of this instance.")
		else:
			metadata_inspector.update_node(object, ["load"], {}, [[], "new"])
	#else:
	#	metadata_inspector.set_nonodelabel("Select a single node to edit and view its metadata.")
	return false
