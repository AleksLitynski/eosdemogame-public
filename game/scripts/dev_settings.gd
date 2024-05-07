class_name DevSettings

static var settings = get_settings()
static func get_settings():
	var file = FileAccess.open("res://dev_settings.json", FileAccess.READ)
	if file == null:
		file = FileAccess.open("res://__template.dev_settings.json", FileAccess.READ)
	
	var json = JSON.new()
	json.parse(file.get_as_text())
	return json.data
