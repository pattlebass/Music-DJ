extends HBoxContainer


func _ready():
	var path = "res://assets/themes/%s/" % Variables.options.theme
	$DownloadButton.icon = load(path+"download.svg")
	$DeleteButton.icon = load(path+"delete.svg")
