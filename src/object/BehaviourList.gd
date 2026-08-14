class_name BehaviourList extends Node

@export var enabled: bool = true
@export var verbose: bool = false
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

func _log_standard(message: String) -> void:
	if not verbose: return
	print("[%s]: %s" % [CLASS_BEHAVIOUR_NODE, message])

func _log_warn(message: String) -> void:
	if not verbose: return
	push_warning("[%s]: %s" % [CLASS_BEHAVIOUR_NODE, message])

func _log_err(message: String) -> void:
	printerr("[%s]: %s" % [CLASS_BEHAVIOUR_NODE, message])

#endregion CONSOLE OUT
#region MANAGING BEHAVIOURS

# TODO: This is slow as shi*!!!!!!!!!!!!!*
static func get_behaviourlist(object: Node) -> BehaviourList:
	var _children: Array[Node] = object.get_children(false)
	for _node: Node in _children:
		if _node is BehaviourList:
			return _node as BehaviourList
	push_warning("Could not get %s from object %s" % [CLASS_BEHAVIOUR_NODE, object.to_string()])
	return null

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

func refill_behaviours_actors() -> void:
	if behaviours.is_empty(): return
	for behaviour: Behaviour in behaviours:
		behaviour.actors = actors
		behaviour.init()

func get_actor(actor_name: String) -> Node:
	return actors.get(actor_name, null)

func remove_actor(actor_name: String) -> void:
	if not actors.erase(actor_name):
		return _log_warn("Actor '%s' wasn't removed - Wasn't in actors" % actor_name)
	_log_standard("Removed actor '%s'" % actor_name)
	refill_behaviours_actors()

func add_actor(actor_name: String, node: Node, overwrite: bool = true) -> bool:
	var _can_overwrite: bool = actors.has(actor_name)
	if _can_overwrite and not overwrite:
		return true
	if not actors.set(actor_name, node):
		return false
	_log_standard("Added actor '%s' %s" % [actor_name, ["", "(overwritten)"][_can_overwrite as int]])
	refill_behaviours_actors()
	return true

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
		"%s Preprocess:\n-F_END: %s\nF_START: %s\nALWAYS: %s" % \
		[CLASS_BEHAVIOUR_NODE, normal_priority_pool, \
		high_priority_pool, vhigh_priority_pool])
	tick_normal = 0; tick_high = 0 # Reset ticks
	
var tick_normal: int = 0
var tick_high: int = 0
var tick: int = 0 # Not used, mostly for debugging
func _process(delta: float) -> void:
	if refill_actors:
		refill_behaviours_actors()
		refill_actors = false
	if not vhigh_priority_pool.is_empty():
		for _b: Behaviour in vhigh_priority_pool:
			if _b.enabled and _b.condition(delta): 
				_b.action(delta)
	if not normal_priority_pool.is_empty():
		var _f_end_b: Behaviour = normal_priority_pool[tick_normal]
		if _f_end_b.enabled and _f_end_b.condition(delta): 
			_f_end_b.action.call_deferred(delta)
	if not high_priority_pool.is_empty():
		var _f_start_b: Behaviour = high_priority_pool[tick_high]
		if _f_start_b.enabled and _f_start_b.condition(delta): 
			_f_start_b.action(delta)
	tick += 1
	tick_normal += 1
	tick_high += 1
	if tick_normal >= normal_priority_pool.size():
		tick_normal = 0
	if tick_high >= high_priority_pool.size():
		tick_high = 0
	if tick > 1000:
		tick = 0

#endregion BEHAVIOUR CLOCK
#region OVERRIDES

func _ready() -> void:
	preprocess_behaviours()

#endregion OVERRIDES
