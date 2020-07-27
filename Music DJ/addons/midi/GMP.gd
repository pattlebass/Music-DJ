"""
	Godot MIDI Player Plugin by arlez80 (Yui Kinomoto)
"""

tool
extends EditorPlugin

#var sf2_import_plugin

func _enter_tree( ):
	self.add_custom_type( "GodotMIDIPlayer", "AudioStreamPlayer", preload("MidiPlayer.gd"), preload("icon.png") )

	#self.sf2_import_plugin = preload("import/SF2Import.gd").new( )
	#self.add_import_plugin( self.sf2_import_plugin )

func _exit_tree( ):
	self.remove_custom_type( "GodotMIDIPlayer" )
	#self.remove_import_plugin( self.sf2_import_plugin )
	#self.sf2_import_plugin = null

func has_main_screen():
	return true

func make_visible( visible:bool ):
	pass

func get_plugin_name( ):
	return "Godot MIDI Player"
