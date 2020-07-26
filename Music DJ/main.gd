extends Control

var song = [[], [], [], []]
var can_play = true
var last_columns = [-1]

func _ready():
	var step_scene = preload("res://Step.tscn")
	for i in 25:
		var step = step_scene.instance()
		step.get_node("Label").text = str(i + 1)
		get_node("HBoxContainer/StepContainer/HBoxContainer").add_child(step)
		
		# Signals
		step.get_node("Button1").connect("pressed", self, "button", [i, 0])
		step.get_node("Button2").connect("pressed", self, "button", [i, 1])
		step.get_node("Button3").connect("pressed", self, "button", [i, 2])
		step.get_node("Button4").connect("pressed", self, "button", [i, 3])
		
		
		for g in song:
			g.append(0)


func _process(delta):
	pass


func play():
	yield(get_tree(), "idle_frame")
	$SoundDialog/AudioStreamPlayer.stop()
	for i in 25:
		if i > last_columns.back():
			$HBoxContainer2/Play.pressed = false
			return
		
		if not can_play:
			return
		
		# Visuals
		var step = get_node("HBoxContainer/StepContainer/HBoxContainer").get_child(i)
		step.get_node("Label").add_color_override("font_color", Color(1,0,0))
		
		# Play sounds
		for a in 4:
			if not can_play:
				return
			if song[a][i] == 0:
				continue
			var audio_player = $AudioPlayers.get_child(a)
			var sound = song[a][i]
			audio_player.stream = load("res://sounds/"+str(a)+"/"+str(sound)+".wav")
			audio_player.play()
		
		yield(get_tree().create_timer(3), "timeout")
		step.get_node("Label").add_color_override("font_color", Color(1,1,1))

func button(_column, _instrument):
	$SoundDialog.instrument_index = _instrument
	$SoundDialog.column = _column
	$SoundDialog.popup_centered(Vector2(500, 550))


func _on_Play_toggled(button_pressed):
	if button_pressed:
		can_play = true
		play()
		$HBoxContainer2/Play.text = "Stop"
	else:
		can_play = false
		$HBoxContainer2/Play.text = "Play"


func _on_Export_pressed():
	if  last_columns.back() != -1:
		$SaveDialog.title = "Export song as"
		$SaveDialog.type_of_save = "export"
		$SaveDialog.popup_centered()


func _on_SaveProject_pressed():
	if  last_columns.back() != -1:
		$SaveDialog.title = "Save project as"
		$SaveDialog.type_of_save = "project"
		$SaveDialog.popup_centered()


func _on_OpenProject_pressed():
	$LoadDialog.popup_centered()
