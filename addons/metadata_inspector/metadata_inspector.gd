tool
extends EditorPlugin

var MAX_ENTRIES = 120

var metapanel
var nonodelabel
var vbox
var plugin : EditorInspectorPlugin

#var realtime_updater : Node

var is_metadata_inspector = false

var activenode = null
var lastfocus = [[], ""]


var l = TypeFormattingLogic.new()

var fpscounter = 0


var global_choices   = ["delete", "undo", "redo", "move↑", "move↓", "path?"]
var global_shortcuts = [KEY_DELETE, KEY_Z, KEY_Z, KEY_UP, KEY_DOWN, KEY_C]
var global_mods      = ["c", "c", "cs", "c", "c", "cs"]

var prev_focus_rootbox
var last_focus_rootbox 

func _enter_tree():

	while(destroy_old()):
		destroy_old()

	plugin = preload("./CustomInspectorPlugin.gd").new()
	add_inspector_plugin(plugin)

#	realtime_updater = preload("./RealtimeUpdater.gd").new()
#	self.add_child(realtime_updater)

	metapanel = ScrollContainer.new()
	metapanel.name = "Meta"
	metapanel.size_flags_horizontal = metapanel.SIZE_EXPAND_FILL
	metapanel.size_flags_vertical = metapanel.SIZE_EXPAND_FILL

	vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = vbox.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = vbox.SIZE_EXPAND_FILL
	#vbox.valign = vbox.VALIGN_TOP
	#vbox.align = vbox.ALIGN_BEGIN
	metapanel.add_child(vbox)

	nonodelabel = Label.new()
	nonodelabel.text="Select a single node to edit and view its metadata."
	nonodelabel.size_flags_vertical = Label.SIZE_EXPAND_FILL
	nonodelabel.size_flags_horizontal = Label.SIZE_EXPAND_FILL
	nonodelabel.valign = Label.VALIGN_CENTER
	nonodelabel.align = Label.ALIGN_CENTER
	nonodelabel.autowrap = true
	nonodelabel.set_custom_minimum_size(Vector2(100,0))
	metapanel.add_child(nonodelabel)

	add_control_to_dock(DOCK_SLOT_RIGHT_UL, metapanel)

	is_metadata_inspector = true


func get_metavals(n):
	var metavals = {}
	for key in n.get_meta_list():
		if typeof(key) == TYPE_STRING:
			metavals[key] = n.get_meta(key)
		else:
			print("Metadata Inspector: Weird meta index, not string, ignoring: "+str(key))
	return metavals


func update_node(n, act, save_metavals, focus):
	#n.set_meta("friends", [n.get_node("Character-Sprite")])
	#print(n.name+" : "+str(act)+" : "+str(save_metavals)+" : "+str(focus))
	#print("Updating: "+n.name)
	#n.set_meta("mustbestring", {1.0: Label.new(), 55 : Quat(1,1,1,1), false: "myval3"})
	#n.set_meta("nestedshit", ["array1", "array2", "array3", {"thisisdictkey1": "thisisdictval1", "thisisdictkey2": "thisisdictval2", "shit": [1,2,3,4,5]}])
	
	for oldentry in vbox.get_children():
		vbox.remove_child(oldentry)
		oldentry.queue_free()

	if is_instance_valid(n) and not n.is_queued_for_deletion():
		if "save" in act:
			for key in n.get_meta_list():
				if typeof(key) == TYPE_STRING:
					# Godot 3.1 has no remove_meta and uses null instead
					if n.has_method("remove_meta"):
						n.remove_meta(key)
					else:
						n.set_meta(key, null)
			for key in save_metavals:
				n.set_meta(key, save_metavals[key])

		prev_focus_rootbox = vbox
		
		var metavals = get_metavals(n)
		var counted_entries = count_entries(metavals, 0) - 1
		if  counted_entries < MAX_ENTRIES:
			var prevbox = null
			for key in metavals:
				if n.has_method("remove_meta") or metavals[key] != null:
					prevbox = ui_create_rows_recursively(metavals[key], key, vbox, TYPE_DICTIONARY, [], focus, prevbox)
			last_focus_rootbox = ui_just_make_rootbox(vbox, "NEWENTRY")
			
			ui_create_row(last_focus_rootbox, "", "", true, [true, true], ["*+***__**+**NEWENTRY**+**__***+*"], focus)
			
			vbox.visible = true
			nonodelabel.visible = false
			
			var oldactivenode = activenode
			activenode = n
			if oldactivenode != null and oldactivenode != activenode:
				get_editor_interface().get_selection().clear()
				get_editor_interface().get_selection().add_node(activenode)
		else:
			set_nonodelabel("This node has "+str(counted_entries)+" entry rows and thereby exceeds the limit of "+str(MAX_ENTRIES)+". If you wish to view its metadata, please change the MAX_ENTRIES limit in the plugin code.")
	else:
		set_nonodelabel("Select a single node to edit and view its metadata.")


