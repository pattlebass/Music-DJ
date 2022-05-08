extends HBoxContainer


func _ready():
	var path = "res://assets/themes/%s/" % Variables.options.theme
	$DownloadButton.icon = load(path+"download.png")
	$DeleteButton.icon = load(path+"delete.png")
