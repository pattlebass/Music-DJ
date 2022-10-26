class_name MidiFile

"""
This is a MIDI parser specifically designed for MusicDJ files.

Made by Fabian S. (@pattlebass) with the help of javidx9's tutorial.

Links:
Tutorial: https://www.youtube.com/watch?v=040BKtnDdg0
C++: https://github.com/OneLoneCoder/olcPixelGameEngine/blob/master/Videos/OneLoneCoder_PGE_MIDI.cpp
Midi Spec: http://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html
"""

class MidiEvent:
	enum Type {
		NOTE_OFF,
		NOTE_ON,
		OTHER,
	}
	
	var type
	var key = 0
	var velocity = 0
	var delta_tick = 0

class MidiNote:
	var key = 0
	var velocity = 0
	var start_time = 0
	var duration = 0
	
	func equal_to(note: MidiNote) -> bool:
		return key == note.key and velocity == note.velocity \
				and start_time == note.start_time and duration == note.duration

class MidiTrack:
	var track_name: String
	var instrument: String
	var events := []
	var notes := []


enum Events {
	VOICE_NOTE_OFF = 0x80,
	VOICE_NOTE_ON = 0x90,
	VOICE_AFTERTOUCH = 0xA0,
	VOICE_CONTROL_CHANGE = 0xB0,
	VOICE_PROGRAM_CHANGE = 0xC0,
	VOICE_CHANNEL_PRESSURE = 0xD0,
	VOICE_PITCH_BEND = 0xE0,
	VOICE_SYSTEM_EXCLUSIVE = 0xF0,
}

enum MetaEvents {
	MetaSequence = 0x00,
	MetaText = 0x01,
	MetaCopyright = 0x02,
	MetaTrackName = 0x03,
	MetaInstrumentName = 0x04,
	MetaLyrics = 0x05,
	MetaMarker = 0x06,
	MetaCuePoint = 0x07,
	MetaChannelPrefix = 0x20,
	MetaEndOfTrack = 0x2F,
	MetaSetTempo = 0x51,
	MetaSMPTEOffset = 0x54,
	MetaTimeSignature = 0x58,
	MetaKeySignature = 0x59,
	MetaSequencerSpecific = 0x7F,
}

var tracks := []
var tempo = 0
var bpm = 0


