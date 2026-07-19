class_name Data

const DATA_DIR := "user://data/"

## Generates a safe filename like: user://data/player1[2026_07_18][19_53_01].dat
static func generate_timestamp_path(save_name: String = "") -> String:
	var t: Dictionary = Time.get_datetime_dict_from_system()

	var filename := "[%d_%02d_%02d][%02d_%02d_%02d].dat" % [
		t.year, t.month, t.day, t.hour, t.minute, t.second
	]

	# Prepend the save_name to the filename if one was provided
	if not save_name.is_empty():
		filename = save_name + filename

	return DATA_DIR.path_join(filename)

## Stores a dictionary to a file. Returns the path saved to on success, or empty string on failure.
static func write(save_name: String, data_to_store: Dictionary, data_file: String = "") -> String:
	if data_to_store.is_empty():
		push_warning("Data: Attempting to write empty dictionary.")
		
	if data_file.is_empty():
		data_file = generate_timestamp_path(save_name)
	
	DirAccess.make_dir_absolute(data_file.get_base_dir())
	
	var file := FileAccess.open(data_file, FileAccess.WRITE)
	if file == null:
		push_error("Data: Failed to write to %s (Error: %d)" % [data_file, FileAccess.get_open_error()])
		return ""
	
	file.store_var(data_to_store, false)  
	return data_file

## Loads a dictionary from a file. If no file provided, loads the newest file matching the save_name.
static func read(save_name: String = "", data_file: String = "") -> Dictionary:
	if data_file.is_empty():
		data_file = get_latest_save_file(save_name)
		
	if data_file.is_empty() or not FileAccess.file_exists(data_file):
		return {}
	
	var file := FileAccess.open(data_file, FileAccess.READ)
	if file == null:
		push_error("Data: Failed to read from %s (Error: %d)" % [data_file, FileAccess.get_open_error()])
		return {}
	
	var loaded_data: Variant = file.get_var(false) 
	
	if typeof(loaded_data) == TYPE_DICTIONARY:
		return loaded_data as Dictionary
		
	push_error("Data: Data file corrupted or invalid format: %s" % data_file)
	return {}

## Scans the save directory and returns the file path with the most recent modified time.
## If save_name is provided, it only looks for files that start with that name.
static func get_latest_save_file(save_name: String = "") -> String:
	if not DirAccess.dir_exists_absolute(DATA_DIR):
		return ""
		
	var dir := DirAccess.open(DATA_DIR)
	if dir == null: return ""
	
	var latest_file := ""
	var latest_time: int = 0
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".dat"):
			# Filter out files that don't belong to this specific save_name
			if not save_name.is_empty() and not file_name.begins_with(save_name):
				file_name = dir.get_next()
				continue
				
			var full_path := DATA_DIR.path_join(file_name)
			var modified_time := FileAccess.get_modified_time(full_path)
			
			if modified_time > latest_time:
				latest_time = modified_time
				latest_file = full_path
				
		file_name = dir.get_next()
		
	return latest_file
