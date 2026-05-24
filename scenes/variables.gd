extends Node

const CATEGORY_NAMES: Array[String] = ["Introduction", "Verse", "Chorus", "Solo"]
const INSTRUMENT_NAMES: Array[String] = [
	"INSTRUMENT_DRUMS",
	"INSTRUMENT_BASS",
	"INSTRUMENT_KEYS",
	"INSTRUMENT_TRUMPET"
]
const MINIMUM_DRAG = 100
const MINIMUM_COLUMNS = 1
const VIBRATION_MS = 40

var saves_dir := "user://saves/"
var projects_dir := "user://saves/Projects/"
var opened_file := ""

@onready var main: Control = get_node("/root/Main/")


func _ready() -> void:
	# Make directories
	DirAccess.make_dir_recursive_absolute(projects_dir)
	
	# Demo song
	if not FileAccess.file_exists(projects_dir.path_join("demo.mdj")):
		# HACK: https://github.com/godotengine/godot/issues/741051
		var dir := DirAccess.open("res://")
		dir.copy("res://demo.mdj", projects_dir.path_join("demo.mdj"))
