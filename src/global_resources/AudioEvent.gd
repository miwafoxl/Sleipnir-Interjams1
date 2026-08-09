class_name AudioEvent extends Resource

@export var bus_name: AudioEventBus = AudioEventBus.MASTER
@export var stream_list: AudioStreamPlaylist = null

enum AudioEventBus {
	MASTER, # Uncategorized
	MUSIC, # Music
	DIALOGUE, # Vocal taunts and dialogs
	EFFECT_LOFD, # Low-feedback SFX
	EFFECT_HIFD, # Hi-feedback SFX
}
