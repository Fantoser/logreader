extends Node

var session = Session.new()
var placeless_messages = {}
var unclaimed_movements = {}
var starLocation_time = {}
var time
var nameList = {}
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
var colors = ["#e57373", "#d91d00", "#7a432f", "#e6bbac", "#8c6246", "#ff0044", "#6e2e8e", "#6c5336", "#c200f2", "#d98d36", "#ffd580", "#f23d9d", "#a6987c", "#e2ace6",  "#566573", "#673973",  "#9979f2", "#7f6600", "#e6f23d", "#7a9900", "#b4e6ac", "#20802d", "#00330e", "#39e667", "#608071", "#755102", "#3df2e6", "#007780", "#132526", "#80e6ff", "#308fbf", "#205380", "#002e73", "#50592d", "#397ee6", "#0041f2","#260a00", "#acbbe6", "#0d1233", "#0e0066", "#26001f", "#7f0044", "#664d53", "#661a24"]

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
#	selector.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	self.add_child(selector)
	selector.popup_centered_clamped(Vector2(600,400))
	get_node("%FilePathField").text = yield(selector,"file_selected")

func _on_Read_pressed():
	if get_node("%FilePathField").text == "":
		get_node("%LoadingLabel").text = "No file selected"
	else:
		get_node("%LoadingLabel").text = "Loading..."
		yield(get_tree().create_timer(0.1), "timeout")

		var file = File.new()
		if file.open(get_node("%FilePathField").text,file.READ) == OK:
			var index = 1
			while not file.eof_reached(): # iterate through all lines until the end of file is reached
				var line = file.get_line()
				if line.find("GMT]") != -1: #Check if a timestamped line, to avoid login messages and such
#					if line.find("[OOC]") == -1 and line.find("has played a song:") == -1 and line.find("has presented evidence:") == -1: #Check if message is not an OOC message, so it have to be IC
#						_process_IC_msg(line)
#						continue
					if line.find("moves from") != -1:
						_process_move(line)
				index += 1
			file.close()
		ResourceSaver.save("res://test_save.tres", session)
		get_node("%LoadingLabel").text = ""
		$"%Controls".setup()

func _save_character(name):
	session.characters[session.characters.size()] = {
		"name": name,
		"color": Color(colors[session.characters.size()]),
		"location": null,
		"startLocation": null
	}
	_check_unclaimed_movements(name)

func _save_area(ID, name):
	session.areas[ID] = {
		"name": name
	}

func _process_IC_message(line):
	var lineArray = line.split(" ")
	var time = _convert_time(str(lineArray[4]) + "-" + str(monthDic[lineArray[1]]) + "-" + str(lineArray[2]) + " " + lineArray[3])
	var character = lineArray[6]
	var custom_name = null
	var message = line.split(":", true, 3)[3]
	if character.length() > 0 and character[character.length()-1] == ":": # The character don't have custom name
		character = character.rstrip(":")
	else: # The character have custom name and I eternally hate them
		character = lineArray[7].lstrip("(").rstrip("):")
		custom_name = lineArray[6]
	if message.find("] {{{") != -1 and message.find(" }}}[") != -1: # Remove the area indicator from message
		message = message.split("] {{{", true, 1)[1]
	if session.characters.has(character) == false: # Character not saved yet
		_save_character(character)
		placeless_messages[character] = []
	if session.characters[character]["custom_names"].has(custom_name) == false: # Custom name for character not saved yet
		session.characters[character]["custom_names"].append(custom_name)
		_check_unclaimed_movements(character, custom_name)
	if session.characters[character]["startLocation"] == null: # Character never moved
		placeless_messages[character].append({
			"time": time,
			"message": message
		})
	else:
		var location = session.characters[character]["location"]
		if session.messages.has(location) == false:
			session.messages[location] = {}
		session.messages[location][time] = {
			"speaker": character,
			"message": message
		}

func _process_IC_msg(line):
	var lineArray = line.split(" ")
	var time = _convert_time(str(lineArray[4]) + "-" + str(monthDic[lineArray[1]]) + "-" + str(lineArray[2]) + " " + lineArray[3])
	var character = lineArray[6]
	var custom_name = null
	var message = line.split(":", true, 3)[3]
	if message.find("] {{{") != -1 and message.find(" }}}[") != -1: # Remove the area indicator from message
		message = message.split("] {{{", true, 1)[1]
	if character.length() > 0 and character[character.length()-1] == ":": # The character don't have custom name
		character = character.rstrip(":")
	else: # The character have custom name and I eternally hate them
		character = lineArray[7].lstrip("(").rstrip("):")
		custom_name = lineArray[6]
	if custom_name != null:
		character = _identify(custom_name, character) # Run function to change custom name if changed or turn out the character saved with custom name
	var id = _getCharID(character)

func _getCharID(name):
	for id in session.characters:
		if session.characters[id]["name"] == name:
			return id
	_save_character(name) # Didn't find character so save it
	return session.characters.size()-1

func _isInList(name):
	var result = false

	for id in session.characters:
		if session.characters[id]["name"] == name:
			result = true
			break
	return result

func _identify(custom_name, character=null):
	var testing
	if custom_name == "Kokichi" and character == "DRRA_Kokichi":
		print("Kok ichi")
		testing == true
	var result = null

	if character != null: # Checking if character is in the nameList or custom name changed
		if nameList.has(character) == false or nameList[character] != custom_name:
			nameList[character] = custom_name