func parse(path: String, silent := false) -> void:
	tracks = []
	tempo = 0
	bpm = 0
	
	var file := File.new()
	file.open(path, File.READ_WRITE)
	
	var buffer := StreamPeerBuffer.new()
	buffer.data_array = file.get_buffer(file.get_len())
	buffer.big_endian = true
	
	file.close()
	
	# Header chunk
	var file_id = buffer.get_utf8_string(4)
	var header_length = buffer.get_u32()
	var format = buffer.get_u16()
	var no_tracks = buffer.get_u16()
	var divisions_word = buffer.get_u16()
	var divisions_format = divisions_word & 0x8000
	
	if buffer.get_utf8_string(4).begins_with("SEM"):
		if not silent:
			print("---SEM---")
		var sem1_length = buffer.get_32()
		buffer.seek(buffer.get_position() + sem1_length)
	
	for chunk in no_tracks:
		if not silent:
			print("---Track %s---" % chunk)
		var track_id = buffer.get_utf8_string(4)
		var track_length = buffer.get_u32()
		
		var end_of_track := false
		var previous_status := 0
		
		tracks.append(MidiTrack.new())
		
		# Proccess the events
		while not (end_of_track or buffer.get_position() == buffer.get_size() - 1):
			var status_time_delta = read_value(buffer)
			var status = buffer.get_u8()
			if status < 128:
				status = previous_status
				buffer.seek(buffer.get_position() - 1)
			
			match (status & 0xF0): # Compare only first 4 bits
				Events.VOICE_NOTE_OFF:
					previous_status = status
					var channel = status & 0x0f # Last 4 bits
					var note_id = buffer.get_u8()
					var note_velocity = buffer.get_u8()
					
					var event = MidiEvent.new()
					tracks[chunk].events.append(event)
					event.type = MidiEvent.Type.NOTE_OFF
					event.key = note_id
					event.velocity = note_velocity
					event.delta_tick = status_time_delta
				
				Events.VOICE_NOTE_ON:
					previous_status = status
					var channel = status & 0x0f # Last 4 bits
					var note_id = buffer.get_u8()
					var note_velocity = buffer.get_u8()
					
					var event = MidiEvent.new()
					tracks[chunk].events.append(event)
					event.key = note_id
					event.velocity = note_velocity
					event.delta_tick = status_time_delta
					
					if note_velocity == 0:
						event.type = MidiEvent.Type.NOTE_OFF
					else:
						event.type = MidiEvent.Type.NOTE_ON
				
				Events.VOICE_AFTERTOUCH:
					previous_status = status
					var channel = status & 0x0f # Last 4 bits
					var note_id = buffer.get_u8()
					var note_velocity = buffer.get_u8()
					
					var event = MidiEvent.new()
					tracks[chunk].events.append(event)
					event.type = MidiEvent.Type.OTHER
				
				Events.VOICE_CONTROL_CHANGE:
					previous_status = status
					var channel = status & 0x0f # Last 4 bits
					var control_id = buffer.get_u8()
					var control_value = buffer.get_u8()
					
					var event = MidiEvent.new()
					tracks[chunk].events.append(event)
					event.type = MidiEvent.Type.OTHER
				
				Events.VOICE_PROGRAM_CHANGE:
					previous_status = status
					var channel = status & 0x0f # Last 4 bits
					var program_id = buffer.get_u8()
					
					var event = MidiEvent.new()
					tracks[chunk].events.append(event)
					event.type = MidiEvent.Type.OTHER
				
				Events.VOICE_CHANNEL_PRESSURE:
					previous_status = status
					var channel = status & 0x0f # Last 4 bits
					var channel_pressure = buffer.get_u8()
					
					var event = MidiEvent.new()
					tracks[chunk].events.append(event)
					event.type = MidiEvent.Type.OTHER
				
				Events.VOICE_PITCH_BEND:
					previous_status = status
					var channel = status & 0x0f # Last 4 bits
					var LS7B = buffer.get_u8()
					var MS7B = buffer.get_u8()
					
					var event = MidiEvent.new()
					tracks[chunk].events.append(event)
					event.type = MidiEvent.Type.OTHER
				
				Events.VOICE_SYSTEM_EXCLUSIVE:
					previous_status = 0
					
					if status == 0xFF:
						# Meta message
						var type = buffer.get_u8()
						var length = read_value(buffer)
						
						match type:
							MetaEvents.MetaTrackName:
								tracks[chunk].track_name = buffer.get_utf8_string(length)
							MetaEvents.MetaInstrumentName:
								tracks[chunk].instrument = buffer.get_utf8_string(length)
							MetaEvents.MetaEndOfTrack:
								end_of_track = true
							MetaEvents.MetaSetTempo:
								# Tempo is in microseconds per quarter note
								if tempo == 0:
									tempo = get_u24(buffer)
									bpm = 60_000_000 / tempo
									if not silent:
										print("Set tempo: %s" % tempo)
										print("Set bpm: %s" % bpm)
							_:
								buffer.seek(buffer.get_position() + length)
				_:
					# Unrecognized byte
					pass
	
	# Convert events to notes
	# HACK: Convert delta time to real time
	for track in tracks:
		var real_time = 0
		
		var notes_processing = []
		
		for event in track.events:
			real_time += event.delta_tick
			
			if event.type == MidiEvent.Type.NOTE_ON:
				var note = MidiNote.new()
				note.key = event.key
				note.velocity = event.velocity
				note.start_time = real_time
				notes_processing.append(note)
			elif event.type == MidiEvent.Type.NOTE_OFF:
				for note in notes_processing:
					if note.key == event.key:
						note.duration = real_time - note.start_time
						track.notes.append(note)
						notes_processing.erase(note)
	
#	for i in tracks[2].notes:
#		print("Time: %s | Vel: %s | Key: %s | Dur: %s" % [i.start_time, i.velocity, i.key, i.duration])
	
	# duration:383, key:75, start_time:0, velocity:77
#	print(inst2dict(tracks[1].notes[0]))
	
	pass


