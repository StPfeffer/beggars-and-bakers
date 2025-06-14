extends Area2D

@export
var player: CharacterBody2D


@onready
var pickupSound = $AudioStreamPlayer2D
@onready
var sprite = $AnimatedSprite2D

var picked = false;


func _on_area_entered(area: Area2D) -> void:
	if picked:
		return

	pickupSound.play()

	sprite.hide()
	picked = true

	player.set_coin(player.coin_counter + 1)

	await pickupSound.finished
	queue_free()
