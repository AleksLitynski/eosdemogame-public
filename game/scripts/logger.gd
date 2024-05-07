class_name Logger

static var logger = Logger.new()

signal on_log_raw
signal on_log
var log_level = LogLevels.INFO
var modules = {}
var start_time = 0
var log_level_mapping

enum LogLevels {
	NEVER = 0,
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
	FATAL = 5,
}

func level_to_string(level): return LogLevels.keys()[level].to_lower()
func string_to_level(str_nm) -> LogLevels: return LogLevels.keys().map(func(k): return k.to_lower()).find(str_nm) as LogLevels

class ModuleLogger:
	var module_name
	var min_log_level = LogLevels.INFO
	var logger
	
	func debug(message): logger.log(module_name, LogLevels.DEBUG, message)
	func info(message): logger.log(module_name, LogLevels.INFO, message)
	func warn(message): logger.log(module_name, LogLevels.WARN, message)
	func error(message): logger.log(module_name, LogLevels.ERROR, message)
	func fatal(message): logger.log(module_name, LogLevels.FATAL, message)

func _init():
	log_level = string_to_level(DevSettings.settings.logging.log_level)
	start_time = Time.get_unix_time_from_system()
	_add_module("default")
	on_log.connect(func(time, module, level, message):
		print("[" + time + "] [" + module + "] [" + level_to_string(level) + "] " + message)
	)

	on_log.connect(func(time, module, level, message):
		var msg = Label.new()
		msg.text = "[" + time + "] [" + module + "] [" + level_to_string(level) + "] " + message
		msg.add_theme_font_size_override("font_size", 12)
		var sb := StyleBoxFlat.new()
		sb.border_width_bottom = 1
		sb.border_color = Color.GRAY
		sb.bg_color = Color.TRANSPARENT
		sb.set_content_margin_all(5)
		msg.add_theme_stylebox_override("normal", sb)
		
		if Global.main && Global.main.M:
			Global.main.M.logs_holder.add_child(msg)
			Global.main.M.logs_holder.move_child(msg, 0)
	)


func _add_module(name):
	if modules.has(name): return modules[name]
	var mod_logger = ModuleLogger.new()
	mod_logger.logger = self
	mod_logger.module_name = name
	for module_name_pattern in DevSettings.settings.logging.module_log_levels:
		if RegEx.create_from_string(module_name_pattern).search(name) != null:
			mod_logger.min_log_level = string_to_level(DevSettings.settings.logging.module_log_levels[module_name_pattern])
			break
	modules[name] = mod_logger
	return mod_logger

func log(module, level, message):
	var time = str(round(Time.get_unix_time_from_system() - start_time))
	on_log_raw.emit(time, module, level, message)
	if level >= modules[module].min_log_level && level >= log_level:
		on_log.emit(time, module, level, message)

static func add_module(name):
	if logger == null: logger = Logger.new()
	return logger._add_module(name)
static func mod(name):
	return logger.modules[name]
static func debug(message): logger.modules.default.debug(message)
static func info(message): logger.modules.default.info(message)
static func warn(message): logger.modules.default.warn(message)
static func error(message): logger.modules.default.error(message)
static func fatal(message): logger.modules.default.fatal(message)
