extends PopupDialog


var frames = [30]
var anim_textures = []
var texture_res = preload("res://assets/tutorial/animated_texture.tres")

func _ready():
	for page in frames.size():
		var anim_texture = texture_res.duplicate()
		anim_texture.frames = frames[page]
		for i in frames[page]:
			var frame_texture = load("res://assets/tutorial/"+str(page)+"/"+str(i)+".png")
			
			anim_texture.set_frame_texture(i, frame_texture)
			
		anim_textures.append(anim_texture)
		$VBoxContainer/VBoxContainer2/HBoxContainer/TextureRect.texture = anim_texture
	
	call_deferred("popup_centered")
