extends "res://scenes/DialogScript.gd"


var panels = [{"title":"Tap and hold a tile to copy it.", "video":"res://assets/tutorial/0.webm", "index":0},
{"title":"Tap the number of a column to open its menu.", "video":"res://assets/tutorial/1.webm", "index":1},
{"title":"You can drag and drop project files into the App's window.", "video":"res://assets/tutorial/2.webm", "index":2},
{"title":"Follow [color=#4ecca3][url=https://twitter.com/pattlebass_dev]@pattlebass_dev[/url][/color] on Twitter for updates.", "video":"res://assets/tutorial/3.webm", "index":3},]
var current = 0

onready var video_player = $VBoxContainer/HBoxContainer2/VBoxContainer2/VideoPlayer
onready var animation = $AnimationPlayer2


func _ready():
	if Variables.current_tutorial_version > Variables.options["last_seen_tutorial"]:
		call_deferred("popup_centered")


func about_to_show(dim := true):
	current = 0
	change_panel(0, 0)
	.about_to_show()


func _on_NextButton_pressed():
	current += 1
	change_panel(current, current - 1)


func _on_PreviousButton_pressed():
	current -= 1
	change_panel(current, current + 1)


func change_panel(_panel_no, _previous_panel_no):
	if _panel_no >= panels.size():
		if Variables.current_tutorial_version > Variables.options["last_seen_tutorial"]:
			Variables.options["last_seen_tutorial"] = Variables.current_tutorial_version
			Variables.save_options()
		hide()
		return
	
	var previous_button = $VBoxContainer/HBoxContainer2/VBoxContainer/PreviousButton
	#var next_button = $VBoxContainer/HBoxContainer2/VBoxContainer3/NextButton
	if _panel_no == 0:
		previous_button.disabled = true
	else:
		previous_button.disabled = false
	
	# Note for future me:
	# You can think backwards = opposite
	# eg: fade_in_right_to_left backwards is fade_out_left_to_right
	# I know it's confusing but it's easier to change
	if _panel_no >= _previous_panel_no:
		animation.play("fade_out_right_to_left")
	else:
		animation.play_backwards("fade_in_right_to_left")
	
	yield(get_tree().create_timer(0.1), "timeout")
	animation.stop(false)
	
	var panel = panels[_panel_no]
	video_player.stream = load(panel["video"])
	video_player.play()
	$VBoxContainer/RichTextLabel.bbcode_text = panel["title"]
	$VBoxContainer/PageLabel.text = str(panel["index"]+1)+"/"+str(panels.size())
	
	if _panel_no >= _previous_panel_no:
		animation.play("fade_in_right_to_left")
	else:
		animation.play_backwards("fade_out_right_to_left")


func _on_VideoPlayer_finished():
	video_player.play()


func _on_Label2_meta_clicked(meta):
	OS.shell_open(meta)
