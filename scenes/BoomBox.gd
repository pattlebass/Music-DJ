# The audio and song manager
extends Node

var song := [[], [], [], []]
var used_columns := [-1]
var column_index := 15
var is_playing := false

var time_delay: float # in seconds

var bar_length := 3
var sounds := [[0], [0], [0], [0]]

onready var column_container = get_node("/root/main/HBoxContainer/ScrollContainer/HBoxContainer")
onready var audio_players = get_node("/root/main/AudioPlayers")

signal play_started
signal play_ended
signal column_play_started


func _ready() -> void:
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	time_delay = max(0, time_delay)
	
	# Load all sounds
	for instrument in 4:
		for sample in 32:
			sounds[instrument].append(load("res://sounds/%s/%s.ogg" % [instrument, sample + 1]))
	
	connect("play_ended", self, "_on_play_ended")


var time := 0.0
var single := false
var current_column := 0 # Starts at 0

func _process(delta) -> void:
	if not is_playing:
		return
	
	time += delta
	print(time)
	
	if time - time_delay > bar_length:
		# Bar
		print("Current column: ", current_column)
		if current_column > 0:
			column_container.get_child(current_column - 1).end_play()
		
		_play_column(current_column)
		
		current_column += 1
		time -= bar_length
		
		if current_column - 1 >= used_columns[-1] or single:
			is_playing = false
			yield(get_tree().create_timer(bar_length), "timeout")
			emit_signal("play_ended")


func play_song() -> void:
	time = bar_length
	current_column = 0
	is_playing = true
	single = false
	emit_signal("play_started")


func stop() -> void:
	is_playing = false
	emit_signal("play_ended")
	
	for i in audio_players.get_children():
		i.stop()


func play_column(p_column_no) -> void:
	time = bar_length
	current_column = p_column_no
	single = true
	is_playing = true
	emit_signal("play_started")


func _play_column(_column_no) -> void:
	# Visuals
	var column = column_container.get_child(_column_no)
	column.start_play()
	emit_signal("column_play_started", column)
	
	# Play sounds
	for instrument in 4:
		if song[instrument][_column_no] == 0:
			continue
		
		var audio_player = audio_players.get_child(instrument)
		var sound = song[instrument][_column_no]
		audio_player.stream = sounds[instrument][sound]
		audio_player.play()


func set_tile(instrument: int, column_no:int, sample_index: int) -> void:
	BoomBox.song[instrument][column_no] = sample_index
	
	if sample_index == 0:
		# If all buttons in a column are clear remove that column from the play list
		var uses = 0
		for i in 4:
			if BoomBox.song[i][column_no]:
				uses += 1
				break
		if uses == 0:
			BoomBox.used_columns.erase(column_no)
	else:
		if not BoomBox.used_columns.has(column_no):
			BoomBox.used_columns.append(column_no)


func add_column() -> void:
	for i in song:
		i.append(0)


func remove_column(column_no: int) -> void:
	column_index -= 1
	for i in 4:
		song[i].pop_back()
		used_columns.erase(column_no)


func clear_column(column_no: int) -> void:
	used_columns.erase(column_no)
	for i in 4:
		song[i][column_no] = 0


func _on_play_ended() -> void:
	for i in column_container.get_children():
		if i is Column:
			i.end_play()
