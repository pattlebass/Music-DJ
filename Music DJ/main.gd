extends Control

var song = {"drums":[], "guitar":[], "keys":[], "trumpet":[]}

func _ready():
	var step_scene = preload("res://Step.tscn")
	for i in 25:
		var step = step_scene.instance()
		step.get_node("Label").text = str(i + 1)
		get_node("HBoxContainer/StepContainer/HBoxContainer").add_child(step)
		
		# Signals
		step.get_node("Button1").connect("pressed", self, "button1", [i])
		step.get_node("Button2").connect("pressed", self, "button1", [i])
		step.get_node("Button3").connect("pressed", self, "button1", [i])
		step.get_node("Button4").connect("pressed", self, "button1", [i])
		
		
		for g in song.values():
			g.append(0)


func _process(delta):
	pass


func play():
	for i in 25:
		song["drums"][i]
		song["guitar"][i]
		song["keys"][i]
		song["trumpet"][i]


func button1(_index):
	print(_index)
	
	song["drums"].insert(_index, 1)

func button2(_index):
	print(_index)
	
	song["guitar"].insert(_index, 0)

func button3(_index):
	print(_index)
	
	song["keys"].insert(_index, 0)

func button4(_index):
	print(_index)
	
	song["trumpet"].insert(_index, 0)
