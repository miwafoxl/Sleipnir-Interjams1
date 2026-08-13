class_name BehaviourList extends Node

const LOG_VERBOSE: bool = true

@export var enabled: bool = true
@export var actors: Dictionary[String, Node] = {} # Actor ID: Node
@export var behaviours: Array[Behaviour] = []

# Managed by BehaviourList
var refill_actors: bool = true 
var vhigh_priority_pool: Array[Behaviour] = [] 
var high_priority_pool: Array[Behaviour] = []
var normal_priority_pool: Array[Behaviour] = []
# End Managed by BehaviourList


# Actor -> A node in which the behaviour needs to act upon
# Behaviour -> An predictable operation where action is done to Actors
# Example: A "Bullet" Behaviour receives an actor Node2D which it
# needs in order to move the bullet to a desired direction, it
# can't do it on its own.

 #region CONSOLE OUT

static func _log_standard(message: String) -> void:
	if not LOG_VERBOSE: return
	print("[BehaviourList]: %s" % message)

static func _log_warn(message: String) -> void:
	if not LOG_VERBOSE: return
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
	var _count = behaviours.count(behaviour_name)
	var _remove: Callable = func(_b: Behaviour) -> bool:
		return not _b.name == behaviour_name
	behaviours = behaviours.filter(_remove)
	_log_standard("Removed %s '%s' behaviour(s)." % [_count, behaviour_name])

func insert_behaviour(behaviour: Behaviour, at_index: int = -1) -> bool:
	preprocess_behaviours.call_deferred()
	_log_standard("Inserted behaviour '%s'" % behaviour.name)
	return OK == behaviours.insert(at_index, behaviour)
	
#endregion MANAGING BEHAVIOURS
#region MANAGING ACTORS

func get_actor(actor_name: String) -> Node:
	return actors.get(actor_name, null)

func remove_actor(actor_name: String) -> void:
	if not actors.erase(actor_name):
		_log_warn("Actor '%s' wasn't removed - Wasn't in actors" % actor_name)
	_log_standard("Append actor '%s'" % actor_name)

func append_actor(actor_name: String, node: Node) -> bool:
	_log_standard("Append actor '%s'" % actor_name)
	return actors.set(actor_name, node)

#endregion MANAGING ACTORS
#region BEHAVIOUR CLOCK

func preprocess_behaviours() -> void:
	var _auto: bool = false
	var _high_priority_spool: Array[Behaviour] = [] # Subpool
	var _normal_priority_spool: Array[Behaviour] = [] # Subpool
	if behaviours.is_empty(): return
	for _b: Behaviour in behaviours:
		if _b.enabled:
			match _b.process:
				Behaviour.ProcessMode.F_END:
					normal_priority_pool.append(_b)
				Behaviour.ProcessMode.F_START:
					high_priority_pool.append(_b)
				Behaviour.ProcessMode.ALWAYS:
					vhigh_priority_pool.append(_b)
				_:
					if _auto:
						_normal_priority_spool.append(_b) 
					else:
						_high_priority_spool.append(_b)
					_auto = not _auto
	# Adds subpools to the end of master pool
	for _b: Behaviour in _high_priority_spool:
		high_priority_pool.append(_b)
	for _b: Behaviour in _normal_priority_spool:
		normal_priority_pool.append(_b)
	_log_standard( \
		"BehaviourList Preprocess:\n-F_END: %s\nF_START: %s\nALWAYS: %s" % \
		[normal_priority_pool, high_priority_pool, vhigh_priority_pool])
	# Reset ticks
	tick_normal = 0
	tick_high = 0
	
var tick_normal: int = 0
var tick_high: int = 0
func _process(delta: float) -> void:
	if refill_actors:
		for behaviour: Behaviour in behaviours:
			behaviour.actors = actors
		refill_actors = false
	if not vhigh_priority_pool.is_empty():
		for _b: Behaviour in vhigh_priority_pool:
			if _b.condition(delta): _b.action(delta)
	var _f_end_b: Behaviour = normal_priority_pool[tick_normal]
	var _f_start_b: Behaviour = high_priority_pool[tick_high]
	if _f_end_b.condition(delta): _f_end_b.action.call_deferred(delta)
	if _f_start_b.condition(delta): _f_start_b.action(delta)
	tick_normal = (tick_normal + 1) % (normal_priority_pool.size() - 1)
	tick_high = (tick_high + 1) % (high_priority_pool.size() - 1)

#endregion BEHAVIOUR CLOCK

#region OVERRIDES

func _ready() -> void:
	preprocess_behaviours()

#endregion OVERRIDES
