class_name BRotate extends Behaviour

@export var amount: float = 0.05

var rotating: Sprite2D

func init() -> void:
	if rotating == null:
		rotating = actor

func condition(_delta: float) -> bool:
	return true

func action(_delta: float) -> void:
	rotating.rotate(-amount)
	event.emit("sound.rotating")
