extends PopupDialog

onready var main = get_parent()


func _ready():
	pass


func about_to_show(dim := true):
	rect_pivot_offset = rect_size / 2
	
	if dim:
		main.on_popup_show()
	
	$AnimationPlayer.play("fade_in")


func popup_hide(dim := true):
	$AnimationPlayer.play("fade_out")
	
	if dim:
		main.on_popup_hide()
