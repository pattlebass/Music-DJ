extends Node

const CATEGORY_NAMES: Array[String] = ["Introduction", "Verse", "Chorus", "Solo"]
const INSTRUMENT_NAMES: Array[String] = [
	"INSTRUMENT_DRUMS",
	"INSTRUMENT_BASS",
	"INSTRUMENT_KEYS",
	"INSTRUMENT_TRUMPET"
]
const MINIMUM_DRAG = 100
const MINIMUM_COLUMNS = 15
const VIBRATION_MS = 75
const HOLD_TIME_S = 0.5

var saves_dir := "user://saves/"
var projects_dir := "user://saves/Projects/"
var exports_dir := "user://saves/Exports/"
var opened_file := ""

@onready var main = get_node("/root/Main/")


func _ready() -> void:
	# Set directories
	if OS.get_name() == "Android" and Utils.has_storage_perms():
		exports_dir = OS.get_system_dir(OS.SYSTEM_DIR_MUSIC).path_join("MusicDJ")
	
	# Make directories
	DirAccess.make_dir_recursive_absolute(projects_dir)
	DirAccess.make_dir_recursive_absolute(exports_dir)
	
	# Demo song
	if not FileAccess.file_exists(projects_dir.path_join("Demo.mdj")):
		DirAccess.copy_absolute("res://demo.mdj", projects_dir.path_join("Demo.mdj"))
