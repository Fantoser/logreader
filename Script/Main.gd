extends Node

var session = Session.new()
var astring: String
var placeless_messages = {}
var time
var dateDic = {"year": 2000,
				"month": 01,
				"day": 01
				}
var monthDic = {
	"Jan": 1,
	"Feb": 2,
	"Mar": 3,
	"Apr": 4,
	"May": 5,
	"Jun": 6,
	"Jul": 7,
	"Aug": 8,
	"Sep": 9,
	"Oct": 10,
	"Nov": 11,
	"Dec": 12
}
var test = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$"%Controls".session = session
	get_viewport().connect("size_changed", self, "_resize")

func _resize():
	self.rect_size = get_viewport().size

func _on_FileLoad_pressed():
	var selector = FileDialog.new()
	selector.add_filter("*.log")
	selector.set_mode(selector.MODE_OPEN_FILE)
	selector.set_access(selector.ACCESS_FILESYSTEM)
	selector.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	self.add_child(selector)
	selector.popup_centered_clamped(Vector2(600,400))
	get_node("%FilePathField").text = yield(selector,"file_selected")

func _on_Read_pressed():
	if get_node("%FilePathField").text == "":
		get_node("%LoadingLabel").text = "No file selected"
	else:
		get_node("%LoadingLabel").text = "Loading..."
		var t = Timer.new()
		t.set_wait_time(0.1)
		t.set_one_shot(true)
		self.add_child(t)	#7 line of code cause there is no wait() function WOOO
		t.start()
		yield(t, "timeout")
		t.queue_free()

		var file = File.new()
		if file.open(get_node("%FilePathField").text,file.READ) == OK:
			var index = 1
			while not file.eof_reached(): # iterate through all lines until the end of file is reached
				var line = file.get_line()
				if line.find("GMT]") != -1: #Check if a timestamped line, to avoid login messages and such
					if line.find("[OOC]") == -1: #Check if message is not an OOC message, so it have to be IC
						_save_IC_message(line)
						continue
					if line.find("moves from") != -1:
						_save_movement(line)
				index += 1
			file.close()
		$PanelContainer2/RichTextLabel.text = astring
		ResourceSaver.save("res://test_save.tres", session)
		get_node("%LoadingLabel").text = ""
		print(Time.get_datetime_string_from_unix_time(session.startTime, true))
		print(Time.get_datetime_string_from_unix_time(session.endTime, true))
		$"%Controls".setup()

func _save_character(name):
	session.characters[name] = {
		"Color": Color(255, 255, 255, 255),
		"location": null
	}

func _save_IC_message(line):
	var lineArray = line.split(" ")
	var time = _convert_time(str(lineArray[4]) + "-" + str(monthDic[lineArray[1]]) + "-" + str(lineArray[2]) + " " + lineArray[3])
	var character = lineArray[6].rstrip(":")
	var message = line.split(":", true, 3)[3]
	if message.find("] {{{") != -1 and message.find(" }}}[") != -1:
		message = message.split("] {{{", true, 1)[1]
	if session.characters.has(character) == false:
		_save_character(character)
		placeless_messages[character] = []
	if session.characters[character]["location"] == null: #Character's location unknown
		placeless_messages[character].append({
			"time": time,
			"message": message
		})
	else:
		var location = session.characters[character]["location"]
		session.messages[location][time] = {
			"speaker": character,
			"message": message
		}

func _save_movement(line):
	var character = line.split("]")[3].lstrip(" ").split("moves from")[0].rstrip(" ")
	var from = line.split("] ")[3].split(" to")[0]
	var fromID = line.split("] ")[2].split("[")[1]
	var to = line.split("] ")[4].rsplit(".")[0]
	var toID = line.split("] ")[3].split("[")[1]
	var lineArray = line.split(" ")
	var time = _convert_time(str(lineArray[4]) + "-" + str(monthDic[lineArray[1]]) + "-" + str(lineArray[2]) + " " + str(lineArray[3]))
	session.characters["location"] = toID
	# Save from and to areas if they are not saved yet
	if session.areas.has(from) == false:
		session.areas[fromID] = {
			"name": from
		}
	if session.areas.has(to) == false:
		session.areas[toID] = {
			"name": to
		}
	# Save the messages what had unknown location
	if placeless_messages.has(character):
		for message in placeless_messages[character]:
			if session.messages.has(fromID) == false:
				session.messages[fromID] = {}
			session.messages[fromID][message["time"]] = {
			"speaker": character,
			"message": message["message"]
		}
	# Save movement
	if session.movements.has(time) == false:
		session.movements[time] = []
	session.movements[time].append({
		"character": character,
		"from": fromID,
		"to": toID
	})

func _convert_time(timeStr):
	var timeDic = Time.get_datetime_dict_from_datetime_string(timeStr, false)
	var time = Time.get_unix_time_from_datetime_dict(timeDic)
	if session.startTime == 0:
		session.startTime = time
	if session.endTime < time:
		session.endTime = time
	return time

