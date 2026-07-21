class_name Log

## Log severity levels.
enum Level { DEBUG, INFO, WARN, ERROR, FATAL }

static var min_level: Level = Level.DEBUG
static var enabled_categories: Dictionary = {}
static var write_to_file: bool = false
static var log_file_path: String = "user://debug.log"
static var max_file_size_bytes: int = 2 * 1024 * 1024

static var _file: FileAccess
static var _mutex: Mutex = Mutex.new()

## Logs a debug-level message.
static func debug(cat: String, msg: String) -> void: _log(Level.DEBUG, cat, msg)
## Logs an info-level message.
static func info(cat: String, msg: String) -> void:  _log(Level.INFO, cat, msg)
## Logs a warn-level message and pushes to the editor console.
static func warn(cat: String, msg: String) -> void: 
	_log(Level.WARN, cat, msg)
	push_warning("[%s] %s" % [cat, msg])
## Logs an error-level message and pushes to the editor console.
static func error(cat: String, msg: String) -> void: 
	_log(Level.ERROR, cat, msg)
	push_error("[%s] %s" % [cat, msg])
## Logs a fatal-level message, closes the log file, and crashes the game.
static func fatal(cat: String, msg: String) -> void:
	_log(Level.FATAL, cat, msg)
	push_error("FATAL: [%s] %s" % [cat, msg])
	close_log_file()
	if OS.has_feature("editor"): assert(false, msg)
	else: OS.crash("FATAL: [%s] %s" % [cat, msg])

## Internal logging method that handles formatting and filtering.
static func _log(level: Level, cat: String, msg: String) -> void:
	if level < min_level or (not enabled_categories.is_empty() and not enabled_categories.has(cat)):
		return

	_mutex.lock()
	var dt := Time.get_datetime_dict_from_system()
	var ts := "%02d:%02d:%02d" % [dt.hour, dt.minute, dt.second]
	var lvl_str: String = Level.keys()[level]
	
	print_rich("[color=cyan]%s[/color] [color=%s][%s][/color] [b]%s:[/b] %s" % [ts, _get_color(level), lvl_str, cat, msg])
	
	if write_to_file:
		_write("[%s-%02d-%02d %s] [%s] %s: %s" % [dt.year, dt.month, dt.day, ts, lvl_str, cat, msg])
	_mutex.unlock()

## Returns the UI color string corresponding to the log [param level].
static func _get_color(level: Level) -> String:
	return ["gray", "white", "yellow", "red", "darkred"][level]

## Internal method to write messages to the log file.
static func _write(line: String) -> void:
	if not _file:
		_file = FileAccess.open(log_file_path, FileAccess.READ_WRITE)
		if _file: _file.seek_end()
		else: return
	
	if _file.get_length() >= max_file_size_bytes: _rotate()
	_file.store_line(line)
	_file.flush()

## Rotates log files by renaming current log to .old and creating a new one.
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

## Safely closes the log file.
static func close_log_file() -> void:
	_mutex.lock()
	if _file:
		_file.close()
		_file = null
	_mutex.unlock()

## Adds a category to the allowlist for logging.
static func enable_category(cat: String) -> void: enabled_categories[cat] = true
## Removes a category from the allowlist.
static func disable_category(cat: String) -> void: enabled_categories.erase(cat)
