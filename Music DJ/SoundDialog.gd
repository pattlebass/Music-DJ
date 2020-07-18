extends WindowDialog

onready var main = get_parent()

var instrument_index
var column

func _on_SoundDialog_about_to_show():
	$VBoxContainer/ItemList.clear()
	var instrument
	if instrument_index == 0:
		instrument = "Drums"
	elif instrument_index == 1:
		instrument = "Guitar"
	elif instrument_index == 2:
		instrument = "Keys"
	elif instrument_index == 3:
		instrument = "Trumpet"
	
	for i in 32:
		$VBoxContainer/ItemList.add_item(str(instrument) + " " + str(i+1))


func _on_ItemList_item_selected(index):
	print(str(instrument_index)+"/"+str(index+1))
	$AudioStreamPlayer.stream = load("res://sounds/"+str(instrument_index)+"/"+str(index+1)+".wav")
	$AudioStreamPlayer.play()


func _on_OkButton_pressed():
	main.song[instrument_index][column] = $VBoxContainer/ItemList.get_selected_items()[0]+1
	
	hide()
	column = 0
