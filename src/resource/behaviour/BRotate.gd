class_name BRotate extends Behaviour

@export var amount: float = 0.05

var rotating: Sprite2D

func init() -> void:
	var _rotator: Sprite2D = get_actor("rotate")
	if _rotator == null:
		rotating = get_actor() as Sprite2D
		return
	rotating = _rotator

func condition(_delta: float) -> bool:
	return true

func action(_delta: float) -> void:
	rotating.rotate(-amount)