func set_nonodelabel(txt):
		nonodelabel.text = txt
		vbox.visible = false
		nonodelabel.visible = true


func ui_copy_path_to_clipboard(obj):
	var ppa = Array(str(activenode.get_path()).split("@@")[-1].split("/"))
	ppa.pop_front()
	var pps = "/root"
	for val in ppa:
		pps += "/"+val

	var path = obj.get_parent().get_node("./textbox_key").get_meta("path").duplicate()
	var result = "get_node(\""+pps+"\").get_meta(\""+str(path[0])+"\")"

	if str(path[-1]) == "*+***__**+**NEWENTRY**+**__***+*":
		result = ""
	else:
		path.pop_front()
		for key in path:
			var fkey = "**UNSUPPORTED TYPE**"
			if typeof(key) == TYPE_INT:
				fkey = str(key)
			elif typeof(key) == TYPE_STRING:
				fkey = '"'+key+'"'
			result += "["+fkey+"]"
			
		print(result)
		OS.set_clipboard(result)
	



func delete_entry_from_ui_and_update(obj):
	var rootbox = obj.get_parent().get_parent()
	var parent = rootbox.get_parent()

	var children = []
	for n in parent.get_children():
		children.push_back(n)
	
	var textbox_keyorval
	if rootbox.get_children()[0].get_node("./textbox_val").has_focus():
		textbox_keyorval = rootbox.get_children()[0].get_node("./textbox_val")
	else:
		textbox_keyorval = rootbox.get_children()[0].get_node("./textbox_key")

	if not rootbox.get_children()[0].get_node("./textbox_key").get_meta("isnew"):
		var prev_focus_rootbox = rootbox.get_meta("prev_focus_rootbox")
		if prev_focus_rootbox == vbox:
			last_focus_rootbox.get_children()[0].get_node("./textbox_key").grab_focus()
		else:
			prev_focus_rootbox.get_children()[0].get_node("./textbox_key").grab_focus()
	else:
		var poppedpath = rootbox.get_children()[0].get_node("./textbox_key").get_meta("path")
		poppedpath.pop_back()
		lastfocus[0] = poppedpath
		lastfocus[1] = "new"

	parent.remove_child(rootbox)
	
	if update_all_from_ui(null):
		rootbox.queue_free()
	else:
		for n in parent.get_children():
			parent.remove_child(n)
		for n in children:
			parent.add_child(n)
		textbox_keyorval.grab_focus()

