extends PopupDialog

onready var main = get_parent()
var dim := true

func _ready():
	pass


func about_to_show():
	rect_pivot_offset = rect_size / 2
	
	if dim:
		main.on_popup_show()
	
	$AnimationPlayer.play("fade_in")


func popup_hide():
	$AnimationPlayer.play("fade_out")
	
	if dim:
		main.on_popup_hide()
