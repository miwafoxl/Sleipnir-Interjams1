@abstract
class_name Behaviour extends Node

@warning_ignore("unused_signal")
signal event

var enabled: bool = true ## Sets if the behaviour is currently active
var process: BehaviourMode = BehaviourMode.AUTOMATIC ## The behaviour's mode of operation. See [b]ProcessMode[/b] for more.

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
enum BehaviourMode {
	AUTOMATIC, ## Alternates between [code]F_START[/code] and [code]F_END[/code].
	F_START, ## Runs [code]action()[/code] immediately after [code]condition()[/code] returns true.
	F_END, ## Runs [code]action()[/code] deferred after [code]condition()[/code] returns true.
	ALWAYS, ## Checks and runs [code]action()[/code] for each frame before everything else.
}

## The [GameObject] will populate this field with the parent node in which
## this Behaviour is in.
var actor: Node

#region MANAGING

## Sets this behaviour enabled. 
func set_enabled(enable: bool) -> void:
	enabled = enable

#endregion MANAGING
#region OVERRIDEABLES

## This method is called automatically by [GameObject] once it populates
## the [code]actors[/code] variable at runtime.
func init() -> void:
	pass

## This method is called automatically by [GameObject] where it will test
## whether if [code]action()[/code] can be ran.
@warning_ignore("unused_parameter")
func condition(delta: float) -> bool:
	return true

@warning_ignore("unused_parameter")
func condition_physics(delta: float) -> bool:
	return true

## This method is called automatically by [GameObject], which provides
## action for a met criteria given by [code]condition()[/code].
@warning_ignore("unused_parameter")
func action(delta: float) -> void:
	pass

@warning_ignore("unused_parameter")
func action_physics(delta: float) -> void:
	pass

#endregion OVERRIDEABLES
