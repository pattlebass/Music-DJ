extends "res://DialogScript.gd"

var instrument_index
var instrument_name = ["Drums", "Bass", "Keys", "Trumpet"]
var column_no
var pressed_button_index = 0
var genre_index = 0 # Index based on genre. Eg: button 0 of genre 2. genre_index would be 0

var column
var button


func _ready():
	
	# Create list
	var text = ["Groove 1", "Groove 2", "Salsa 1", "Salsa 2", "Reggae 1", "Reggae 2", "Techno 1", "Techno 2"]
	var category = ["Introduction", "Verse", "Chorus", "Solo"]
	var colors = GlobalVariables.colors
	var button_index = -1
	
	for i in 4:
		var scroll_container = $VBoxContainer/ScrollContainer/VBoxContainer
		
		var separator = HSeparator.new()
		separator.set("custom_constants/separation", 10)
		separator.modulate = Color(1, 1, 1, 0.01)
		scroll_container.add_child(separator)
		
		var label = Label.new()
		label.text = category[i]
		label.theme = load("res://assets/themes/%s/theme2.tres" % GlobalVariables.options.theme)
		scroll_container.add_child(label)
		
		var separator2 = HSeparator.new()
		var theme2_path = "res://assets/themes/%s/theme2.tres" % GlobalVariables.options.theme
		#separator2.theme = load(theme2_path)
		scroll_container.add_child(separator2)
		
		# Icon
		var image = load("res://assets/mask.png")
		var texture = ImageTexture.new()
		#image.create(32, 32, false, Image.FORMAT_RGBA4444)
		image.lock()
		for v in 32:
			for h in 32:
				var current_pixel = image.get_pixel(h, v)
				if current_pixel == Color(1, 1, 1):
					image.set_pixel(h, v, colors[i]*current_pixel)
				else:
					image.set_pixel(h, v, Color(1, 1, 1, 0))
		image.unlock()
		texture.create_from_image(image)
		
		# Buttons
		for g in 8:
			button_index += 1
			var button_in_list = Button.new()
			button_in_list.text = " "+text[g]
			button_in_list.theme = load("res://assets/themes/%s/theme2.tres" % GlobalVariables.options.theme)
			button_in_list.icon = texture
			button_in_list.align = Button.ALIGN_LEFT
			button_in_list.mouse_filter = Button.MOUSE_FILTER_PASS
			button_in_list.connect("pressed", self, "on_Button_selected", [button_index, g])
			button_in_list.name = str(button_index)
			button_in_list.focus_mode = Control.FOCUS_NONE
			button_in_list.toggle_mode = true
			scroll_container.add_child(button_in_list)
			

func about_to_show():
	column = main.get_node("HBoxContainer/StepContainer/HBoxContainer").get_child(column_no)
	button = column.get_child(instrument_index+1)
	
	# Set title
	var instrument
	
	instrument = instrument_name[instrument_index]
	$VBoxContainer/Label.text = instrument + ", column " + str(column_no+1)
	
	
	# Set button states
	$VBoxContainer/HBoxContainer/OkButton.disabled = true
	
	var clear_button = get_node("VBoxContainer/HBoxContainer/ClearButton")
	
	if button.text == "":
		clear_button.disabled = true
	else:
		clear_button.disabled = false
	
	.about_to_show()

func on_Button_selected(index, _genre_index):
	if index == pressed_button_index:
		get_node("VBoxContainer/ScrollContainer/VBoxContainer/"+str(pressed_button_index)).pressed = true

	print(str(instrument_index)+"/"+str(index+1))
	$AudioStreamPlayer.stream = load("res://sounds/"+str(instrument_index)+"/"+str(index+1)+".wav")
	$AudioStreamPlayer.play()
	$VBoxContainer/HBoxContainer/OkButton.disabled = false
	pressed_button_index = index
	genre_index = _genre_index
	
	for i in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		if i is Button:
			if i.name == str(index):
				continue
			i.pressed = false


func _on_OkButton_pressed():
	var style_box = preload("res://assets/button_stylebox.tres").duplicate()
	
	button.text = str(genre_index+1)
	
	var sound_button = get_node("VBoxContainer/ScrollContainer/VBoxContainer/"+str(pressed_button_index))
	var image = sound_button.icon.get_data()
	
	image.lock()
	
	style_box.bg_color = image.get_pixel(10,10)
	button.set("custom_styles/normal", style_box)
	button.set("custom_styles/pressed", style_box)
	button.set("custom_styles/disabled", style_box)
	button.set("custom_styles/hover", style_box)
	button.set("custom_styles/focus", StyleBoxEmpty)
	
	image.unlock()
	
	main.song[instrument_index][column_no] = pressed_button_index+1
	if column_no > main.last_columns.back():
		main.last_columns.append(column_no)

	hide()
	column_no = 0


func _on_ClearButton_pressed():
	button.text = ""
	button.set("custom_styles/normal", null)
	button.set("custom_styles/pressed", null)
	button.set("custom_styles/disabled", null)
	button.set("custom_styles/hover", null)
	
	# If all buttons in a column are clear remove that column from the play list
	var falses = -1
	for i in column.get_children():
		if i is Button and i.text != "":
			falses += 1
	if falses == 0:
		main.last_columns.erase(column_no)
	
	main.song[instrument_index][column_no] = 0

	hide()


func _on_CancelButton_pressed():
	hide()


func popup_hide():
	$VBoxContainer/ScrollContainer.scroll_vertical = 0
	for i in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		if i is Button:
			i.pressed = false
	.popup_hide()
