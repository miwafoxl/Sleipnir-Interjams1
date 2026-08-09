extends Node

const LOG_VERBOSE: bool = true
const LOG_DEFAULT_SCENE: String = "default"

@export var preset_scenes: Dictionary[String, PackedScene] = {}

static var current_scene: WeakRef = null # Dereferences to Node
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

func swap_scene(loaded_scene: String) -> bool:
	var _scene: PackedScene = loaded_scenes.get(loaded_scene, null)
	var _new: Node = null
	if not loaded_scenes.has(loaded_scene) or _scene == null:
		if LOG_VERBOSE: _log_warn("Failed to swap to scene '%s' - No such scene loaded" % loaded_scene)
		return false
	unload_current()
	_new = _scene.instantiate()
	current_scene = weakref(_new)
	var _main: Node = SceneTree.root
	_main.add_child.call_deferred(_new)
	if LOG_VERBOSE: _log_standard("Swapping to scene '%s'" % loaded_scene)
	return true

func unload_current() -> void:
	var _cur: Node = current_scene.get_ref()
	if not _cur == null: 
		_cur.queue_free()
		if LOG_VERBOSE: _log_standard("Unloading current scene")
	
func load_scene_path(scene_name: String, path: String, swap: bool = false) -> bool:
	var _scn: PackedScene = load(path)
	if _scn == null:
		if LOG_VERBOSE: _log_warn("Failed to load scene '%s'" % scene_name)
		return false
	if loaded_scenes.has(scene_name):
		if LOG_VERBOSE: _log_standard("Overwriting already loaded scene '%s'" % scene_name)
	loaded_scenes.set(scene_name, _scn)
	if swap: swap_scene(scene_name)
	return true

#endregion SCENE MANAGING
