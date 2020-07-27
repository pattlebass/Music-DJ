extends Node2D




func _on_Button_toggled(button_pressed):
	$AudioStreamPlayer/GodotMIDIPlayer.tempo = 200
	if button_pressed:
		$AudioStreamPlayer/GodotMIDIPlayer.play()
	else:
		$AudioStreamPlayer/GodotMIDIPlayer.stop()
