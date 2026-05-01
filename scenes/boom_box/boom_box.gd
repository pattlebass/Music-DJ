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

var sounds := [
	[preload("res://sounds/silence.ogg")],
	[preload("res://sounds/silence.ogg")],
	[preload("res://sounds/silence.ogg")],
	[preload("res://sounds/silence.ogg")]
]

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sync_timer: Timer = $SyncTimer

signal play_started
signal play_ended
signal column_play_started(column_no: int)
signal column_play_ended(column_no: int)

signal bpm_changed
signal song_changed


func _ready() -> void:
	# Load all sounds
	for instrument in 4:
		for sample in 32:
			sounds[instrument].append(load("res://sounds/%s/%s.ogg" % [instrument, sample + 1]))
	
	play_ended.connect(_on_play_ended)
	
	sync_timer.timeout.connect(_on_sync_timer_timeout)


func assemble_song_stream(from: int, to: int) -> void:
	for i in 4:
		var playlist_stream: AudioStreamPlaylist = audio_player.stream.get_sync_stream(i)
		playlist_stream.stream_count = to - from
		for j in range(from, to):
			playlist_stream.set_list_stream(j - from, sounds[i][song.data[i][j]])


var _playing_column_no := 0
func play(from := 0, to := song.get_trimmed_length()) -> void:
	assemble_song_stream(from, to)
	audio_player.play()
	
	is_playing = true
	_playing_column_no = from
	sync_timer.start()
	column_play_started.emit(from)
	play_started.emit()


func stop() -> void:
	is_playing = false
	play_ended.emit()
	audio_player.stop()


func play_column(p_column_no: int) -> void:
	play(p_column_no, p_column_no + 1)


func play_from_column(p_column_no: int) -> void:
	play(p_column_no)


func _on_sync_timer_timeout() -> void:
	if _playing_column_no + 1 >= song.get_trimmed_length():
		sync_timer.stop()
		return
	
	_playing_column_no += 1
	
	if _playing_column_no > 0:
		column_play_ended.emit(_playing_column_no - 1)
	
	column_play_started.emit(_playing_column_no)


func _on_play_ended() -> void:
	# HACK
	for i in song.get_length():
		column_play_ended.emit(i)
	
	sync_timer.stop()


func _on_audio_stream_player_finished() -> void:
	stop()


func convert_project(old_project: String) -> Song:
	# DEPRECATED v1.0-stable: Convert projects
	var file := FileAccess.open(old_project, FileAccess.READ)
	var song2 := Song.new()
	
	var json_song = JSON.parse_string(file.get_as_text())
	
	if json_song == null:
		song2.data = file.get_var()
		return song2
	
	file.close()
	
	if json_song is Array:
		song2.data = json_song
		return song2
	
	if json_song is Dictionary:
		if json_song.format == 1:
			song2.format = json_song.format
			song2.bpm = json_song.bpm
			song2.data = json_song.data
	
	return song2
