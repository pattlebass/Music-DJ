extends PopupDialog

onready var main = get_parent()


func _ready():
	#theme = GlobalVariables.theme_resource
	$BackPanel.theme = load("res://assets/themes/%s/theme2.tres" % GlobalVariables.options.theme)


func about_to_show():
	yield(get_tree(), "idle_frame")
	
	$BackPanel.rect_global_position = Vector2(0, 0)
	$BackPanel.rect_size = OS.get_window_size()
	
	$AnimationPlayer.play("fade_in")


func popup_hide():
	visible = true
	# Animation
	$AnimationPlayer.play_backwards("fade_in")
	yield(get_tree().create_timer(0.1), "timeout")
	
	visible = false
