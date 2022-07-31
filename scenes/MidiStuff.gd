extends Node

func _ready() -> void:
	var midi = MidiFile.new()
	
	midi.parse_file("user://13-mod.mid")
	
#	var buffer = StreamPeerBuffer.new()
#	buffer.big_endian = true
#	buffer.data_array = PoolByteArray([0x0B, 0x71, 0xB0])
#	print(get_u24(buffer))
#
	get_tree().quit()
