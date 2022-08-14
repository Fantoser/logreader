extends PanelContainer


var session
var character = preload("res://Character.tscn")
var area = preload("res://Area.tscn")
var bean = preload("res://Bean.png")

var areas
var prevTime
var playing
var playing_backward

# Called when the node enters the scene tree for the first time.
func _ready():
	areas = get_node("%Map").get_node("AreasRects")

func clear():
	for child in get_node("%Characters").get_children():
		child.queue_free()
	for child in get_node("%Map").get_node("AreasRects").get_children():
		child.queue_free()

func _on_MapLoad_pressed():
	var selector = FileDialog.new()
	selector.add_filter("*.png, *.jpg, *.jpeg, *.bmp")
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

func _on_SaveButton_pressed():
	var selector = FileDialog.new()
	selector.add_filter("*.tres")
	selector.set_mode(selector.MODE_SAVE_FILE)
	selector.set_access(selector.ACCESS_FILESYSTEM)
#	selector.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	self.add_child(selector)
	selector.popup_centered_clamped(Vector2(600,400))
	var filePath = yield(selector,"file_selected")
	print(filePath)
	if filePath != null:
		ResourceSaver.save(filePath, session)

func _on_LoadButton_pressed():
	var selector = FileDialog.new()
	selector.add_filter("*.tres")
	selector.set_mode(selector.MODE_OPEN_FILE)
	selector.set_access(selector.ACCESS_FILESYSTEM)
#	selector.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	self.add_child(selector)
	selector.popup_centered_clamped(Vector2(600,400))
	var filePath = yield(selector,"file_selected")
	if filePath != null:
		clear()
		session = ResourceLoader.load(filePath)
		setup()
		

func setup():
	get_node("%currentTime").text = Time.get_datetime_string_from_unix_time(get_node("%timeScale").value + session.startTime, true)
	get_node("%timeScale").max_value = session.endTime - session.startTime
	get_node("%endTime").text = Time.get_datetime_string_from_unix_time(session.endTime, true)
	prevTime = session.startTime
	_fill_log()
	_add_areas()
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
	var areas = get_node("%Map").get_node("AreasRects")
	for id in session.characters:
		var characterNode = character.instance()
		characterNode.get_node("%Name").text = session.characters[id]["name"]
		characterNode.get_node("%Icon").self_modulate = Color(session.characters[id]["color"])
		get_node("%Characters").add_child(characterNode)

		var mapChar = TextureRect.new()
		mapChar.name = str(id)
		mapChar.mouse_filter = MOUSE_FILTER_IGNORE
		mapChar.texture = bean
		mapChar.self_modulate = session.characters[id]["color"]
		areas.get_node(str(session.characters[id]["startLocation"])).get_node("%Grid").add_child(mapChar)

func _add_areas():
	for id in session.areas:
		var areaNode = area.instance()
		var areas = get_node("%Map").get_node("AreasRects")
		areaNode.session = session
		areaNode.id = id
		areaNode.areaName = session.areas[id]["name"]
		areaNode.rect_position = Vector2(areas.get_child_count() * areaNode.rect_size.x+10, 0)
		areas.add_child(areaNode)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if playing == true and get_node("%timeScale").value != 0:
		get_node("%timeScale").value += 1
		_on_timeScale_scrolling()
	if playing_backward == true and get_node("%timeScale").value != (session.endTime - session.startTime):
		get_node("%timeScale").value -= 1
		_on_timeScale_scrolling()


func _on_timeScale_scrolling():
	if get_node("%endTime").text != "0":
		get_node("%currentTime").text = Time.get_datetime_string_from_unix_time(get_node("%timeScale").value + session.startTime, true)
		var newTime = Time.get_unix_time_from_datetime_string(get_node("%currentTime").text)
		_move_characters(newTime)
		prevTime = newTime

func _move_characters(newTime):
	var from = "from"
	var to = "to"
	var fromTime = prevTime
	var toTime = newTime
	if newTime < prevTime:
		from = "to"
		to = "from"
		fromTime = newTime
		toTime = prevTime
	for time in range(fromTime, toTime):
		if session.movements.has(time):
			for movement in session.movements[time]:
				if areas.get_node(movement[from]).get_node("%Grid").has_node(str(movement["character"])):
					var character = areas.get_node(movement[from]).get_node("%Grid").get_node(str(movement["character"]))
					areas.get_node(movement[from]).get_node("%Grid").remove_child(character)
					areas.get_node(movement[to]).get_node("%Grid").add_child(character)


func _on_Play_pressed():
	playing_backward = false
	playing = !playing


func _on_Play_Backward_pressed():
	playing = false
	playing_backward = !playing_backward


func _on_NextStep_pressed():
	playing_backward = false
	playing = false
	for time in range(get_node("%timeScale").value + session.startTime, session.endTime):
		if session.movements.has(time) and time > get_node("%timeScale").value + session.startTime:
			get_node("%timeScale").value = time - session.startTime
			_on_timeScale_scrolling()
			break


func _on_PrevStep_pressed():
	playing_backward = false
	playing = false
	for time in range(get_node("%timeScale").value + session.startTime, session.startTime, -1):
		if session.movements.has(time) and time < get_node("%timeScale").value + session.startTime:
			get_node("%timeScale").value = time - session.startTime
			_on_timeScale_scrolling()
			break

