extends PopupDialog


var panels = [{"title":"Tap and hold a tile to copy it.", "video":"res://assets/tutorial/0.webm", "index":0},
{"title":"Tap the number of a column to open its menu.", "video":"res://assets/tutorial/1.webm", "index":1},
{"title":"Follow @pattlebass_dev on Twitter for updates.", "video":"res://assets/tutorial/2.webm", "index":2},]
var current = 0

onready var video_player = $VBoxContainer/HBoxContainer2/VBoxContainer2/VideoPlayer


func _ready():
	if GlobalVariables.options["show_tutorial"]:
		call_deferred("popup_centered")


func _on_TutorialDialog_about_to_show():
	change_panel(0)
	$AnimationPlayer.play("fade_in")


func _on_NextButton_pressed():
	current += 1
	change_panel(current)


func _on_PreviousButton_pressed():
	current -= 1
	change_panel(current)


func change_panel(_panel_no):
	if _panel_no >= panels.size():
		GlobalVariables.options["show_tutorial"] = false
		GlobalVariables.save_options()
		hide()
		return
	
	$AnimationPlayer.play_backwards("fade_in_image")
	yield(get_tree().create_timer(0.1), "timeout")
	var panel = panels[_panel_no]
	video_player.stream = load(panel["video"])
	video_player.play()
	print(video_player)
	$VBoxContainer/Label2.text = panel["title"]
	$VBoxContainer/Label3.text = str(panel["index"]+1)+"/"+str(panels.size())
	$AnimationPlayer.play("fade_in_image")
	
	var previous_button = $VBoxContainer/HBoxContainer2/VBoxContainer/PreviousButton
	var next_button = $VBoxContainer/HBoxContainer2/VBoxContainer3/NextButton
	if _panel_no == 0:
		previous_button.disabled = true
	else:
		previous_button.disabled = false



func _on_TutorialDialog_popup_hide():
	visible = true
	# Animation
	$AnimationPlayer.play_backwards("fade_in")
	yield(get_tree().create_timer(0.1), "timeout")
	visible = false


func _on_VideoPlayer_finished():
	video_player.play()
