extends PanelContainer


var session
var difference
var character = preload("res://Character.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_MapLoad_pressed():
	var selector = FileDialog.new()
	selector.set_mode(selector.MODE_OPEN_FILE)
	selector.set_access(selector.ACCESS_FILESYSTEM)
#	selector.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	self.add_child(selector)
	selector.popup_centered_clamped(Vector2(600,400))
	get_node("%MapFileField").text = yield(selector,"file_selected")

func _on_InsertButton_pressed():
	var image_path = get_node("%MapFileField").text

	var image = Image.new()
	var error = image.load(image_path)
	if error != OK:
		print("Error loading image file")
		return

	var texture = ImageTexture.new()
	texture.create_from_image(image)

	get_node("%Map").get_node("MapImage").texture = texture

func setup():
	get_node("%currentTime").text = Time.get_datetime_string_from_unix_time(get_node("%timeScale").value + session.startTime, true)
	get_node("%timeScale").max_value = session.endTime - session.startTime
	get_node("%endTime").text = Time.get_datetime_string_from_unix_time(session.endTime, true)
	_fill_log()
	_add_characters()

func _fill_log():
	for time in range(session.startTime, session.endTime+1):
		for area in session.messages:
			if session.messages[area].has(time):
				var label = Label.new()
				label.text = session.messages[area][time]["speaker"]
				label.text += " - " + Time.get_datetime_string_from_unix_time(time, true)
				label.text += "\n" + session.messages[area][time]["message"] + "\n"
				get_node("%Log").add_child(label)

func _add_characters():
	for id in session.characters:
		var characterNode = character.instance()
		characterNode.get_node("%Name").text = session.characters[id]["name"]
		characterNode.get_node("%Icon").self_modulate = Color(session.characters[id]["color"])
		get_node("%Characters").add_child(characterNode)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_timeScale_scrolling():
	if get_node("%endTime").text != "0":
		get_node("%currentTime").text = Time.get_datetime_string_from_unix_time(get_node("%timeScale").value + session.startTime, true)
