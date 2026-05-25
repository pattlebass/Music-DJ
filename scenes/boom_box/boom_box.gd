## The audio and song manager
extends Node

const MAX_UNDO_SIZE := 30

var song: Song

var is_playing := false
var undo_stack: Array[Song] = []
var redo_stack: Array[Song] = []

var sounds := [
	[preload("res://sounds/silence.ogg")],
	[preload("res://sounds/silence.ogg")],
	[preload("res://sounds/silence.ogg")],
	[preload("res://sounds/silence.ogg")]
]

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var preview_player: AudioStreamPlayer = $PreviewStreamPlayer
@onready var sync_timer: Timer = $SyncTimer

signal play_started
signal play_ended
signal column_play_started(column_no: int)
signal column_play_ended(column_no: int)

signal song_loaded(is_undo: bool)

signal history_changed


func _ready() -> void:
	# Load all sounds
	for instrument in 4:
		for sample in 32:
			sounds[instrument].append(load("res://sounds/%s/%s.ogg" % [instrument, sample + 1]))
	
	play_started.connect(_on_play_started)
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


func play_preview_sample(instrument: int, sample: int) -> void:
	preview_player.stream = sounds[instrument][sample]
	preview_player.play()


func load_song(p_song: Song) -> void:
	undo_stack.clear()
	redo_stack.clear()
	history_changed.emit()
	_load_song(p_song, false)


func _load_song(p_song: Song, is_undo: bool) -> void:
	if song != null:
		song.disconnect_all()
	
	p_song.about_to_change.connect(
		func():
			undo_stack.append(p_song.duplicate())
			if undo_stack.size() > MAX_UNDO_SIZE:
				undo_stack.pop_front()
			redo_stack.clear()
			history_changed.emit()
	)
	
	song = p_song
	song_loaded.emit(is_undo)


func undo() -> void:
	if not can_undo():
		return
	
	redo_stack.append(song)
	_load_song(undo_stack.pop_back(), true)
	history_changed.emit()


func redo() -> void:
	if not can_redo():
		return
	
	undo_stack.append(song)
	_load_song(redo_stack.pop_back(), true)
	history_changed.emit()


func can_undo() -> bool:
	return not undo_stack.is_empty()


func can_redo() -> bool:
	return not redo_stack.is_empty()


func _on_sync_timer_timeout() -> void:
	if _playing_column_no + 1 >= song.get_trimmed_length():
		sync_timer.stop()
		return
	
	_playing_column_no += 1
	
	if _playing_column_no > 0:
		column_play_ended.emit(_playing_column_no - 1)
	
	column_play_started.emit(_playing_column_no)


func _on_play_started() -> void:
	preview_player.stop()


func _on_play_ended() -> void:
	# HACK
	for i in song.get_length():
		column_play_ended.emit(i)
	
	sync_timer.stop()


func _on_audio_stream_player_finished() -> void:
	stop()


func convert_project(old_project: String) -> Song:
	# DEPRECATED v2.0: Convert projects
	var file := FileAccess.open(old_project, FileAccess.READ)
	var song2 := Song.new()
	
	var json_song = JSON.parse_string(file.get_as_text())
	
	if json_song == null:
		# TODO: Create method to check if file is valid instead of returning empty song
		var err_msg := "File (%s) is not json format." % old_project
		printerr(err_msg)
		Utils.toast(err_msg)
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
