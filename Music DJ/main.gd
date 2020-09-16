extends Control

var song = [[], [], [], []]
var can_play = true
var last_columns = [-1]
var column_index = 15
var user_dir = ""

# Notes:
# * "column" refers to the column node itself, while "column_no" refers
# to the column as a number
# * A few variables/nodes need renaming (column -> column_no, step -> column)
# * Some signals are a bit messy

# To do:
# * In-app tutorial


func _ready():
	var column_scene = preload("res://Column.tscn")
	for i in column_index:
		var column = column_scene.instance()
		column.get_node("Label").text = str(i + 1)
		get_node("HBoxContainer/StepContainer/HBoxContainer").add_child(column)
		
		# Signals
		for b in 4:
			var button = column.get_node("Button"+str(b+1))
			button.connect("pressed", self, "on_Tile_pressed", [i, b])
			button.connect("button_down", self, "on_Tile_held", [i, b, column.get_node("Button"+str(b+1))])
		column.get_node("Label").connect("pressed", self, "on_Column_Button_pressed", [i, column])
		
		# Add to song
		for g in song:
			g.append(0)
	
	var add_button = get_node("HBoxContainer/StepContainer/HBoxContainer/VBoxContainer")
	$HBoxContainer/StepContainer/HBoxContainer.move_child(add_button, column_index+1)

	if OS.get_name() == "Android":
		user_dir = "/storage/emulated/0/MusicDJ/"
		var dir = Directory.new()
		dir.open("/storage/emulated/0/")
		dir.make_dir("MusicDJ")
		dir.open(user_dir)
		dir.make_dir("Projects")
		dir.make_dir("Exports")
		
	else:
		user_dir = "res://saves/"


func play():
	yield(get_tree(), "idle_frame")
	$SoundDialog/AudioStreamPlayer.stop()
	for i in column_index:
		if i > last_columns.back():
			$HBoxContainer2/Play.pressed = false
			return
		
		if not can_play:
			return
		
		# Visuals
		var column = get_node("HBoxContainer/StepContainer/HBoxContainer").get_child(i)
		column.get_node("Label").add_color_override("font_color", Color(1,0,0))
		
		# Play sounds
		for a in 4:
			if song[a][i] == 0:
				continue
			#if not can_play:
			#	return
				
			var audio_player = $AudioPlayers.get_child(a)
			var sound = song[a][i]
			audio_player.stream = load("res://sounds/"+str(a)+"/"+str(sound)+".wav")
			audio_player.play()
		
		yield(get_tree().create_timer(3), "timeout")
		column.get_node("Label").add_color_override("font_color", Color(1,1,1))
		
		if i >= last_columns.back():
			$HBoxContainer2/Play.pressed = false
			return
		
		
func on_Tile_pressed(_column_no, _instrument):
	$SoundDialog.instrument_index = _instrument
	$SoundDialog.column_no = _column_no
	$SoundDialog.popup_centered(Vector2(500, 550))


func on_Tile_held(_column_no, _instrument, _button):
	# Needs cleanup
	yield(get_tree().create_timer(0.5), "timeout")
	if _button.pressed and _button.text != "":
		_button.disabled = true
		_button.disabled = false
		
		$HBoxContainer/StepContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var float_button_scene = preload("res://FloatButton.tscn")
		var float_button_parent = float_button_scene.instance()
		
		float_button_parent.add_child(_button.duplicate())
		
		var float_button = float_button_parent.get_child(1)
		
		var rect_size = float_button.rect_size
		
		float_button.get_node("Area2D").queue_free()
		float_button.rect_position = -rect_size*1.5/2
		float_button.rect_size = rect_size * 1.5
		float_button.set("custom_colors/font_color", Color.black)
		float_button_parent.instrument = _instrument
		float_button_parent.column_no = _column_no
		float_button_parent.global_position = get_global_mouse_position()
		add_child(float_button_parent)
		var rect_global_pos = _button.rect_global_position
		float_button_parent.pos_y = rect_global_pos.y


func on_Column_Button_pressed(_column_no, _column):
	$ColumnDialog.column = _column
	$ColumnDialog.column_no = _column_no
	
	$ColumnDialog.popup()
	var label = _column.get_node("Label")
	var pos = label.rect_global_position
	pos.x -= $ColumnDialog.rect_size.x/2 - label.rect_size.x/2
	pos.y += label.rect_size.x
	$ColumnDialog.rect_global_position = pos


func _on_Play_toggled(button_pressed):
	if button_pressed:
		can_play = true
		play()
		$HBoxContainer2/Play.text = "Stop"
	else:
		can_play = false
		$HBoxContainer2/Play.text = "Play"
		
		yield(get_tree(), "idle_frame")
		for i in $AudioPlayers.get_children():
			i.stop()


func _on_Export_pressed():
	if  last_columns.back() != -1:
		$SaveDialog.title = "Export song as"
		$SaveDialog.type_of_save = "export"
		$SaveDialog.popup_centered()


func _on_SaveProject_pressed():
	$SaveDialog.title = "Save project as"
	$SaveDialog.type_of_save = "project"
	$SaveDialog.popup()


func _on_OpenProject_pressed():
	$LoadDialog.popup_centered()


func _on_AddButton_pressed():
	var column_scene = preload("res://Column.tscn")
	var column = column_scene.instance()
	
	# Signals
	for b in 4:
		var button = column.get_node("Button"+str(b+1))
		button.connect("pressed", self, "on_Tile_pressed", [column_index, b])
		button.connect("button_down", self, "on_Tile_held", [column_index, b, column.get_node("Button"+str(b+1))])
	column.get_node("Label").connect("pressed", self, "on_Column_Button_pressed", [column_index, column])
	
	# Add to song
	for g in song:
		g.append(0)
	
	column_index += 1
	column.get_node("Label").text = str(column_index)
	get_node("HBoxContainer/StepContainer/HBoxContainer").add_child(column)
	
	
	var add_button = get_node("HBoxContainer/StepContainer/HBoxContainer/VBoxContainer")
	$HBoxContainer/StepContainer/HBoxContainer.move_child(add_button, column_index+1)
	
	column.get_node("AnimationPlayer").play("fade_in")
