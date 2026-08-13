class_name BRotate extends Behaviour

@export var amount: float = 0.05

var player: Sprite2D

func condition(_delta: float) -> bool:
	player = actors.get("player") as Sprite2D
	return true

func action(_delta: float) -> bool:
	player.rotate(amount)
	return true
