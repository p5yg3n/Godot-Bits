class_name Log

enum Level {
	DEBUG,
	INFO,
	WARN,
	ERROR,
	FATAL
}

# --- Configuration ---
static var min_level: Level = Level.DEBUG
# Use a Dictionary for O(1) lookups: { "CategoryName": true }
static var enabled_categories: Dictionary = {} 
static var write_to_file: bool = false
static var log_file_path: String = "user://debug.log"
static var max_file_size_bytes: int = 2 * 1024 * 1024 # 2 MB limit

static var _file: FileAccess
static var _mutex: Mutex = Mutex.new()

# --- Public API ---

static func debug(category: String, message: String) -> void:
	_process_log(Level.DEBUG, category, message, "gray")

static func info(category: String, message: String) -> void:
	_process_log(Level.INFO, category, message, "white")

static func warn(category: String, message: String) -> void:
	_process_log(Level.WARN, category, message, "yellow")
	push_warning("[%s] %s" % [category, message])

static func error(category: String, message: String) -> void:
	_process_log(Level.ERROR, category, message, "red")
	push_error("[%s] %s" % [category, message])

static func fatal(category: String, message: String) -> void:
	_process_log(Level.FATAL, category, message, "darkred")
	push_error("FATAL: [%s] %s" % [category, message])
	
	# Ensure log is flushed to disk before crashing
	close_log_file()
	
	if OS.has_feature("editor"):
		assert(false, "FATAL ERROR: " + message)
	else:
		OS.crash("FATAL ERROR: [%s] %s" % [category, message])

# --- Internal Engine ---

static func _process_log(level: Level, category: String, message: String, color: String) -> void:
	if level < min_level:
		return
		
	# Dictionary O(1) lookup
	if enabled_categories.size() > 0 and not enabled_categories.has(category):
		return

	_mutex.lock()

	var datetime = Time.get_datetime_dict_from_system()
	var time_str = "%02d:%02d:%02d" % [datetime.hour, datetime.minute, datetime.second]
	var date_str = "%04d-%02d-%02d" % [datetime.year, datetime.month, datetime.day]
	var level_str = Level.keys()[level]
	
	# Console Output
	print_rich("[color=cyan]%s[/color] [color=%s][%s][/color] [b]%s:[/b] %s" % [time_str, color, level_str, category, message])
	
	# File Output
	if write_to_file:
		var plain_msg = "[%s %s] [%s] %s: %s" % [date_str, time_str, level_str, category, message]
		_write_to_file(plain_msg)

	_mutex.unlock()

static func _write_to_file(message: String) -> void:
	# Open file if needed
	if _file == null:
		_file = FileAccess.open(log_file_path, FileAccess.WRITE_READ)
		if _file == null:
			push_warning("Log failed to open: " + error_string(FileAccess.get_open_error()))
			return
		_file.seek_end()

	# Rotation Logic (Already inside _mutex from _process_log)
	if _file.get_length() >= max_file_size_bytes:
		_file.close()
		var dir = DirAccess.open(log_file_path.get_base_dir())
		if dir:
			var old_path = log_file_path + ".old"
			if dir.file_exists(old_path):
				dir.remove(old_path)
			dir.rename(log_file_path, old_path)
		
		_file = FileAccess.open(log_file_path, FileAccess.WRITE)
		if _file == null: return

	_file.store_line(message)
	_file.flush() # Ensure it's on disk

static func close_log_file() -> void:
	_mutex.lock()
	if _file != null:
		_file.close()
		_file = null
	_mutex.unlock()

# --- Lifecycle Management ---
# Call this from your Main scene's _notification function:
# if what == NOTIFICATION_WM_CLOSE_REQUEST: Log.close_log_file()
