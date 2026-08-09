extends Node
class_name AudioMaSTER

const LOG_VERBOSE: bool = true

@export var sound_presets: Dictionary[String, AudioEvent]
@export var music_presets: Dictionary[String, AudioEvent]

#region CONSOLE OUT

func _log_standard(message: String) -> void:
	print("[Audio]: %s" % message)

func _log_warn(message: String) -> void:
	push_warning("[Audio]: %s" % message)

func _log_err(message: String) -> void:
	printerr("[Audio]: %s" % message)

#endregion CONSOLE OUT
