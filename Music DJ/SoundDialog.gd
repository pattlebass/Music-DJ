extends WindowDialog

var instrument

func _on_SoundDialog_about_to_show():
	$VBoxContainer/ItemList.clear()
	for i in 32:
		$VBoxContainer/ItemList.add_item(str(instrument) + " " + str(i+1))


func _on_ItemList_item_selected(index):
	$AudioStreamPlayer.stream = load("res://sounds/"+str(instrument*index)+".wav")
	$AudioStreamPlayer.play()
