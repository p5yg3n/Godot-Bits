extends Panel
class_name FileDrop

## Emitted when a file is dropped within this control's bounds.
signal file_received(path: String)

## Only accept files with these extensions (e.g., ["png", "jpg", "txt"]).
## If empty, all file types are accepted.
@export var allowed_extensions: Array[String] = []
## Text displayed in the center of the drop zone.
@export var label_text: String = "Drop files here"

## Background color of the control.
@export var bg_color: Color = Color(0.2, 0.2, 0.2, 0.5)

var _label: Label
var _style_box: StyleBoxFlat

func _ready() -> void:
	# Setup StyleBox
	_style_box = StyleBoxFlat.new()
	add_theme_stylebox_override("panel", _style_box)
	_style_box.bg_color = bg_color
	
	# Setup Label
	_label = Label.new()
	_label.text = label_text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.anchors_preset = Control.PRESET_FULL_RECT
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	
	# Listen to OS-level file drops
	get_window().files_dropped.connect(_handle_files_dropped)

func _handle_files_dropped(files: PackedStringArray) -> void:
	# Only process if drop occurs over this control
	if get_global_rect().has_point(get_global_mouse_position()):
		for file in files:
			if _is_file_allowed(file):
				file_received.emit(file)
			else:
				push_warning("File rejected: " + file.get_file())

## Returns true if the file extension is allowed.
func _is_file_allowed(path: String) -> bool:
	if allowed_extensions.is_empty():
		return true
	return path.get_extension().to_lower() in allowed_extensions
