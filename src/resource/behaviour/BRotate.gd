class_name BRotate extends Behaviour

@export var amount: float = 0.05

var player: Sprite2D

func init() -> void:
	player = get_actor() as Sprite2D

func condition(_delta: float) -> bool:
	return true

func action(_delta: float) -> void:
	player.rotate(-amount)