func move_entry_inside_ui_and_update(obj, direction):
	var rootbox = obj.get_parent().get_parent()
	var prevbox = rootbox.get_meta("prevbox") if rootbox.has_meta("prevbox") else null
	var nextbox = rootbox.get_meta("nextbox") if rootbox.has_meta("nextbox") else null

	if (prevbox == null and direction == "up") or (nextbox == null and direction == "down"):
		return false

	var newbox = prevbox if direction == "up" else nextbox

	var keyorval
	if rootbox.get_children()[0].get_node("./textbox_val").has_focus():
		 keyorval = "val"
	else:
		keyorval = "key"

	# swaps children rootbox <-> newbox
	var nextchildren = []
	for n in newbox.get_children():
		nextchildren.push_back(n)
		newbox.remove_child(n)
	for n in rootbox.get_children():
		rootbox.remove_child(n)
		newbox.add_child(n)
	for n in nextchildren:
			rootbox.add_child(n)

	# this causes excessive reloads from CustomInspectorPlugin which makes it lose focus
	# not necessary, but for completions sake
	#var rootboxname = rootbox.name
	#var newboxname = newbox.name
	#newbox.name = "~~~~~~~~~~~~~~~~~~~shoa"
	#rootbox.name = newboxname
	#newbox.name = rootboxname

	newbox.get_children()[0].get_node("./textbox_"+keyorval).grab_focus()

	update_all_from_ui(null)


func update_all_from_ui(unused):

	var prevfocus = lastfocus.duplicate(true)

	var metavals = {}

	if update_from_textboxes_recursively(vbox, [[],[],[]], metavals) == 0:
		var undo_redo = get_undo_redo()
		undo_redo.create_action("Save Metavals on Node "+activenode.name)
		undo_redo.add_do_method(self, "update_node", activenode, ["save"], metavals, lastfocus.duplicate(true))
		undo_redo.add_undo_method(self, "update_node", activenode, ["save"], get_metavals(activenode), prevfocus)
		undo_redo.commit_action()

		return true
	else:
		print("Metadata Inspector: Unknown error while updating! (dup vals?)")
		return false


func update_from_textboxes_recursively(tbox, tpath, metavals):
	var failure = 0

	if tbox.is_class("Node"):
		
		# this looks sort of super stupid, but in order to re-count array positions from scratch there seems to be no other way
		var path = [[],[],[]]
		if tbox.name.substr(0,7) == "RootBox":
			var newkey
			if tbox.get_children()[0].get_node("./textbox_key").editable:
				newkey = tbox.get_children()[0].get_node("./textbox_key").text
			else:
				newkey = tbox.get_children()[0].get_node("./textbox_key").get_meta("oval")

			path[0] = tpath[0] + [newkey]
			path[1] = tpath[1] + [typeof(tbox.get_children()[0].get_node("./textbox_val").get_meta("oval"))]
			path[2] = tpath[2] + [0]
			
			if path[0].size() > 1:
				if tpath[1][-1] == TYPE_ARRAY:
					path[0][-1] = tpath[2][-1]
				tpath[2][-1] += 1
			
			tbox.set_meta("path", path[0])
		else:
			path = tpath
			
		for n in tbox.get_children():
			if n.has_node("./textbox_key"):
				if not update_from_textbox(n, path[0], metavals):
					failure += 1
			failure += update_from_textboxes_recursively(n, path, metavals)
	return failure

func save_focus(obj, tpath, isnew):
	var poppedpath = [] + tpath
	poppedpath.pop_back()
	
	if obj.get_node("./textbox_key").has_focus():
		if isnew:
			lastfocus[0] = poppedpath
			lastfocus[1] = "new"
		else:
			lastfocus[0] = tpath
			lastfocus[1] = "key"
	elif obj.get_node("./textbox_val").has_focus():
		if isnew:
			lastfocus[0] = poppedpath
			lastfocus[1] = "new"
		else:
			lastfocus[0] = tpath
			lastfocus[1] = "val"

