extends PopupDialog

onready var main = get_parent()


func _ready():
	pass


func about_to_show():
	rect_pivot_offset = rect_size / 2
	
	main.on_popup_show()
	
	$AnimationPlayer.play("fade_in")


func popup_hide():
	$AnimationPlayer.play("fade_out")

	main.on_popup_hide()
