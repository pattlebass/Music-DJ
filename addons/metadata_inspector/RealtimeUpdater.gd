extends Node

var counter = 0 

func _ready():
	print("REDY")

func _process(delta):
	if counter == 30:
		#print(Engine.is_editor_hint())
		if( self.get_tree().has_method("is_editor_hint") and not self.get_tree().is_editor_hint()
		or( not Engine.is_editor_hint())
				):
			print("UPDATE")
	counter = (counter+1)%120
