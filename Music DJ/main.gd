extends Control

var song = [[], [], [], []]
var can_play = true
var last_columns = [-1]
var column_index = 15
var user_dir = ""
var is_playing = false

# Notes:
# * "column" refers to the column node itself, while "column_no" refers
# to the column as a number
# * A few variables/nodes need renaming (column -> column_no, step -> column)
# * Some signals are a bit messy


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
		yield(get_tree(), "idle_frame")
		OS.request_permissions()
		
		user_dir = "/storage/emulated/0/MusicDJ/"
		var dir = Directory.new()
		dir.open("/storage/emulated/0/")
		dir.make_dir("MusicDJ")
		dir.open(user_dir)
		dir.make_dir("Projects")
		dir.make_dir("Exports")
		
	else:
		var dir = Directory.new()
		dir.open("user://")
		dir.make_dir("saves")
		dir.open("user://saves")
		dir.make_dir("Exports")
		dir.make_dir("Projects")
		user_dir = "user://saves/"


func play_song():
	is_playing = true
	yield(get_tree(), "idle_frame")
	$SoundDialog/AudioStreamPlayer.stop()
	for i in column_index:
		play_column(i, false)
		yield(get_tree().create_timer(3), "timeout")
		var column = get_node("HBoxContainer/StepContainer/HBoxContainer").get_child(i)
		column.get_node("Label").add_color_override("font_color", Color(1,1,1))
	
		if i >= last_columns.back():
			$HBoxContainer2/Play.pressed = false
			can_play = true
			is_playing = false
			return
		
		
func play_column(_column_no, _single):
	is_playing = true
	
	if _column_no > last_columns.back():
		$HBoxContainer2/Play.pressed = false
		return
	
	if not can_play:
		return
	
	# Visuals
	var column = get_node("HBoxContainer/StepContainer/HBoxContainer").get_child(_column_no)
	column.get_node("Label").add_color_override("font_color", Color(1,0,0))
	
	# Play sounds
	for a in 4:
		if song[a][_column_no] == 0:
			continue
		#if not can_play:
		#	return
			
		var audio_player = $AudioPlayers.get_child(a)
		var sound = song[a][_column_no]
		audio_player.stream = load("res://sounds/"+str(a)+"/"+str(sound)+".wav")
		audio_player.play()
	# Needs cleanup
	yield(get_tree().create_timer(3), "timeout")
	column.get_node("Label").add_color_override("font_color", Color(1,1,1))
		
	if _single:
		can_play = true
		is_playing = false
		
		
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
	
	var label = _column.get_node("Label")
	var pos = label.rect_global_position
	pos.x -= $ColumnDialog.rect_size.x/2 - label.rect_size.x/2
	pos.y += label.rect_size.x
	var viewport_size = get_viewport().get_visible_rect().size
	var pos_plus_size = pos+$ColumnDialog.rect_size+Vector2(16,16)
	var pos_minus_size = pos-$ColumnDialog.rect_size-Vector2(16,16)
	if pos_plus_size.x > viewport_size.x:
		pos.x -= pos_plus_size.x - viewport_size.x
	elif pos.x < 0:
		pos.x = 0 + 16
		
	$ColumnDialog.rect_global_position = pos
	
	var sprite = $ColumnDialog.get_node("Sprite")
	var sprite_pos_x = label.rect_global_position.x + label.rect_size.x/2
	sprite.global_position.x = sprite_pos_x
	
	
	$ColumnDialog.popup()


func _on_Play_toggled(button_pressed):
	if button_pressed:
		can_play = true
		play_song()
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
	
	
func _process(delta):
	if last_columns.back() == -1:
		$HBoxContainer2/Play.disabled = true
		$HBoxContainer2/Export.disabled = true
		$HBoxContainer2/SaveProject.disabled = true
	else:
		$HBoxContainer2/Play.disabled = false
		$HBoxContainer2/Export.disabled = false
		$HBoxContainer2/SaveProject.disabled = false
		
		if is_playing:
			$HBoxContainer2/Export.disabled = true
		else:
			$HBoxContainer2/Export.disabled = false
