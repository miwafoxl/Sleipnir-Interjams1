class_name GameObject extends Node

const SELF_NODE_ACTOR: String = "self"

@warning_ignore("unused_signal")
signal behaviour_event(event: StringName)

@export var enabled: bool = true
@export var verbose: bool = false
@export var scripts: Array[GDScript]

# Managed by GameObject
#var behaviours: Array[Behaviour] = []
var behaviours: Dictionary[String, Behaviour] = {}
var do_behaviour_init: bool = true 
var vhigh_priority_pool: Array[Behaviour] = [] 
var high_priority_pool: Array[Behaviour] = []
var normal_priority_pool: Array[Behaviour] = []
# End Managed by GameObject


# Actor -> A node in which the behaviour needs to act upon
# Behaviour -> An predictable operation where action is done to Actors
# Example: A "Bullet" Behaviour receives an actor Node2D which it
# needs in order to move the bullet to a desired direction, it
# can't do it on its own.

 #region CONSOLE OUT

func _log_standard(message: String) -> void:
	if not verbose: return
	print("[GameObject]: %s" % [message])

func _log_warn(message: String) -> void:
	if not verbose: return
	push_warning("[GameObject]: %s" % [message])

func _log_err(message: String) -> void:
	printerr("[GameObject]: %s" % [message])

#endregion CONSOLE OUT
#region MANAGING BEHAVIOURS

# TODO: This is slow as shi*!!!!!!!!!!!!!*
## Obtains the [GameObject] if it's present in [code]node[/code] and returns it.
## Returns [code]null [/code] if not found.[br]
## [codeblock lang=gdscript]
## # Does this node have Bullet behaviour?
## var list := GameObject.get_gameobject(some_node);
## var bullet_behaviour := list.get_behaviours(&"bullet");
## if not behaviours.is_empty(): # It must be a bullet...
## 		glass_break()  # Let's shatter!
## [/codeblock][br][br]
## Please use [method GameObject.get_behaviour_from] or 
## [method GameObject.has_behaviour] instead.
## @deprecated
static func get_gameobject(object: Node) -> GameObject:
	if object is GameObject:
		return object as GameObject
	push_warning("Could not get GameObject from object %s" % object.to_string())
	return null

## Obtains a [Behaviour] from a [Node] that has [GameObject]. 
## Returns [code]null[/code] if GameObject isn't present in object.[br]
## [codeblock lang=gdscript]
## var bullet := GameObject.get_behaviour_from(some_node, &"bullet");
## if not bullet == null: # It must be a bullet...
## 		bullet.set_speed(36)  # How convenient
## [/codeblock]
static func get_behaviour_from(object: Node, tag: String) -> Behaviour:
	var _behaviour: Behaviour = null
	if object is GameObject:
		_behaviour = object.get_behaviour(tag)
	if _behaviour == null:
		push_warning("Could not get behaviour '%s' from object %s" % [tag, object.get_path()])
	return _behaviour

## Checks whether [code]behaviour_name[/code] is present in a [GameObject] of object. 
## Returns [code]false[/code] if behaviour was not found or GameObject isn't 
## present in object.[br]
## [codeblock lang=gdscript]
## var toxic: bool = GameObject.has_behaviour(some_node, &"toxic");
## if toxic:
## 		self.poison()
## [/codeblock]
static func has_behaviour(object: Node, tag: String) -> bool:
	var _behaviour: Behaviour = null
	if object is GameObject:
		var _gameobject: GameObject = object as GameObject
		if not _gameobject.get_behaviour(tag) == null:
			return true
	return false

## Set this GameObject enabled. A disabled GameObject will disable
## all its containing [Behaviour]s.
func set_enabled(enable: bool) -> void:
	enabled = enable

## Obtains a single behaviour that match [code]tag[/code]. Returns null
## if no match was found.
func get_behaviour(tag: String = "") -> Behaviour:
	return behaviours.get(tag, null)

## Obtains all behaviours that matches [code]expr[/code]. Returns an empty
## [Array] if none matched.
func get_behaviour_match(expr: String = "") -> Array[Behaviour]:
	var _selected: Array[Behaviour] = []
	for behaviour_tag: String in behaviours.keys():
		if behaviour_tag.match(expr):
			_selected.append(behaviours.get(behaviour_tag))
	return _selected

## Remove behaviours from list that match [code]tag[/code].
#func remove_behaviours(tag: StringName = &"") -> void:
	#if tag.is_empty(): return
	#var _count = behaviours.count(tag)
	#var _remove: Callable = func(_b: Behaviour) -> bool:
		#return not _b.name == tag
	#behaviours = behaviours.filter(_remove)
	#_log_standard("Removed %s '%s' behaviour(s)." % [_count, tag])

