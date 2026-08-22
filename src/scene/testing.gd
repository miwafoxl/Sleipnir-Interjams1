extends Node2D

@onready var test: BRotate = GameObject.get_behaviour_from($Icon3, "BRotate")

func _ready() -> void:
	test.event.connect(process_event)

func process_event(event: String) -> void:
	match event:
		"sound.rotating":
			SoundBlaster.queue_play("rotating")
		"sound.stopped":
			SoundBlaster.queue_play("stopped_rotating")

func _on_icon_but_pressed() -> void:
	test.rotating = $Icon

func _on_icon_2_but_pressed() -> void:
	test.rotating = $Icon2

func _on_icon_3_but_pressed() -> void:
	test.rotating = $Icon3
