extends Area2D

@export
var player: CharacterBody2D


@onready
var pickupSound = $AudioStreamPlayer2D
@onready
var sprite = $AnimatedSprite2D

var picked = false;


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if picked:
			return

		pickupSound.play()

		sprite.hide()
		picked = true

		player.set_coin(player.coin_counter + 1)

		await pickupSound.finished
		queue_free()