func from_mdj(song):
	var buffer := StreamPeerBuffer.new()
	buffer.big_endian = true
	
	# MThd header
	var mtdh_buffer := StreamPeerBuffer.new()
	mtdh_buffer.big_endian = true
	mtdh_buffer.put_data("MThd".to_ascii())
	mtdh_buffer.put_32(6) # header length
	mtdh_buffer.put_16(1) # format
	mtdh_buffer.put_16(2) # number of tracks
	mtdh_buffer.put_16(0x00C0) # divisions format
	var mthd = mtdh_buffer.data_array
	
	# Sem1
	var sem1 = PoolByteArray([0x53, 0x45, 0x4D, 0x31])
	
	var sem1_data = PoolByteArray()
	for instrument in 4:
		for column in song[instrument].size():
			var rest_of_song = song[instrument].slice(column, song[instrument].size()-1)
			if rest_of_song.count(0) != rest_of_song.size():
				var sample = song[instrument][column]
				sem1_data.append(sample)
				sem1_data.append((sample - 1) / 8)
		sem1_data.append(255)
	
	var sem1_size = PoolByteArray([0x0, 0x0, 0x0, sem1_data.size() + 2]) # 2 = checksum
	
	sem1.append_array(sem1_size)
	sem1.append_array(sem1_data)
	var sem1_checksum = crc16(sem1)
	sem1.append_array(sem1_checksum)
	
	buffer.put_data(mthd)
	buffer.put_data(sem1)
	
	return buffer.data_array


static func to_mdj(midi_path):
	var song = [[], [], [], []]
	
	var file := File.new()
	file.open(midi_path, File.READ_WRITE)
	
	var buffer := StreamPeerBuffer.new()
	buffer.data_array = file.get_buffer(file.get_len())
	buffer.big_endian = true
	
	file.close()
	
	# Header chunk
	var file_id = buffer.get_utf8_string(4)
	var header_length = buffer.get_u32()
	var format = buffer.get_u16()
	var no_tracks = buffer.get_u16()
	var divisions_word = buffer.get_u16()
	var divisions_format = divisions_word & 0x8000
	
	if buffer.get_utf8_string(4).begins_with("SEM"):
		var sem1_length = buffer.get_32()
		
		var instrument = 0
		
		while instrument < 4:
			if buffer.get_u8() == 0xFF:
				instrument += 1
				continue
			
			buffer.seek(buffer.get_position() - 1)
			
			var sample = buffer.get_u8()
			var category = buffer.get_u8()
			
			song[instrument].append(sample)
	else:
		return song
	
	var max_columns = 15
	for instrument in 4:
		if song[instrument].size() > max_columns:
			max_columns = song[instrument].size()
	
	for instrument in 4:
		for i in max_columns - song[instrument].size():
			song[instrument].append(0)
	
	return song


func read_value(buffer: StreamPeerBuffer) -> int:
	var value :=0
	var byte := 0
	
	# Read byte
	value = buffer.get_u8()
	
	# Check MSB (most significant byte), if set, more bytes need reading
	if value & 0x80:
		value &= 0x7F
		
		# No do while :(
		byte = buffer.get_u8()
		value = (value << 7) | (byte & 0x7F)
		
		while byte & 0x80: # Loop whilst read byte MSB is 1
			# Read next byte
			byte = buffer.get_u8()
			
			# Construct value by setting bottom 7 bits, then shifting 7 bits
			value = (value << 7) | (byte & 0x7F)
		
	return value


func get_u24(buffer: StreamPeerBuffer) -> int:
	var value := 0
	value |= buffer.get_u8() << 16
	value |= buffer.get_u8() << 8
	value |= buffer.get_u8() << 0
	return value


# Adapted from https://gist.github.com/pintoXD/a90e398bba5a1b6c121de4e1265d9a29
func crc16(data: PoolByteArray, big_endian := true):
	var crc = 0x0000
	
	for i in data.size():
		crc ^= data[i]
		for j in 8:
			if (crc & 0x0001) > 0:
				crc = (crc >> 1) ^ 0xA001
			else:
				crc = crc >> 1
	var stream = StreamPeerBuffer.new()
	stream.big_endian = big_endian
	stream.put_16(crc)
	
	return stream.data_array
