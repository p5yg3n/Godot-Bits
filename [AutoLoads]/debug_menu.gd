extends Node

var debug_menu: PopupMenu

func _ready():
	debug_menu = PopupMenu.new()
	add_child(debug_menu)
	debug_menu.id_pressed.connect(_on_menu_item_selected)
	debug_menu.popup_hide.connect(_on_menu_closed)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if event.shift_pressed:
			var target = _get_node_under_mouse()
			if target:
				_show_menu(target)
				get_viewport().set_input_as_handled()

func _get_node_under_mouse() -> Node:
	var space = get_viewport().world_2d.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_viewport().get_mouse_position()

	# Optional: Only detect specific layers (e.g., Layer 1 = 1, Layer 2 = 2)
	# query.collision_mask = 1

	var result = space.intersect_point(query)
	return result.front().collider if result.size() > 0 else null

func _show_menu(target: Node):
	debug_menu.clear()
	debug_menu.set_meta("target", target)
	
	# Allow target to define its own items, or fallback to defaults
	if target.has_method("get_debug_options"):
		for item in target.get_debug_options():
			debug_menu.add_item(item.label, item.id)
	else:
		debug_menu.add_item("Print Name", 0)
		debug_menu.add_item("Delete", 1)
		
	debug_menu.position = get_viewport().get_mouse_position()
	debug_menu.popup()

func _on_menu_item_selected(id: int):
	var target = debug_menu.get_meta("target")
	if not is_instance_valid(target): return
	
	if target.has_method("execute_debug_action"):
		target.execute_debug_action(id)
	else:
		match id:
			0: print("Node: ", target.name)
			1: target.queue_free()

func _on_menu_closed():
	debug_menu.remove_meta("target")
