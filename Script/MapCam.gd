extends Node2D


var dragging = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if event.is_action_pressed("scrollUp"):
		$Camera.zoom -= Vector2(1, 1)
	if event.is_action_pressed("scrollDown"):
		$Camera.zoom += Vector2(1, 1)

	if event is InputEventMouseButton:
		if event.is_action_pressed("rightClick") or event.is_action_pressed("middleClick"):
			dragging = true
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		$Camera.position -= event.get_relative() * $Camera.zoom.x

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
