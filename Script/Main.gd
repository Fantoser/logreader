extends Node


var logFile


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_FileLoad_pressed():
	var selector = FileDialog.new()
	selector.add_filter("*.log")
	selector.set_mode(selector.MODE_OPEN_FILE)
	selector.set_access(selector.ACCESS_FILESYSTEM)
	self.add_child(selector)
	selector.popup_centered_clamped(Vector2(600,400))
	logFile = yield(selector,"file_selected")
	get_node("%FilePathField").text = logFile

func _on_Read_pressed():
	get_node("%LoadingLabel").visible = true
	wait(0.1)
	var file = File.new()
	if file.open(logFile,file.READ) == OK:
		var index = 1
		while not file.eof_reached(): # iterate through all lines until the end of file is reached
			var line = file.get_line()
			line += "\n"
			$PanelContainer2/RichTextLabel.text += line
			index += 1
		file.close()
	get_node("%LoadingLabel").visible = false

func wait(seconds):
	var t = Timer.new()
	t.set_wait_time(seconds)
	t.set_one_shot(true)
	self.add_child(t)
	t.start()
	yield(t, "timeout")
	t.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

