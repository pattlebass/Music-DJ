extends PopupDialog


var panels = [{"title":"Tap and hold a tile to copy it.", "frames":40, "anim_texture":null, "index":0},
{"title":"Tap the number of a column to open its menu.", "frames":40, "anim_texture":null, "index":1},]
#{"title":"Test3", "frames":30, "anim_texture":null, "index":2},
#{"title":"Test4", "frames":30, "anim_texture":null, "index":3}]
var texture_res = preload("res://assets/tutorial/animated_texture.tres")
var current = 0

onready var texture_rect = get_node("VBoxContainer/HBoxContainer2/VBoxContainer2/TextureRect")

func _ready():
	if GlobalVariables.options["show_tutorial"]:
		call_deferred("popup_centered")


func _on_TutorialDialog_about_to_show():
	for panel in panels:
		var anim_texture = texture_res.duplicate()
		anim_texture.frames = panel["frames"]
		for i in panel["frames"]:
			var frame_texture = load("res://assets/tutorial/"+str(panel["index"])+"/"+str(i)+".png")
			
			anim_texture.set_frame_texture(i, frame_texture)
			
		panel["anim_texture"] = anim_texture
	
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
	texture_rect.texture = panel["anim_texture"]
	$VBoxContainer/Label2.text = panel["title"]
	$VBoxContainer/Label3.text = str(panel["index"]+1)+"/"+str(panels.size())
	$AnimationPlayer.play("fade_in_image")
	
	var previous_button = $VBoxContainer/HBoxContainer2/VBoxContainer/PreviousButton
	var next_button = $VBoxContainer/HBoxContainer2/VBoxContainer3/NextButton
	if _panel_no == 0:
		previous_button.disabled = true
		next_button.disabled = false
	elif _panel_no == panels.size()-1:
		previous_button.disabled = false



func _on_TutorialDialog_popup_hide():
	visible = true
	# Animation
	$AnimationPlayer.play_backwards("fade_in")
	yield(get_tree().create_timer(0.1), "timeout")
	visible = false
