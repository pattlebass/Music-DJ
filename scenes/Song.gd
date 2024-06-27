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
signal changed


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
	
	return self


func set_tile(instrument: int, column_no: int, sample_index: int) -> void:
	data[instrument][column_no] = sample_index
	changed.emit()


func add_column() -> void:
	for i in data:
		i.append(0)
	changed.emit()


func remove_column(column_no: int) -> void:
	for i in 4:
		data[i].pop_back()
	changed.emit()


func clear_column(column_no: int) -> void:
	for i in 4:
		data[i][column_no] = 0
	changed.emit()


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
