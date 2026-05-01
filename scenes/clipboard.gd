extends Node

class ClipboardTileData:
	var instrument: int
	var sample: int

var _tile_data: ClipboardTileData


func has_tile() -> bool:
	return _tile_data != null


func get_tile() -> ClipboardTileData:
	return _tile_data


func set_tile(p_instrument: int, p_sample: int) -> void:
	_tile_data = ClipboardTileData.new()
	_tile_data.instrument = p_instrument
	_tile_data.sample = p_sample
