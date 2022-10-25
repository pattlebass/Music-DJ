extends Popup
class_name CustomDialog

onready var main = get_parent()
onready var anim_player
var dim := true
var pivot_manual := false


func _init():
	# Classes cannot have children so I have to add them in code.
	# The animation player in the scene is there to make animation easier
	
	anim_player = AnimationPlayer.new()
	anim_player.add_animation("fade_in", preload("res://scenes/dialogs/custom_dialog/anim_fade_in.tres"))
	anim_player.add_animation("fade_out", preload("res://scenes/dialogs/custom_dialog/anim_fade_out.tres"))
	anim_player.add_animation("reset", preload("res://scenes/dialogs/custom_dialog/anim_reset.tres"))
	add_child(anim_player)
	
	connect("about_to_show", self, "about_to_show")
	connect("popup_hide", self, "popup_hide")


func about_to_show():
	if not pivot_manual:
		rect_pivot_offset = rect_size / 2
	
	if dim:
		main.show_shadow()
	
	anim_player.play("fade_in")


func popup_hide():
	anim_player.play("fade_out")
	
	if dim:
		main.hide_shadow()
