extends PanelContainer


var session
var character = preload("res://Character.tscn")
var area = preload("res://Area.tscn")
var bean = preload("res://Bean.png")

var areas
var prevTime
var playing
var playing_backward
var timer = 0

var loading

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

func _on_InsertButton_pressed(image_path = null):
	if image_path == null:
		image_path = get_node("%MapFileField").text

	var image = Image.new()
	var error = image.load(image_path)
	if error != OK:
		print("Error loading image file")
		return

	var texture = ImageTexture.new()
	texture.create_from_image(image)

	session.map = image_path
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
		loading = true
		clear()
		session = ResourceLoader.load(filePath)
		_on_InsertButton_pressed(session.map)
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
		characterNode.get_node("%Visibility").connect("toggled", self, "set_character_visible", [id])
		get_node("%Characters").add_child(characterNode)

		var mapChar = TextureRect.new()
		mapChar.name = str(id)
		mapChar.mouse_filter = MOUSE_FILTER_IGNORE
		mapChar.texture = bean
		mapChar.self_modulate = session.characters[id]["color"]
		areas.get_node(str(session.characters[id]["startLocation"])).get_node("%Grid").add_child(mapChar)
		session.characters[id]["mapchar"] = mapChar

func set_character_visible(toggle, id):
	session.characters[id]["mapchar"].set_visible(not toggle)

func _add_areas():
	for id in session.areas:
		var areaNode = area.instance()
		var areas = get_node("%Map").get_node("AreasRects")
		areaNode.session = session
		areaNode.id = id
		areaNode.areaName = session.areas[id]["name"]
		if loading == false:
			areaNode.rect_position = Vector2(areas.get_child_count() * areaNode.rect_size.x+10, 0)
			session.areas[id]["Pos"] = areaNode.rect_position
			session.areas[id]["Size"] = Vector2(100, 100)
		else:
			areaNode.rect_position = session.areas[id]["Pos"]
			areaNode.rect_size = session.areas[id]["Size"]
		areas.add_child(areaNode)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_node("%timeScale").value + session.startTime != prevTime and get_node("%endTime").text != "0":
		get_node("%currentTime").text = Time.get_datetime_string_from_unix_time(get_node("%timeScale").value + session.startTime, true)
		var newTime = Time.get_unix_time_from_datetime_string(get_node("%currentTime").text)
		_move_characters(newTime)
		prevTime = newTime
	
	if playing == true and get_node("%timeScale").value != (session.endTime - session.startTime):
		if timer <= 0:
			get_node("%timeScale").value += 1
			timer = (get_node("%playDelay").value * 60)
		else:
			timer -= 1
	if playing_backward == true and get_node("%timeScale").value != 0:
		if timer <= 0:
			get_node("%timeScale").value -= 1
			timer = (get_node("%playDelay").value * 60)
		else:
			timer -= 1


func _on_timeScale_scrolling():
	if get_node("%endTime").text != "0":
		get_node("%currentTime").text = Time.get_datetime_string_from_unix_time(get_node("%timeScale").value + session.startTime, true)
		var newTime = Time.get_unix_time_from_datetime_string(get_node("%currentTime").text)
		_move_characters(newTime)
		prevTime = newTime

#func _move_characters(newTime):
#	if newTime == session.startTime:
#		for area in areas.get_children():
#			for character in area.get_node("%Grid").get_children():
#				area.get_node("%Grid").remove_child(character)
#				areas.get_node(session.characters[int(character.name)]["startLocation"]).get_node("%Grid").add_child(character)
#		return
#	var from = "from"
#	var to = "to"
#	var fromTime = session.startTime
#	var toTime = newTime
#	var fromArea
#	var step = 1
#	if newTime < prevTime:
#		from = "to"
#		to = "from"
#		fromTime = session.endTime
#		toTime = prevTime
#		step = -1
#	for time in range(fromTime, toTime, step):
#		if session.movements.has(time):
#			for movement in session.movements[time]:
#				fromArea = movement[from]
#				if areas.get_node(movement[from]).get_node("%Grid").has_node(str(movement["character"])):
#					fromArea = str(movement[from])
#				else:
#					fromArea = _find_character(str(movement["character"]))
#				var character = areas.get_node(fromArea).get_node("%Grid").get_node(str(movement["character"]))
#				areas.get_node(fromArea).get_node("%Grid").remove_child(character)
#				areas.get_node(movement[to]).get_node("%Grid").add_child(character)
#				var tween = get_tree().create_tween()
#				tween.tween_property(character, "rect_scale", Vector2(2, 2), 0.05).set_ease(Tween.EASE_OUT)
#				tween.tween_property(character, "rect_scale", Vector2(1, 1), 0.5)

func _move_characters(newTime):
	for charID in session.characters:
		var toLocation = _find_charLocation(charID, newTime)
		if areas.get_node(toLocation).get_node("%Grid").has_node(str(charID)):
			continue
		else:
			var fromLocation = _find_character(charID)
			var character = areas.get_node(fromLocation).get_node("%Grid").get_node(str(charID))
			areas.get_node(fromLocation).get_node("%Grid").remove_child(character)
			areas.get_node(toLocation).get_node("%Grid").add_child(character)
			var tween = get_tree().create_tween()
			tween.tween_property(character, "rect_scale", Vector2(2, 2), 0.05).set_ease(Tween.EASE_OUT)
			tween.tween_property(character, "rect_scale", Vector2(1, 1), 0.5)

func _find_charLocation(charID, newTime):
	var result
	for movement in session.characters[charID]["movements"]:
		if movement[0] <= newTime:
			result = movement[2]
		else:
			return result
	return result

func _find_character(id):
	for area in areas.get_children():
		if area.get_node("%Grid").has_node(str(id)):
			return str(area.name)

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

func _on_Minus_pressed():
	get_node("%timeScale").value -= 1

func _on_Plus_pressed():
	get_node("%timeScale").value += 1
