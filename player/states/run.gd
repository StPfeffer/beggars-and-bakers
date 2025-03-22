extends PlayerState


func enter_state():
	state_name = "RUN"


func update(delta: float):
	player.handle_horizontal_movement(delta)
	player.handle_jump(delta)
	player.handle_falling(delta)

	handle_animations()
	handle_idle()


func handle_idle():
	#if player.is_on_floor() and player.current_state != states.Latching:
	if player.is_on_floor() and (!player.leftHold and !player.rightHold):
		player.change_state(states.IDLE)


func handle_animations():
	player.sprite.play("run")