func update_from_textbox(obj, tpath, metavals):

	var isnew = obj.get_node("./textbox_key").get_meta("isnew")

	save_focus(obj, tpath, isnew)
	
	var okey = obj.get_node("./textbox_key").get_meta("oval")
	var oval = obj.get_node("./textbox_val").get_meta("oval")

	var key = obj.get_node("./textbox_key").text
	var val = obj.get_node("./textbox_val").text

	var typ = null
	if obj.get_node("./textbox_val").has_meta("type"):
		typ = obj.get_node("./textbox_val").get_meta("type")

	var save_val = oval
	var save_key = key
	
	if typeof(okey) == TYPE_INT:
		save_key = int(key)
	
	if not obj.get_node("./textbox_key").editable:
		save_key = okey

	if( (obj.get_node("./textbox_val").editable)
	and (typeof(oval) != typ or l.custom_val2str(oval) != val)
	):
		if typ == null:
			typ = l.guess_my_type(val)

		var val0_err1 = l.custom_convert(val, typ)
		if val0_err1.size() > 1:
			ui_make_error_popup("Error in "+str(key)+" ! "+val0_err1[1])
			return false
		else:
			save_val = val0_err1[0]
	else:
		save_val = oval

	if typeof(save_key) in [TYPE_STRING, TYPE_INT]:
		if typeof(oval) == TYPE_DICTIONARY:
			save_val = {}
		if typeof(oval) == TYPE_ARRAY:
			save_val = []
		
	if ( 	(isnew)
		and (val.length() == 0 or not obj.get_node("./textbox_val").editable)
		and (key.length() == 0 or not obj.get_node("./textbox_key").editable) 
		and (not obj.get_node("./textbox_val").has_meta("type"))
		): 
		return true

	return store_in_meta_dict_recursively(metavals, [] + tpath, save_key, save_val)


func store_in_meta_dict_recursively(tn, tpath, tkey, tval):
	if tpath.size() > 2:
		var cur = tpath.pop_front()
		return store_in_meta_dict_recursively(tn[cur], tpath, tkey, tval)
	elif  tpath.size() == 2:
		if typeof(tn[tpath[0]]) == TYPE_ARRAY:
			tn[tpath[0]].push_back(tval)
			return true
		else:
			return store_in_meta_dict_if_no_dup(tn[tpath[0]], tkey, tval)
	elif tpath.size() < 2:
			return store_in_meta_dict_if_no_dup(tn, tkey, tval)


func store_in_meta_dict_if_no_dup(obj, tkey, tval):
	if not obj.has(tkey):
		obj[tkey] = tval
		return true
	else:
		ui_make_error_popup("Duplicate key \""+tkey+"\", not updating!")
		return false


func ui_make_error_popup(txt):
	var dia = AcceptDialog.new()
	dia.dialog_text = txt
	#reely.connect("confirmed", self, "delete_and_update_meta", [null, tpath])
	dia.connect("popup_hide", dia, "queue_free")
	activenode.get_tree().get_root().add_child(dia)
	dia.popup_centered()


func change_saved_type(ttype, obj):
	obj.set_meta("type", ttype)
	if not ttype in l.supported_type_names.keys():
		obj.editable = false

	ui_color_indicate_textbox(obj.text, obj)


func ui_color_indicate_textbox(txt, obj):
	if ( txt != str(obj.get_meta("oval"))
	or ( obj.has_meta("type") and obj.get_meta("type") != typeof(obj.get_meta("oval")) )):
		obj.modulate = Color(0.8,0.8,0.8)
		var dtype
		if obj.has_meta("type"):
			dtype = obj.get_meta("type")
		else:
			dtype = l.guess_my_type(txt)

		# this feature would need more work, kind of superflous anyway
		#if dtype in [TYPE_ARRAY, TYPE_DICTIONARY, TYPE_NIL]:
		#	obj.editable = false
			
		for n in obj.get_children():
			if n.is_class("Label") and n.name.substr(0,8) == "TYPEHINT":
				var conv
				var tryconv = l.custom_convert(txt, dtype)
				if tryconv.size() == 1:
					conv = tryconv[0]
				else:
					conv = ["ERR"]

				var dthint = l.get_typehint(conv)

				n.text = dthint[0]
				n.modulate = dthint[1]
				n.visible = true
	else:
		obj.modulate = Color(1,1,1)

