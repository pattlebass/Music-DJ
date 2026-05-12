class_name Song

const DEFAULT_SIZE = 15

var format := 1
var bpm := 80:
	set(value):
		if value == bpm:
			return
		bpm = value
		bpm_changed.emit()
var data: Array = [[], [], [], []]

signal bpm_changed
signal added_column(column_no: int)
signal removed_column(column_no: int)
signal moved_column(from_no: int, to_no: int)
signal tile_changed(instrument: int, column_no: int, sample_index: int)
signal trimmed_length_changed


func _init() -> void:
	for i in 4:
		data[i].resize(DEFAULT_SIZE)
		data[i].fill(0)


func convert_to_json() -> String:
	return JSON.stringify(
		{
		"format": format,
		"bpm": bpm,
		"data": data
		}
	)


func from(song: Dictionary) -> Song:
	if song.has("format"):
		format = song.format
	if song.has("bpm"):
		bpm = song.bpm
	if song.has("data"):
		data = song.data
		# I hate that I have to do this...
		for instrument in data.size():
			data[instrument] = data[instrument].map(func(sample): return int(sample))
	
	return self


func set_tile(instrument: int, column_no: int, sample_index: int) -> void:
	data[instrument][column_no] = sample_index
	tile_changed.emit(instrument, column_no, sample_index)
	trimmed_length_changed.emit()


func add_column(column_no: int) -> void:
	for i in data:
		i.insert(column_no, 0)
	added_column.emit(column_no)
	trimmed_length_changed.emit()


func remove_column(column_no: int) -> void:
	for i in 4:
		data[i].remove_at(column_no)
	removed_column.emit(column_no)
	trimmed_length_changed.emit()


func duplicate_column(column_no: int) -> void:
	add_column(column_no + 1)
	for instrument in 4:
		set_tile(instrument, column_no + 1, data[instrument][column_no])


func clear_column(column_no: int) -> void:
	for instrument in 4:
		data[instrument][column_no] = 0
		tile_changed.emit(instrument, column_no, 0)
	trimmed_length_changed.emit()


func move_column(from_no: int, to_no: int) -> void:
	for instrument in 4:
		var sample: int = data[instrument][from_no]
		data[instrument].remove_at(from_no)
		data[instrument].insert(to_no, sample)
	moved_column.emit(from_no, to_no)


func get_length() -> int:
	return data[0].size()


func get_trimmed_length() -> int:
	var longest := 0
	for instrument in data:
		for i in instrument.size():
			var sample: int = instrument[i]
			if sample != 0 and i + 1 > longest:
				longest = i + 1
	return longest


## Returns the song duration in seconds
func get_duration() -> float:
	return get_trimmed_length() * 3


func is_column_empty(column_no: int) -> bool:
	var is_empty := true
	
	for i in 4:
		if data[i][column_no]:
			is_empty = false
			break
	
	return is_empty


func save(path: String) -> Error:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(convert_to_json())
	file.close()
	return FileAccess.get_open_error()
