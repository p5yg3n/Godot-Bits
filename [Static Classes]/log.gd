class_name Log

enum Level { DEBUG, INFO, WARN, ERROR, FATAL }

static var min_level: Level = Level.DEBUG
static var enabled_categories: Dictionary = {}
static var write_to_file: bool = false
static var log_file_path: String = "user://debug.log"
static var max_file_size_bytes: int = 2 * 1024 * 1024

static var _file: FileAccess
static var _mutex: Mutex = Mutex.new()

static func debug(category: String, message: String) -> void: _log(Level.DEBUG, category, message)
static func info(category: String, message: String) -> void:  _log(Level.INFO,  category, message)
static func warn(category: String, message: String) -> void:  _log(Level.WARN,  category, message); push_warning("[%s] %s" % [category, message])
static func error(category: String, message: String) -> void: _log(Level.ERROR, category, message); push_error("[%s] %s" % [category, message])

static func fatal(category: String, message: String) -> void:
	_log(Level.FATAL, category, message)
	push_error("FATAL: [%s] %s" % [category, message])
	close_log_file()
	if OS.has_feature("editor"):
		assert(false, "FATAL: " + message)
	else:
		OS.crash("FATAL: [%s] %s" % [category, message])


static func _log(level: Level, category: String, message: String) -> void:
	if level < min_level or (enabled_categories.size() > 0 and not enabled_categories.get(category, false)):
		return

	_mutex.lock()
	var dt := Time.get_datetime_dict_from_system()
	var ts := "%02d:%02d:%02d" % [dt.hour, dt.minute, dt.second]
	var lvl: String = Level.keys()[level]
	
	print_rich("[color=cyan]%s[/color] [color=%s][%s][/color] [b]%s:[/b] %s" % [ts, _get_color(level), lvl, category, message])
	
	if write_to_file:
		var plain := "[%s-%02d-%02d %s] [%s] %s: %s" % [dt.year, dt.month, dt.day, ts, lvl, category, message]
		_write(plain)
	
	_mutex.unlock()


static func _get_color(level: Level) -> String:
	return ["gray", "white", "yellow", "red", "darkred"][level]


static func _write(message: String) -> void:
	if not _file:
		_file = FileAccess.open(log_file_path, FileAccess.READ_WRITE)
		if _file: _file.seek_end()
		else: return
	
	if _file.get_length() >= max_file_size_bytes:
		_rotate()
	
	_file.store_line(message)
	_file.flush()


static func _rotate() -> void:
	if _file: 
		_file.close()
		_file = null
	var dir := DirAccess.open(log_file_path.get_base_dir())
	if not dir: return
	var backup := log_file_path + ".old"
	if dir.file_exists(backup): dir.remove(backup)
	dir.rename(log_file_path, backup)
	_file = FileAccess.open(log_file_path, FileAccess.WRITE)


static func close_log_file() -> void:
	_mutex.lock()
	if _file:
		_file.close()
		_file = null
	_mutex.unlock()


static func enable_category(cat: String) -> void:  
	enabled_categories[cat] = true

static func disable_category(cat: String) -> void: 
	enabled_categories.erase(cat)
