class_name DebugMenu
extends Node

@export var enabled := true
@export var require_shift := true

var debug_menu: PopupMenu
var current_target: Node = null

func _ready() -> void:
	debug_menu = PopupMenu.new()
	add_child(debug_menu)

	debug_menu.id_pressed.connect(_on_item_selected)
	debug_menu.popup_hide.connect(_on_menu_closed)
	debug_menu.max_size = Vector2(260, 600)

func _input(event: InputEvent) -> void:
	if not enabled: return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if not require_shift or event.shift_pressed:
			var target := _get_node_under_mouse()
			if target:
				_show_menu(target)
				get_viewport().set_input_as_handled()

## Returns the node currently under the mouse position using physics queries.
func _get_node_under_mouse() -> Node:
	var space := get_viewport().world_2d.direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = get_viewport().get_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results := space.intersect_point(query)
	return results[0].collider if not results.is_empty() else null

## Displays the context menu for the target node.
func _show_menu(target: Node) -> void:
	current_target = target
	debug_menu.clear()
	debug_menu.set_meta("target", target)

	debug_menu.add_item("Print Info", 0)
	debug_menu.add_item("Toggle Visibility", 1)
	debug_menu.add_item("Print Tree", 2)
	debug_menu.add_item("Queue Free", 3)
	debug_menu.add_separator()

	if target.has_method("get_debug_options"):
		for opt in target.get_debug_options():
			debug_menu.add_item(opt.label, opt.id)

	var mouse_pos = get_viewport().get_mouse_position()
	debug_menu.position = (get_viewport().get_screen_transform() * mouse_pos).round() as Vector2i
	debug_menu.popup()

## Handles selection events from the [PopupMenu].
func _on_item_selected(id: int) -> void:
	if not is_instance_valid(current_target): return

	if current_target.has_method("execute_debug_action"):
		current_target.execute_debug_action(id)
		return

	match id:
		0:
			print("Node: ", current_target.name, " (", current_target.get_class(), ")")
			if "global_position" in current_target:
				print("Position: ", current_target.global_position)
			if "visible" in current_target:
				print("Visible: ", current_target.visible)
		1:
			if "visible" in current_target:
				current_target.visible = not current_target.visible
		2:
			print(current_target.get_path())
			current_target.print_tree()
		3:
			current_target.queue_free()

## Cleans up target reference when the menu is closed.
func _on_menu_closed() -> void:
	current_target = null
	if debug_menu.has_meta("target"):
		debug_menu.remove_meta("target")

## Toggles the enabled state of the DebugMenu globally.
static func toggle_enabled() -> void:
	var dm := Engine.get_singleton("DebugMenu") as Node
	if dm:
		dm.enabled = not dm.enabled