func ui_switch_from_key_context_menu(choice, obj):
	if choice == 0:
		delete_entry_from_ui_and_update(obj)
	elif choice == 1:
		get_undo_redo().undo()
	elif choice == 2:
		get_undo_redo().redo()
	elif choice == 3:
		move_entry_inside_ui_and_update(obj, "up")
	elif choice == 4:
		move_entry_inside_ui_and_update(obj, "down")
	elif choice == 5:
		ui_copy_path_to_clipboard(obj)


func ui_context_menu(ev, obj, from):
	if (ev is InputEventMouseButton and ev.button_index == BUTTON_RIGHT) or (ev is InputEventKey and ev.scancode == KEY_MENU):
		if ev.pressed:

			var dbox = PopupMenu.new()
			dbox.name = "CustomPopupMenu"
			
			obj.add_child(dbox)
			dbox.set_size(Vector2(100,10))

			if ev is InputEventMouseButton:
				dbox.set_position(obj.get_global_transform().xform(obj.get_local_mouse_position()))
			else:
				dbox.set_position(obj.get_global_transform().origin+Vector2(10,10))

			if from == "key":
				# Popupmenu is created on the fly so that actual shortcuts from here will never work bc they are totally bugged
				for i in range(0,global_shortcuts.size()):
					dbox.add_shortcut(get_shortcut(global_choices[i], global_shortcuts[i], global_mods[i]), i)
				dbox.connect("id_pressed", self, "ui_switch_from_key_context_menu", [obj])
			elif from == "val":
				if not typeof(obj.get_meta("oval")) in l.supported_type_names.keys():
					dbox.add_item(l.all_type_names[typeof(obj.get_meta("oval"))], typeof(obj.get_meta("oval")))
				for i in l.supported_type_names.keys():
					dbox.add_item(l.supported_type_names[i], i)
				dbox.connect("id_pressed", self, "change_saved_type", [obj])

			dbox.popup()
			dbox.grab_focus()
		else:
			for n in obj.get_children():
				if n.is_class("PopupMenu"):
					n.queue_free()
	
	# here we implement the real shortcuts
	if ev is InputEventKey and ev.pressed and ev.scancode in global_shortcuts:
		var i = global_shortcuts.find(ev.scancode)
		var failure = 0
		if "c" in global_mods[i] and ev.control != true:
				failure += 1
		if "s" in global_mods[i] and ev.shift != true:
				failure += 1
		if "a" in global_mods[i] and ev.alt != true:
				failure += 1
		if failure == 0:
			ui_switch_from_key_context_menu(i, obj)
			

func get_shortcut(label, key, mod):
	var shortcut = ShortCut.new()
	shortcut.resource_name = label
	var inputeventkey = InputEventKey.new()
	inputeventkey.set_scancode(key)
	if "c" in mod:
		inputeventkey.control = true
	if "s" in mod:
		inputeventkey.shift = true
	if "a" in mod:
		inputeventkey.alt = true
	shortcut.set_shortcut(inputeventkey)
	return shortcut


func ui_resize_child_labels(tbox):
	for n in tbox.get_children():
		if n.is_class("Label"):
			n.set_size(tbox.get_size())


