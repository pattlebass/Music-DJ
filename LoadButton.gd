extends HBoxContainer


func _ready():
	var path = "res://assets/themes/%s/" % GlobalVariables.options.theme
	$DownloadButton.icon = load(path+"download.png")
	$DeleteButton.icon = load(path+"delete.png")
