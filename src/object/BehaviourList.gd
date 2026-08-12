class_name BehaviourList extends Node

@export var enabled: bool = true
@export var actors: Dictionary[String, Node] = {} # Actor ID: Node
@export var behaviours: Array[Behaviour] = []

var refill_actors: bool = true # Managed by BehaviourList

# Actor -> A node in which the behaviour needs to act upon
# Behaviour -> An predictable operation where action is done to Actors
# Example: A "Bullet" Behaviour receives an actor Node2D which it
# needs in order to move the bullet to a desired direction, it
# can't do it on its own.

 #region CONSOLE OUT

static func _log_standard(message: String) -> void:
	print("[BehaviourList]: %s" % message)

static func _log_warn(message: String) -> void:
	push_warning("[BehaviourList]: %s" % message)

static func _log_err(message: String) -> void:
	printerr("[BehaviourList]: %s" % message)

#endregion CONSOLE OUT
#region MANAGING BEHAVIOURS

func set_enabled(enable: bool) -> void:
	enabled = enable

func get_behaviours(behaviour_name: StringName = &"") -> Array[Behaviour]:
	if name.is_empty(): return behaviours
	var _selected: Array[Behaviour] = []
	for behaviour: Behaviour in behaviours:
		if behaviour.name == behaviour_name:
			_selected.append(behaviour)
	return _selected

func remove_behaviours(behaviour_name: StringName = &"") -> void:
	if name.is_empty(): return
	var _indexes: Array[int]
	var _remove: Callable = func(_b: Behaviour) -> bool:
		return not _b.name == behaviour_name
	behaviours = behaviours.filter(_remove)

func append_behaviour(behaviour: Behaviour, at_index: int = -1) -> bool:
	return OK == behaviours.insert(at_index, behaviour)
	
#endregion MANAGING BEHAVIOURS
#region MANAGING ACTORS



#endregion MANAGING ACTORS
#region BEHAVIOUR CLOCK

var tick: int = 0
func _process(_delta: float) -> void:
	if refill_actors:
		for behaviour: Behaviour in behaviours:
			behaviour.actors = actors
		refill_actors = false
	if enabled and tick < behaviours.size():
		var _b: Behaviour = behaviours[tick]
		if _b.enabled and _b.condition(_delta):
			match _b.priority:
				Behaviour.BehaviourPriority.HIGH:
					_b.action(_delta)
				Behaviour.BehaviourPriority.NORMAL:
					_b.action.call_deferred(_delta)
		tick += 1
	else:
		tick = 0

#endregion BEHAVIOUR CLOCKq