## Insert the behaviour [code]behaviour[/code] following the index [code]at_index[/code].
## If negative, the value will be considered from the end of the array.
func insert_behaviour(behaviour: Behaviour, tag: String) -> bool:
	var _script: GDScript = behaviour.get_script()
	var _name: String = tag
	if _script == null:
		return false
	if tag.is_empty():
		_name = _script.get_global_name().to_lower()
	preprocess_behaviours.call_deferred()
	add_script(_script, _name)
	_log_standard("Inserted behaviour '%s'" % behaviour.name)
	return behaviours.set(_name, behaviour)
	
#endregion MANAGING BEHAVIOURS
#region MANAGING ACTORS

## Updates each behaviour with a new [code]actors[/code] value, then runs [code]init()[/code].
## This ensures that all behaviours have a reference to the actors array. It's ran
## automatically by [method GameObject.preprocess_behaviours] and other methods.
func init_behaviours(behaviour_array: Array[Behaviour]) -> void:
	for behaviour: Behaviour in behaviour_array:
		behaviour.actor = self
		if not behaviour.event.is_connected(dispatch_event):
			behaviour.event.connect(dispatch_event)
		behaviour.init()

#region EVENT DISPATCHER

func dispatch_event(event: StringName) -> void:
	behaviour_event.emit(event)

#endregion EVENT DISPATCHER
#region BEHAVIOUR CLOCK

## Called automatically by [GameObject], sorts behaviours into three different pools: 
## [b]F_END[/b], [b]F_START[/b] and [b]ALWAYS[/b]. Those are then stored at variables
## [code]normal_priority_pool[/code], [code]high_priority_pool[/code] and
## [code]vhigh_priority_pool[/code]. [br][br]If behaviours are
## set to [code]AUTOMATIC[/code], it will try to balance [code]normal_priority_pool[/code]
## and [code]high_priority_pool[/code] array sizes evenly in an effort to minimize the
## the behaviour clock from favoring a single behaviour by checking it every frame.
func preprocess_behaviours() -> int:
	var _auto: bool = false
	var _high_priority_spool: Array[Behaviour] = [] # Subpool
	var _normal_priority_spool: Array[Behaviour] = [] # Subpool
	if behaviours.is_empty(): return -1
	for _b: Behaviour in behaviours.values():
		if _b.enabled:
			match _b.process:
				Behaviour.BehaviourMode.F_END:
					normal_priority_pool.append(_b)
				Behaviour.BehaviourMode.F_START:
					high_priority_pool.append(_b)
				Behaviour.BehaviourMode.ALWAYS:
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
		"Behaviours Preprocess:\n\t-F_END: %s\n\tF_START: %s\n\tALWAYS: %s" % \
		[normal_priority_pool, high_priority_pool, vhigh_priority_pool])
	tick_normal = 0; tick_high = 0 # Reset ticks
	return 0
	
var tick_normal: int = 0
var tick_high: int = 0
var tick: int = -1
func _process(delta: float) -> void:
	if tick == -1: return # Disable processing
	if do_behaviour_init:
		init_behaviours(behaviours.values())
		do_behaviour_init = false
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

func _physics_process(delta: float) -> void:
	if tick == -1: return # Disable processing
	if do_behaviour_init:
		init_behaviours(behaviours.values())
		do_behaviour_init = false
	if not behaviours.is_empty():
		for _b: Behaviour in behaviours.values():
			if _b.enabled and _b.condition_physics(delta): 
				_b.action_physics(delta)

#endregion BEHAVIOUR CLOCK
#region

func add_script(script: GDScript, tag: String) -> bool:
	var _node: Node = Node.new()
	_node.set_script(script)
	if _node is Behaviour:
		var _behaviour: Behaviour = _node
		behaviours.set(tag, _behaviour)
		add_child(_node, false, Node.INTERNAL_MODE_FRONT)
		return true
	return false

#endregion SCRIPTS
#region OVERRIDES

func _ready() -> void:
	# Transform scripts into Behaviours
	_log_standard("Logging GameObject at %s" % self.get_path())
	for i in scripts.size():
		var _script: GDScript = scripts[i]
		var _tag: String = _script.get_global_name()
		if not add_script(_script, _tag):
			_log_err("Script %s at index %s does not extend class Behaviour" % [_tag, i])
	# Duplicate behaviours and pre-process before running
	if tick == -1:
		tick = preprocess_behaviours()
	
#endregion OVERRIDES
