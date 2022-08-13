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
	_place_buttons()

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

func _place_buttons():
	var bgWidth = $Background.rect_size.x
	var bgHeight = $Background.rect_size.y
	$ScaleButton.rect_position = Vector2(bgWidth-30, bgHeight-30)
	$Label.rect_position = Vector2(bgWidth/2-$Label.rect_size.x/2, bgHeight/2)
	$Grid.rect_size = Vector2(bgWidth, bgHeight)
	$Grid.columns = bgWidth / 30
	session.areas[id]["Size"] = Vector2($Background.rect_size)
	session.areas[id]["Pos"] = rect_position

func _input(event):

	if event is InputEventMouseMotion:
		if bgDrag == true:
			rect_position += event.get_relative() * camera.zoom.x
		if scaleDrag == true:
			$Background.rect_size += event.get_relative() * camera.zoom.x
	if scaleDrag:
		_place_buttons()
