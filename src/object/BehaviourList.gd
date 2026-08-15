class_name BehaviourList extends Node

const PARENT_NODE_ACTOR: String = "parent"

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
	print("[BehaviourList]: %s" % [message])

func _log_warn(message: String) -> void:
	if not verbose: return
	push_warning("[BehaviourList]: %s" % [message])

func _log_err(message: String) -> void:
	printerr("[BehaviourList]: %s" % [message])

#endregion CONSOLE OUT
#region MANAGING BEHAVIOURS

# TODO: This is slow as shi*!!!!!!!!!!!!!*
## Obtains the [BehaviourList] if it's present in [code]node[/code] and returns it.
## Returns [code]null [/code] if not found.[br]
## [codeblock lang=gdscript]
## # Does this node have Bullet behaviour?
## var list := BehaviourList.get_behaviourlist(some_node);
## var bullet_behaviour := list.get_behaviours(&"bullet");
## if not behaviours.is_empty(): # It must be a bullet...
## 		glass_break()  # Let's shatter!
## [/codeblock]
static func get_behaviourlist(object: Node) -> BehaviourList:
	var _children: Array[Node] = object.get_children(false)
	for _node: Node in _children:
		if _node is BehaviourList:
			return _node as BehaviourList
	push_warning("Could not get BehaviourList from object %s" % object.to_string())
	return null

## Set this BehaviourList enabled. A disabled BehaviourList will disable
## all its containing [Behaviour]s.
func set_enabled(enable: bool) -> void:
	enabled = enable

## Obtains a single behaviour that match [code]behaviour_name[/code]. Returns null
## if no match was found.
func get_behaviour(behaviour_name: StringName = &"") -> Behaviour:
	for behaviour: Behaviour in behaviours:
		if behaviour.name == behaviour_name:
			return behaviour
	return null

## Obtains all behaviours that match [code]behaviour_name[/code]. Returns an empty
## [Array] if no match was found.
func get_behaviours(behaviour_name: StringName = &"") -> Array[Behaviour]:
	if behaviour_name.is_empty(): return behaviours
	var _selected: Array[Behaviour] = []
	for behaviour: Behaviour in behaviours:
		if behaviour.name == behaviour_name:
			_selected.append(behaviour)
	return _selected

## Remove behaviours from list that match [code]behaviour_name[/code].
func remove_behaviours(behaviour_name: StringName = &"") -> void:
	if name.is_empty(): return
	var _count = behaviours.count(behaviour_name)
	var _remove: Callable = func(_b: Behaviour) -> bool:
		return not _b.name == behaviour_name
	behaviours = behaviours.filter(_remove)
	_log_standard("Removed %s '%s' behaviour(s)." % [_count, behaviour_name])

## Insert the behaviour [code]behaviour[/code] following the index [code]at_index[/code].
## If negative, the value will be considered from the end of the array.
func insert_behaviour(behaviour: Behaviour, at_index: int = -1) -> bool:
	preprocess_behaviours.call_deferred()
	_log_standard("Inserted behaviour '%s'" % behaviour.name)
	return OK == behaviours.insert(at_index, behaviour)
	
#endregion MANAGING BEHAVIOURS
#region MANAGING ACTORS

## Updates each behaviour with a new [code]actors[/code] value, then runs [code]init()[/code].
## This ensures that all behaviours have a reference to the actors array. It's ran
## automatically by [method BehaviourList.preprocess_behaviours] and other methods.
func refill_behaviours_actors() -> void:
	actors.set(PARENT_NODE_ACTOR, get_parent())
	for behaviour: Behaviour in behaviours:
		behaviour.actors = actors
		behaviour.init()

## Gets actor [code]actor_name[/code] present in actors dictionary. Returns 
## [code]null[/code] if it wasn't found. If no name is specified, returns
## parent node.
func get_actor(actor_name: String = PARENT_NODE_ACTOR) -> Node:
	return actors.get(actor_name, null)

## Remove behaviours from list that match [code]actor_name[/code].
func remove_actor(actor_name: String) -> void:
	if not actors.erase(actor_name):
		return _log_warn("Actor '%s' wasn't removed - Wasn't in actors" % actor_name)
	_log_standard("Removed actor '%s'" % actor_name)
	refill_behaviours_actors()

## Adds a new actor [code]actor_name[/code] with [code]node[/code] value that can be accessed
## by behaviours (See [method Behaviour.get_actor]). If [code]overwrite[/code] is true, 
## overwrites on top of existing data. Returns true if operation was successful.
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

## Called automatically by [BehaviourList], sorts behaviours into three different pools: 
## [b]F_END[/b], [b]F_START[/b] and [b]ALWAYS[/b]. Those are then stored at variables
## [code]normal_priority_pool[/code], [code]high_priority_pool[/code] and
## [code]vhigh_priority_pool[/code]. [br][br]If behaviours are
## set to [code]AUTOMATIC[/code], it will try to balance [code]normal_priority_pool[/code]
## and [code]high_priority_pool[/code] array sizes evenly in an effort to minimize the
## the behaviour clock from favoring a single behaviour by checking it every frame.
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
		"Behaviours Preprocess:\n-F_END: %s\nF_START: %s\nALWAYS: %s" % \
		[normal_priority_pool, high_priority_pool, vhigh_priority_pool])
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