#			_nameChange(custom_name, character)

	if character != null:
		for id in session.characters:
			if session.characters[id]["name"] == custom_name:
				if testing == true:
					print("aergaerg")
				session.characters[id]["name"] = character

	for theChar in nameList:
		if nameList[theChar] == custom_name:
			result = theChar
			break

	return result

func _nameChange(name, changeTo):
	for id in session.characters:
		if session.characters[id]["name"] == name:
			session.characters[id]["name"] = changeTo
			break

func _process_movement(line):
	var character = line.split("]")[3].lstrip(" ").split("moves from")[0].rstrip(" ")
	var from = line.split("] ")[3].split(" to")[0]
	var fromID = line.split("] ")[2].split("[")[1]
	var to = line.split("] ")[4].rsplit(".")[0]
	var toID = line.split("] ")[3].split("[")[1]
	var lineArray = line.split(" ")
	var time = _convert_time(str(lineArray[4]) + "-" + str(monthDic[lineArray[1]]) + "-" + str(lineArray[2]) + " " + str(lineArray[3]))

	var gotThem = false
	if session.characters.has(character):
		gotThem = true
	if gotThem == false:
		for theChar in session.characters:
			if session.characters[theChar]["custom_names"].has(character): # Check if custom name belong to anyone
				gotThem = true
				character = theChar
#	if session.characters.has(character) == false and gotThem == false:
#		_save_character(character)
	# Save from and to areas if they are not saved yet
	if session.areas.has(fromID) == false:
		_save_area(fromID, from)
	if session.areas.has(toID) == false:
		_save_area(toID, to)
	# Save the messages what had unknown location
	if placeless_messages.has(character):
		for message in placeless_messages[character]:
			session.characters[character]["startLocation"] = fromID
			starLocation_time[character] = time
			if session.messages.has(fromID) == false:
				session.messages[fromID] = {}
			session.messages[fromID][message["time"]] = {
				"speaker": character,
				"message": message["message"]
			}
		placeless_messages.erase(character)

	if placeless_messages.has(fromID):
		for message in placeless_messages[fromID]:
			session.messages[fromID][message["time"]] = {
				"speaker": message["speaker"],
				"message": message["message"]
			}
		placeless_messages.erase(fromID)

	# Save movement and location
	if gotThem == true:
		session.characters[character]["location"] = toID
		if session.movements.has(time) == false:
			session.movements[time] = []
		session.movements[time].append({
			"character": character,
			"from": fromID,
			"to": toID
		})
	else:
		if unclaimed_movements.has(character) == false:
			unclaimed_movements[character]  = {}
			unclaimed_movements[character]["startLocation"] = fromID
			starLocation_time[character] = time
			unclaimed_movements[character]["location"] = toID
			unclaimed_movements[character]["movements"] = []
		unclaimed_movements[character]["movements"].append({
			"time": time,
			"from": fromID,
			"to": toID
		})

func _process_move(line):
	var character = line.split("]")[3].lstrip(" ").split("moves from")[0].rstrip(" ")
	var from = line.split("] ")[3].split(" to")[0]
	var fromID = line.split("] ")[2].split("[")[1]
	var to = line.split("] ")[4].rsplit(".")[0]
	var toID = line.split("] ")[3].split("[")[1]
	var lineArray = line.split(" ")
	var time = _convert_time(str(lineArray[4]) + "-" + str(monthDic[lineArray[1]]) + "-" + str(lineArray[2]) + " " + str(lineArray[3]))

	var charID = _getCharID(character)
	# Save from and to areas if they are not saved yet
	if session.areas.has(fromID) == false:
		_save_area(fromID, from)
	if session.areas.has(toID) == false:
		_save_area(toID, to)

	if session.characters[charID]["startLocation"] == null:
		session.characters[charID]["startLocation"] = fromID
	session.characters[charID]["location"] = toID
	if session.movements.has(time) == false:
		session.movements[time] = []
	session.movements[time].append({
		"character": charID,
		"from": fromID,
		"to": toID
	})

func _check_unclaimed_movements(character, custom_name = null):
	if custom_name == null:
		custom_name = character
	elif unclaimed_movements.has(custom_name) == true:
		if session.characters[character]["startLocation"] == null:
			session.characters[character]["startLocation"] = unclaimed_movements[custom_name]["startLocation"]
		else:
			if starLocation_time[custom_name] > starLocation_time[character]:
				session.characters[character]["startLocation"] = unclaimed_movements[custom_name]["startLocation"]
	if unclaimed_movements.has(custom_name):
		for movement in unclaimed_movements[custom_name]["movements"]:
			if session.movements.has(movement["time"]) == false:
				session.movements[movement["time"]] = []
			session.movements[movement["time"]].append({
				"character": character,
				"from": movement["from"],
				"to": movement["to"]
			})
		unclaimed_movements.erase(custom_name)

func _convert_time(timeStr):
	var timeDic = Time.get_datetime_dict_from_datetime_string(timeStr, false)
	var time = Time.get_unix_time_from_datetime_dict(timeDic)
	if session.startTime == 0:
		session.startTime = time
	if session.endTime < time:
		session.endTime = time
	return time

