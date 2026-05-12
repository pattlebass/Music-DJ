extends Node

var _tile_data: SongTileData


func has_tile() -> bool:
	return _tile_data != null


func get_tile() -> SongTileData:
	return _tile_data


func set_tile(p_instrument: int, p_sample: int) -> void:
	_tile_data = SongTileData.new(p_instrument, p_sample)
