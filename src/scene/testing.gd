extends Node2D

@onready var test: GameObject = GameObject.get_gameobject($Icon3)

func _ready() -> void:
	print_debug(test)

func _on_icon_but_pressed() -> void:
	test.add_actor("rotate", $Icon)

func _on_icon_2_but_pressed() -> void:
	test.add_actor("rotate", $Icon2)

func _on_icon_3_but_pressed() -> void:
	test.add_actor("rotate", $Icon3)