func ui_create_rows_recursively(tval, tkey, tbox, ttype, tpath, tfocus, tprevbox):
	var box = ui_just_make_rootbox(tbox, tkey)
	if tprevbox != null:
		box.set_meta("prevbox", tprevbox)
		tprevbox.set_meta("nextbox", box)
	
	var editables = [true, true]
	if ttype == TYPE_ARRAY:
		editables = [false, true]
		
	if not typeof(tkey) in [TYPE_STRING, TYPE_INT]:
		ui_create_row(box, tkey, tval, false, [false, false], tpath + [tkey], tfocus)
	else:
		if typeof(tval) == TYPE_DICTIONARY:
			ui_create_row(box, tkey, tval, false, [editables[0], false], tpath + [tkey],tfocus)
			var dbox = ui_just_make_subboxes(box)
			var dprevbox = null
			for key in tval.keys():
				dprevbox = ui_create_rows_recursively(tval[key], key, dbox, typeof(tval), tpath + [tkey], tfocus, dprevbox)
			var ddbox = ui_just_make_rootbox(dbox, "NEWENTRY")
			ui_create_row(ddbox, "", "", true, [true, true], tpath + [tkey] + ["*+***__**+**NEWENTRY**+**__***+*"], tfocus)
		elif typeof(tval) == TYPE_ARRAY:
			ui_create_row(box, tkey, tval, false, [editables[0], false], tpath + [tkey], tfocus)
			var dbox = ui_just_make_subboxes(box)
			var dprevbox = null
			for i in range(0, tval.size()):
				dprevbox = ui_create_rows_recursively(tval[i], i, dbox, typeof(tval), tpath + [tkey], tfocus, dprevbox)
			var ddbox = ui_just_make_rootbox(dbox, "NEWENTRY")
			ui_create_row(ddbox, str(tval.size()), "", true, [false, true], tpath + [tkey] + ["*+***__**+**NEWENTRY**+**__***+*"], tfocus)
		else:
			ui_create_row(box, tkey, tval, false, editables, tpath + [tkey], tfocus)
	
	return box


func ui_create_row(tbox, tkey, tval, isnew, editables, tpath, tfocus):

	var dbox = HBoxContainer.new()
	dbox.size_flags_horizontal = dbox.SIZE_EXPAND_FILL
	tbox.add_child(dbox)

	var textbox1 = LineEdit.new()
	textbox1.name = "textbox_key"
	textbox1.size_flags_horizontal = textbox1.SIZE_EXPAND_FILL
	textbox1.editable = editables[0]
	textbox1.set_text(str(tkey))
	textbox1.set_cursor_position(1337)
	textbox1.set_meta("oval", tkey)
	textbox1.set_meta("isnew", isnew)
	textbox1.set_meta("path", tpath)
	textbox1.connect("resized", self, "ui_resize_child_labels", [textbox1])
	textbox1.connect("gui_input", self, "ui_context_menu", [textbox1, "key"])
	textbox1.context_menu_enabled = false
	
	
	dbox.add_child(textbox1)

	var collection_hint 
	var brackets = []
	
	if typeof(tval) == TYPE_DICTIONARY:
		brackets = ["{", "}"]
	elif typeof(tval) == TYPE_ARRAY:
		brackets = ["[", "]"]
	for i in range(0, brackets.size()):
		collection_hint = Label.new()
		collection_hint.text = brackets[i]
		if i == 0:
			collection_hint.align = Label.ALIGN_LEFT
		else:
			collection_hint.align = Label.ALIGN_RIGHT
		collection_hint.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		textbox1.add_child(collection_hint)
		#typehint.set_size(Vector2(100,100))
		
	var textbox2 = LineEdit.new()
	textbox2.name = "textbox_val"
	textbox2.size_flags_horizontal = textbox2.SIZE_EXPAND_FILL
	textbox2.set_text(l.custom_val2str(tval))
	textbox2.set_cursor_position(1337)
	textbox2.editable = editables[1]

	textbox2.set_meta("oval", tval)
	if not isnew:
		textbox2.set_meta("type", typeof(tval))

	if not typeof(tval) in l.supported_type_names.keys():
		textbox2.editable = false
	
	if typeof(tval) in [TYPE_DICTIONARY, TYPE_ARRAY]:
		textbox1.align = LineEdit.ALIGN_CENTER
		textbox2.visible = false

	textbox2.connect("resized", self, "ui_resize_child_labels", [textbox2])
	textbox2.connect("gui_input", self, "ui_context_menu", [textbox2, "val"])
	textbox2.context_menu_enabled = false
	dbox.add_child(textbox2)

	var typehint = Label.new()
	typehint.name = "TYPEHINT"
	typehint.text = l.get_typehint(tval)[0]
	typehint.modulate = l.get_typehint(tval)[1]
	typehint.align = Label.ALIGN_RIGHT
	typehint.size_flags_horizontal = Label.SIZE_EXPAND_FILL
	#typehint.set_size(Vector2(100,100))
	typehint.visible = true
	if isnew:
		typehint.visible = false
	textbox2.add_child(typehint)

	textbox1.connect("text_changed", self, "ui_color_indicate_textbox", [textbox1])
	textbox1.connect("text_entered", self, "update_all_from_ui")
	textbox2.connect("text_changed", self, "ui_color_indicate_textbox", [textbox2])
	textbox2.connect("text_entered", self, "update_all_from_ui")
	
	if not typeof(tkey) in [TYPE_STRING, TYPE_INT]:
		textbox1.editable = false
		textbox2.editable = false
	
	var poppedpath = [] + tpath
	poppedpath.pop_back()
	if isnew and poppedpath == tfocus[0] and tfocus[1] == "new":
		if textbox1.editable:
			textbox1.grab_focus()
		else:
			textbox2.grab_focus()
	else:
		if tpath == tfocus[0]:
			if tfocus[1] == "key":
				textbox1.grab_focus()
			elif tfocus[1] == "val":
				textbox2.grab_focus()
	
	#textbox1.shortcut_keys_enabled = false
	#textbox2.shortcut_keys_enabled = false


