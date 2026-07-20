class_name State
extends Node

## Reference to the [StateMachine] node controlling this state.
var state_machine: StateMachine

## Emitted when the state wants to hand over control to another state.
@warning_ignore("unused_signal")
signal transitioned(new_state_name: String)

func _ready() -> void:
	set_process(false)
	set_physics_process(false)

## Called when the state machine enters this state. 
## Used to initialize state-specific logic.
func enter() -> void:
	pass

## Called when the state machine exits this state. 
## Used to clean up state-specific logic.
func exit() -> void:
	pass

## Called every frame. Replaces [method Node._process].
func update(_delta: float) -> void:
	pass

## Called every physics frame. Replaces [method Node._physics_process].
func physics_update(_delta: float) -> void:
	pass
