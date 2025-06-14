extends Node2D


@export_category("Teleport")
## The scene that will be loaded
@export var scene: String


@onready
var portal_sound = $AudioStreamPlayer2D

func _ready() -> void:
	return


func _on_area_2d_area_entered(area: Area2D) -> void:
	portal_sound.play()
	get_tree().change_scene_to_file(scene)
