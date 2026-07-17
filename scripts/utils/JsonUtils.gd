class_name JsonUtils

static func read_json_file(file: String) -> Dictionary:
	# Check if file exists
	if !FileAccess.file_exists(file):
		printerr("File" + file + "not found!")
		return {}
	
	# Read the save file
	var file_reader := FileAccess.open(file, FileAccess.READ) # Open the file
	var json := JSON.new()
	var err := json.parse(file_reader.get_as_text()) # Parse the file's data
	file_reader.close()
	if err == OK:
		return json.data
	else:
		print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
	
	return {}

static func write_json_file(file: String, data: Dictionary) -> void:
	var file_writer := FileAccess.open(file, FileAccess.WRITE)
	
	var json_string := JSON.stringify(data)
	file_writer.store_string(json_string) # Write this data into the save file
