class_name Song

var format := 1
var bpm := 80
var data := [[], [], [], []]
var used_columns := [-1]


func convert_to_json() -> String:
	return to_json(
		{
		"format": format,
		"bpm": bpm,
		"data": data
		}
	)


func from(song: Dictionary):
	format = song.format
	bpm = song.bpm
	data = song.data
	
	return self


func set_tile(instrument: int, column_no:int, sample_index: int) -> void:
	data[instrument][column_no] = sample_index
	
	if sample_index == 0:
		# If all buttons in a column are clear remove that column from the play list
		var uses = 0
		for i in 4:
			if data[i][column_no]:
				uses += 1
				break
		if uses == 0:
			used_columns.erase(column_no)
	else:
		if not used_columns.has(column_no):
			used_columns.append(column_no)


func add_column() -> void:
	for i in data:
		i.append(0)


func remove_column(column_no: int) -> void:
	for i in 4:
		data[i].pop_back()
		used_columns.erase(column_no)


func clear_column(column_no: int) -> void:
	used_columns.erase(column_no)
	for i in 4:
		data[i][column_no] = 0
