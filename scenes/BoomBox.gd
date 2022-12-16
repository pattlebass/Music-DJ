# The audio and song manager
extends Node

var song := Song.new()
var is_playing := false

var time_delay: float # in seconds

var bar_length: float = 3.0
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
#	print(time)
	
	if time - time_delay > bar_length:
		# Bar
#		print("Current column: ", current_column)
		if current_column > 0:
			column_container.get_child(current_column - 1).end_play()
		
		_play_column(current_column)
		
		current_column += 1
		time -= bar_length
		
		if current_column - 1 >= song.used_columns[-1] or single:
			is_playing = false
			yield(get_tree().create_timer(bar_length), "timeout")
			emit_signal("play_ended")


func play_song() -> void:
	update_pitch()
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
	update_pitch()
	time = bar_length
	current_column = p_column_no
	single = true
	is_playing = true
	emit_signal("play_started")


func _play_column(p_column_no) -> void:
	# Visuals
	var column = column_container.get_child(p_column_no)
	column.start_play()
	emit_signal("column_play_started", column)
	
	# Play sounds
	for instrument in 4:
		if song.data[instrument][p_column_no] == 0:
			continue
		
		var audio_player = audio_players.get_child(instrument)
		var sound = song.data[instrument][p_column_no]
		audio_player.pitch_scale = song.bpm / 80.0
		audio_player.stream = sounds[instrument][sound]
		audio_player.play()


func _on_play_ended() -> void:
	for i in column_container.get_children():
		if i is Column:
			i.end_play()


func update_pitch() -> void:
	bar_length = (60.0/song.bpm) * 4
	
	var pitch = song.bpm / 80.0
	var shift = AudioServer.get_bus_effect(0, 1)
	shift.pitch_scale = 1.0 / pitch
	
	AudioServer.set_bus_effect_enabled(0, 1, shift.pitch_scale != 1)


func convert_project(old_project: String) -> Song:
	# DEPRECATED v1.0-stable: Convert projects
	var file := File.new()
	file.open(old_project, File.READ)
	var song := Song.new()
	
	var json_result = JSON.parse(file.get_as_text())
	
	if json_result.error:
		song.data = file.get_var()
		return song
	
	file.close()
	
	if json_result.result is Array:
		song.data = json_result.result
		return song
	
	if json_result.result is Dictionary:
		if json_result.result.format == 1:
			song.format = json_result.result.format
			song.bpm = json_result.result.bpm
			song.data = json_result.result.data
	
	return song
