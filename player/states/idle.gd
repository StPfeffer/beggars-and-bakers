extends PlayerState


func enter_state():
	state_name = "IDLE"


func update(delta: float):
	player.handle_falling(delta)
	player.handle_jump(delta)
	player.handle_horizontal_movement(delta)

	if player.leftHold or player.rightHold:
		player.change_state(states.RUN)

	handle_animations()


func handle_animations():
	player.sprite.play("idle")
	player.flip_player()
