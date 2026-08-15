@abstract
class_name Behaviour extends Resource

@export_category("Behaviour Settings")
@export var name: StringName = &"" ## A StringName that will be used for future referencing.
@export var enabled: bool = true ## Sets if the behaviour is currently active
@export var process: ProcessMode = ProcessMode.AUTOMATIC ## The behaviour's mode of operation. See [b]ProcessMode[/b] for more.

## Controls the order in which this behaviour is checked and ran.[br][br]
## - [code]AUTOMATIC[/code]: Alternates between [code]F_START[/code]
## and [code]F_END[/code].[br][br]
## - [code]F_START[/code]: Runs [code]action()[/code] immediately
## after [code]condition()[/code] returns true.[br][br]
## - [code]F_END[/code]: Runs [code]action()[/code] deferred after 
## [code]condition()[/code] returns true.[br][br]
## - [code]ALWAYS[/code]: Checks and runs [code]action()[/code] for
## each frame before everything else.[br][br]
## [b]Warning:[/b] [code]ALWAYS[/code] should be used sparingly as it might
## slow down runtime performance.
enum ProcessMode {
	AUTOMATIC, ## Alternates between [code]F_START[/code] and [code]F_END[/code].
	F_START, ## Runs [code]action()[/code] immediately after [code]condition()[/code] returns true.
	F_END, ## Runs [code]action()[/code] deferred after [code]condition()[/code] returns true.
	ALWAYS, ## Checks and runs [code]action()[/code] for each frame before everything else.
}

## The [BehaviourList] will populate this field with context nodes in which 
## [code]action()[/code] and [code]condition()[/code] can borrow values from.
var actors: Dictionary[String, Node]

#region MANAGING

## Gets actor [code]actor_name[/code] present in actors dictionary. Returns 
## [code]null[/code] if it wasn't found. If no name is specified, returns
## parent node.
func get_actor(actor_name: String = "parent") -> Node:
	return actors.get(actor_name, null)

## Sets this behaviour enabled. 
func set_enabled(enable: bool) -> void:
	enabled = enable

#endregion MANAGING
#region OVERRIDEABLES

## This method is called automatically by [BehaviourList] once it populates
## the [code]actors[/code] variable at runtime.
@abstract
func init() -> void

## This method is called automatically by [BehaviourList] where it will test
## whether if [code]action()[/code] can be ran.
@abstract
func condition(delta: float) -> bool

## This method is called automatically by [BehaviourList], which provides
## action for a met criteria given by [code]condition()[/code].
@abstract
func action(delta: float) -> bool

#endregion OVERRIDEABLES
