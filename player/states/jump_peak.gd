extends PlayerState


func enter_state():
	state_name = "JUMP_PEAK"


func update(delta: float):
	player.handle_horizontal_movement(delta)
	player.change_state(states.FALL)

	handle_animations()


func handle_animations():
	player.sprite.play("jump")
	player.flip_player()
