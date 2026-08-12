class_name Behaviour extends Resource

@export var name: StringName = &""
@export var enabled: bool = true
@export var priority: BehaviourPriority = BehaviourPriority.NORMAL

enum BehaviourPriority {
	NORMAL,		# Action is ran at the end of the frame
	HIGH,		# Action is ran at the start of the frame
	VERY_HIGH,	# TODO: Condition is checked frame by frame,
				# Action is ran at the start of the frame
}

# This variable will be autofilled by the BehaviourList before
# condition() and action() is ran.
var actors: Dictionary[String, Node]

#region MANAGING BEHAVIOUR

func set_enabled(enable: bool) -> void:
	enabled = enable

#endregion MANAGING BEHAVIOUR
#region OVERRIDEABLES

@warning_ignore("unused_parameter")
func condition(delta: float) -> bool:
	return true

@warning_ignore("unused_parameter")
func action(delta: float) -> void:
	return

#endregion OVERRIDEABLES
