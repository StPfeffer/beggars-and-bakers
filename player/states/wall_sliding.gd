extends PlayerState


func enter_state():
	state_name = "WALL_SLIDING"

	if player.wallLatching and ((player.wallLatchingModifer and player.latchHold) or !player.wallLatchingModifer):
		player.appliedGravity = 0
		handle_wall_latching_velocity()
	elif player.wallSliding != 1 and player.velocity.y > 0:
		player.appliedGravity = player.appliedGravity / player.wallSliding


func update(delta: float):
	player.handle_horizontal_movement(delta)
	player.handle_jump(delta)
	player.handle_falling(delta)

	handle_animations()
	#handle_idle()


func handle_idle():
	#if player.is_on_floor() and player.current_state != states.Latching:
	if player.is_on_floor() and (!player.leftHold and !player.rightHold):
		player.change_state(states.IDLE)


func handle_wall_latching_velocity():
	if player.velocity.y < 0:
		player.velocity.y += 50
	if player.velocity.y > 0:
		player.velocity.y = 0

	if player.wallLatchingModifer and player.latchHold and player.movementInputMonitoring == Vector2(true, true):
		player.velocity.x = 0


func handle_animations():
	player.flip_player()
	player.sprite.play("wall_slide")
