class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	# Loop through all child nodes to find the states
	for child in get_children():
		if child is State:
			# Store the state in a dictionary using its name (in lowercase) as the key
			states[child.name.to_lower()] = child
			# Connect the state's transition signal to our state machine
			child.transitioned.connect(on_child_transition)
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

# Handles the signal emitted by the current state
func on_child_transition(state: State, new_state_name: String) -> void:
	# Ignore if the signal didn't come from the active state
	if state != current_state:
		return
	
	var new_state: State = states.get(new_state_name.to_lower())
	if not new_state:
		push_warning("State Machine: State '" + new_state_name + "' does not exist.")
		return
	
	# Swap the states
	if current_state:
		current_state.exit()
		
	new_state.enter()
	current_state = new_state
