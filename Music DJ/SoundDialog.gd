extends WindowDialog

onready var main = get_parent()

var instrument_index
var column
var actual_index = 0
onready var item_list = $VBoxContainer/ItemList


func _ready():
	var text = ["Groove 1", "Groove 2", "Salsa 1", "Salsa 2", "Reggae 1", "Reggae 2", "Techno 1", "Techno 2"]
	var category = ["Introduction", "Verse", "Chorus", "Solo"]
	var color = [Color(0.678, 0.847, 90.2), Color(0.565, 0.933, 0.565), Color(1, 0.502, 1), Color(1, 0.894, 0.71)]
	
	for i in 4:
		item_list.add_item(category[i], null, false)
		#item_list.set_item_custom_fg_color(0, color[0])
		for g in 8:
			var image = Image.new()
			var texture = ImageTexture.new()
			image.create(32, 32, false, Image.FORMAT_RGBA4444)
			image.lock()
			for v in 32:
				for h in 32:
					image.set_pixel(h, v, color[i])
			image.unlock()
			texture.create_from_image(image)
			item_list.add_item("  "+text[g], texture)
	
	item_list.set_item_disabled(0, true)
	item_list.set_item_disabled(9, true)
	item_list.set_item_disabled(18, true)
	item_list.set_item_disabled(27, true)

func _on_SoundDialog_about_to_show():
	$VBoxContainer/HBoxContainer/OkButton.disabled = true
	
	var instrument
	
	if instrument_index == 0:
		instrument = "Drums"
	elif instrument_index == 1:
		instrument = "Bass"
	elif instrument_index == 2:
		instrument = "Keys"
	elif instrument_index == 3:
		instrument = "Trumpet"
	
	window_title = instrument


func _on_ItemList_item_selected(index):
	if item_list.is_item_disabled(index):
		return
	
	var offsets = {0:1, 9:2, 18:3, 27:4}
	var offset = 0
	
	for i in offsets.keys():
		if index > i and index < i+9:
			offset = offsets[i]
	actual_index = index - offset
	
	print(str(instrument_index)+"/"+str(actual_index+1))
	$AudioStreamPlayer.stream = load("res://sounds/"+str(instrument_index)+"/"+str(actual_index+1)+".wav")
	$AudioStreamPlayer.play()
	$VBoxContainer/HBoxContainer/OkButton.disabled = false


func _on_OkButton_pressed():
	var selected = $VBoxContainer/ItemList.get_selected_items()
	
	if selected.empty():
		return
	
	# Button
	var step = main.get_node("HBoxContainer/StepContainer/HBoxContainer").get_child(column)
	var button = step.get_child(instrument_index+1)
	var style_box = StyleBoxTexture.new()
	
	button.text = str(actual_index+1)
	
	style_box.texture = $VBoxContainer/ItemList.get_item_icon(selected[0])
	button.set("custom_styles/normal", style_box)
	
	main.song[instrument_index][column] = actual_index+1
	
	$VBoxContainer/ItemList.unselect_all()
	$VBoxContainer/ItemList.get_v_scroll().set_value(0.0)
	hide()
	column = 0


func _on_ClearButton_pressed():
	var step = main.get_node("HBoxContainer/StepContainer/HBoxContainer").get_child(column)
	var button = step.get_child(instrument_index+1)
	button.text = ""
	button.set("custom_styles/normal", null)
	
	main.song[instrument_index][column] = 0
	
	$VBoxContainer/ItemList.unselect_all()
	$VBoxContainer/ItemList.get_v_scroll().set_value(0.0)
	hide()

func _on_CancelButton_pressed():
	$VBoxContainer/ItemList.unselect_all()
	$VBoxContainer/ItemList.get_v_scroll().set_value(0.0)
	hide()