func ui_just_make_rootbox(tbox, tname):
	var box = VBoxContainer.new()
	box.name = "RootBox-"+str(tname)
	
	# this is only used for grabbing a new box to focus if the active one was deleted
	box.set_meta("prev_focus_rootbox", prev_focus_rootbox)
	#prev_focus_rootbox.set_meta("next_focus_rootbox", box)
	
	prev_focus_rootbox = box
	box.size_flags_horizontal = box.SIZE_EXPAND_FILL
	tbox.add_child(box)
	return box


func ui_just_make_subboxes(tbox):
	var dbox = HBoxContainer.new()
	dbox.size_flags_horizontal = dbox.SIZE_EXPAND_FILL
	tbox.add_child(dbox)
	var ddbox1 = Panel.new()
	ddbox1.set_custom_minimum_size(Vector2(1,0))
	dbox.add_child(ddbox1)
	var ddbox2 = VBoxContainer.new()
	ddbox2.size_flags_horizontal = ddbox2.SIZE_EXPAND_FILL
	dbox.add_child(ddbox2)

	return ddbox2


func _exit_tree():
	destroy_old()


func destroy_old():
	for n in get_parent().get_children():
		if n.name.substr(0, 12) == "EditorPlugin" and n.get("is_metadata_inspector") == true:
			remove_inspector_plugin(n.plugin)
			remove_control_from_docks(n.metapanel)
			n.call_deferred('free')


func get_plugin_name():
	return "Metadata Inspector"


func count_entries(v, c):
	if typeof(v) in [TYPE_DICTIONARY]:
		for i in v.keys():
			c += count_entries(v[i], 0)
	if typeof(v) in [TYPE_ARRAY]:
		for i in range(0, v.size()):
			c += count_entries(v[i], 0)
	c += 1
	return c



#func _process(delta):
#	fpscounter = (fpscounter + 1)%999999999
#	if fpscounter%30 == 0:
#		print(fpscounter)







#func get_plugin_icon():
   #return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")



# this function is no longer used
#func ui_adddel_button_pressed(button, tpath):
#	if button.text == "+":
#		update_all_from_ui(null)			# TODO: + button, same as ENTER, no specific function?
#	elif button.text == "-":
#		button.set_meta("delete") == true
#		update_all_from_ui(null)
#	else:
#		if IwantConfirmDialogues == true:
#			var reely = ConfirmationDialog.new()
#			reely.dialog_text = "Really delete "+button.text+"?"
#			reely.connect("confirmed", self, "update_all_from_ui")
#			reely.connect("popup_hide", reely, "queue_free")
#			button.get_tree().get_root().add_child(reely)
#			reely.popup_centered()
#		else:
#			update_all_from_ui(null)
