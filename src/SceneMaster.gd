extends Node

const LOG_VERBOSE: bool = true
const LOG_DEFAULT_SCENE: String = "default"

@export var preset_scenes: Dictionary[String, PackedScene] = {}

static var current_scene: WeakRef = null
static var loaded_scenes: Dictionary[String, PackedScene] = {}

#region CONSOLE OUT

func _log_standard(message: String) -> void:
	print("[Scene]: %s" % message)

func _log_warn(message: String) -> void:
	push_warning("[Scene]: %s" % message)

func _log_err(message: String) -> void:
	printerr("[Scene]: %s" % message)

#endregion CONSOLE OUT

#region SCENE MANAGING 

func swap_scene(scene: String) -> bool:
	if not loaded_scenes.has(scene):
		if LOG_VERBOSE: _log_warn("Failed to swap to scene '%s' - No such scene loaded" % scene)
		return false
	

func load_scene_path(scene: String, path: String, swap: bool = false) -> bool:
	var _scn: PackedScene = load(path)
	if _scn == null:
		if LOG_VERBOSE: _log_warn("Failed to load scene '%s'" % scene)
		return false
	if loaded_scenes.has(scene):
		if LOG_VERBOSE: _log_standard("Overwriting already loaded scene '%s'" % scene)
	loaded_scenes.set(scene, _scn)
	if swap: swap_scene(scene)
	return true

#endregion SCENE MANAGING
