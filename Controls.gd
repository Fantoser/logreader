extends PanelContainer


var session
var difference

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func setup():
	var difference = session.endTime - session.startTime
	get_node("%timeScale").max_value = session.endTime - difference
	get_node("%endTime").text = Time.get_datetime_string_from_unix_time(session.endTime, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if session.startTime != 0 and difference != null:
		get_node("%currentTime").text = Time.get_datetime_string_from_unix_time(get_node("%timeScale").value + difference, true)
