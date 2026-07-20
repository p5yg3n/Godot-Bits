class_name StateMachine
extends Node

## The state to enter when the machine first initializes.
@export var initial_state: State

## The currently active [State].
var current_state: State
## A dictionary mapping state names to their corresponding [State] nodes.
var states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(_on_child_transition)
			child.state_machine = self
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

## Handles transitioning from the [member current_state] to the [param new_state_name].
func _on_child_transition(new_state_name: String) -> void:
	if current_state and current_state.name.to_lower() == new_state_name.to_lower():
		return

	var new_state: State = states.get(new_state_name.to_lower())
	if not new_state:
		push_warning("StateMachine: State '" + new_state_name + "' does not exist.")
		return

	if current_state:
		current_state.exit()
	
	new_state.enter()
	current_state = new_state
