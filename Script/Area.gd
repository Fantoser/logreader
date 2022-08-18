extends Control

var session

var id
var areaName

var scaleDrag
var bgDrag
var camera

# Called when the node enters the scene tree for the first time.
func _ready(): 
	camera = get_parent().get_parent().get_node("Camera")
	$Label.text = areaName
	self.name = id

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_ScaleButton_button_down():
	scaleDrag = true

func _on_ScaleButton_button_up():
	scaleDrag = false

func _on_Background_button_down():
	bgDrag = true

func _on_Background_button_up():
	bgDrag = false
	session.areas[id]["Pos"] = rect_position

func _input(event):
	if event is InputEventMouseMotion:
		if bgDrag == true:
			rect_position += event.get_relative() * camera.zoom.x
		if scaleDrag == true:
			rect_size += event.get_relative() * camera.zoom.x
	session.areas[id]["Size"] = rect_size
	session.areas[id]["Pos"] = rect_position
