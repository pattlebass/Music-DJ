extends Node

var samples = [[], [], [], []]


func _ready() -> void:
	var midi = MidiFile.new()
	
	var instruments = ["DRUMS.MID", "COMP.MID", "BASS.MID", "ACC.MID"]
	
#	midi.parse("user://ACC.MID")
	
	for i in instruments.size():
		midi.parse("user://" + instruments[i], true)
		
		for track in midi.tracks:
			if not track.notes:
				continue
			samples[i].append(track.notes[0])
	
	print(samples[0].size())
	print(samples[1].size())
	print(samples[2].size())
	print(samples[3].size())
	
#	var buffer = StreamPeerBuffer.new()
#	buffer.big_endian = true
#	buffer.data_array = PoolByteArray([0x0B, 0x71, 0xB0])
#	print(get_u24(buffer))
#
	get_tree().quit()


func int2bin(decimal_value: int) -> String:
	var binary_string = "" 
	var temp 
	var count = 7
	
	if decimal_value > 255:
		count = 15
	elif decimal_value > pow(2, 16) - 1:
		count = 31
	
	while(count >= 0):
		temp = decimal_value >> count 
		if(temp & 1):
			binary_string += "1"
		else:
			binary_string += "0"
		count -= 1
	
	return binary_string


func bin2int(bin_str: String) -> int:
	var out = 0
	
	for c in bin_str:
		out = (out << 1) + int(c == "1")
	
	return out
