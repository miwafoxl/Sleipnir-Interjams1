extends Node

const LOG_VERBOSE: bool = true

@export var autoload_preset_at_startup: String = "default"
@export var preset_scenes: Dictionary[String, PackedScene] = {}

static var current_scene: WeakRef = null # -> Node
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

func load_preset(scene_name: String, swap: bool = false) -> bool:
	var _scn: PackedScene = null
	if not preset_scenes.has(scene_name):
		if LOG_VERBOSE: _log_warn("Failed to load preset scene '%s' - No such scene found" % scene_name)
		return false
	_scn = preset_scenes.get(scene_name)
	loaded_scenes.set(scene_name, _scn)
	if LOG_VERBOSE: _log_standard("Loaded preset scene '%s'" % scene_name)
	if swap: swap_scene(scene_name)
	return true

func unload_current() -> void:
	var _cur: Node = current_scene.get_ref()
	if not _cur == null: 
		_cur.queue_free()
		if LOG_VERBOSE: _log_standard("Unloading current scene")

func unload_scene(scene_name: String) -> void:
	if loaded_scenes.has(scene_name):
		loaded_scenes.erase(scene_name)
		if LOG_VERBOSE: _log_standard("Unloaded scene '%s'" % scene_name)

#endregion SCENE MANAGING

#region OVERRIDES

func _ready() -> void:
	if not autoload_preset_at_startup.is_empty():
		load_preset(autoload_preset_at_startup, true)

#endregion OVERRIDES
