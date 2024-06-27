## The audio and song manager
extends Node

var song: Song:
	set(value):
		if song == value:
			return
		song = value
		song.bpm_changed.connect(bpm_changed.emit)
		song.changed.connect(song_changed.emit)
var is_playing := false

var time_delay: float # in seconds

var bar_length := 3.0
var sounds := [[0], [0], [0], [0]]

@onready var column_container = Variables.main.column_container
@onready var audio_players = Variables.main.get_node("AudioPlayers")

signal play_started
signal play_ended
signal column_play_started

signal bpm_changed
signal song_changed


func _ready() -> void:
	while !column_container:
		column_container = Variables.main.column_container
		await get_tree().process_frame
	
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	time_delay = max(0, time_delay)
	
	# Load all sounds
	for instrument in 4:
		for sample in 32:
			sounds[instrument].append(load("res://sounds/%s/%s.ogg" % [instrument, sample + 1]))
	
	play_ended.connect(_on_play_ended)


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
		
		if current_column >= song.get_trimmed_length() - 1 or single:
			is_playing = false
			await get_tree().create_timer(bar_length).timeout
			play_ended.emit()
		
		current_column += 1
		time -= bar_length


func play_song() -> void:
	update_pitch()
	time = bar_length
	current_column = 0
	is_playing = true
	single = false
	play_started.emit()


func stop() -> void:
	is_playing = false
	play_ended.emit()
	
	for i in audio_players.get_children():
		i.stop()


func play_column(p_column_no) -> void:
	update_pitch()
	time = bar_length
	current_column = p_column_no
	single = true
	is_playing = true
	play_started.emit()


func play_from_column(p_column_no) -> void:
	update_pitch()
	time = bar_length
	current_column = p_column_no
	single = false
	is_playing = true
	play_started.emit()


func _play_column(p_column_no) -> void:
	# Visuals
	var column = column_container.get_child(p_column_no)
	column.start_play()
	column_play_started.emit(column)
	
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
	var file := FileAccess.open(old_project, FileAccess.READ)
	var song := Song.new()
	
	var json_song = JSON.parse_string(file.get_as_text())
	
	if json_song == null:
		song.data = file.get_var()
		return song
	
	file.close()
	
	if json_song is Array:
		song.data = json_song
		return song
	
	if json_song is Dictionary:
		if json_song.format == 1:
			song.format = json_song.format
			song.bpm = json_song.bpm
			song.data = json_song.data
	
	return song
