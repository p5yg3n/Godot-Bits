class_name DataManager

## Data Manager - Fast, safe, and reliable save system
## Configure these to fit your game
const DIR := "user://data/"
static var EXT := ".dat"

## Optional AES encryption key (set before use for secure saves)
static var encryption_key: String = ""


## Saves data with atomic write + optional encryption. Returns true on success.
static func save(filename: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := DIR.path_join(filename + EXT)
	var tmp := path + ".tmp"
	
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if not file:
		push_error("DataManager: Failed to open temp file for writing")
		return false
	
	var payload := data.duplicate(true)
	if not encryption_key.is_empty():
		file.store_var(payload, true)  # compression
		file.close()
		# Re-open with encryption
		file = FileAccess.open_encrypted_with_pass(tmp, FileAccess.WRITE, encryption_key)
		if not file: return false
		file.store_var(payload, true)
	else:
		file.store_var(payload, true)
	
	file.close()
	return DirAccess.rename_absolute(tmp, path) == OK


## Loads data. Returns empty dict if missing, corrupted, or wrong type.
static func load(filename: String) -> Dictionary:
	var path := DIR.path_join(filename + EXT)
	if not FileAccess.file_exists(path):
		return {}
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	
	# Try encrypted first if key is set
	if not encryption_key.is_empty():
		file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, encryption_key)
		if not file:
			push_warning("DataManager: Decryption failed for " + filename)
			file = FileAccess.open(path, FileAccess.READ)  # fallback
	
	var data = file.get_var(true)
	return data if data is Dictionary else {}


## Returns list of save basenames (without extension)
static func list_saves() -> Array[String]:
	var dir := DirAccess.open(DIR)
	if not dir: return []
	
	return Array(dir.get_files()) \
		.filter(func(f): return f.ends_with(EXT)) \
		.map(func(f): return f.get_basename())


## Deletes a save file
static func delete(filename: String) -> bool:
	return DirAccess.remove_absolute(DIR.path_join(filename + EXT)) == OK


## Quick existence check
static func exists(filename: String) -> bool:
	return FileAccess.file_exists(DIR.path_join(filename + EXT))


## Get the most recent save (by modification time)
static func get_latest() -> String:
	var files := list_saves()
	if files.is_empty(): return ""
	
	var latest := ""
	var max_time := -1
	
	for f in files:
		var full := DIR.path_join(f + EXT)
		var t := FileAccess.get_modified_time(full)
		if t > max_time:
			max_time = t
			latest = f
	
	return latest
