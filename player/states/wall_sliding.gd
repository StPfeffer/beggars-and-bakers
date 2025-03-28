extends PlayerState


func enter_state():
	state_name = "WALL_SLIDING"

	if player.wall_latching and ((player.wall_latching_modifer and player.latch_hold) or !player.wall_latching_modifer):
		player.applied_gravity = 0
		handle_wall_latching_velocity()
	elif player.wall_sliding != 1 and player.velocity.y > 0:
		player.applied_gravity = player.applied_gravity / player.wall_sliding


func update(delta: float):
	player.handle_horizontal_movement(delta)
	player.handle_jump()
	player.handle_falling(delta)

	handle_animations()
	#handle_idle()


func handle_idle():
	#if player.is_on_floor() and player.current_state != states.Latching:
	if player.is_on_floor() and (!player.left_hold and !player.right_hold):
		player.change_state(states.IDLE)


func handle_wall_latching_velocity():
	if player.velocity.y < 0:
		player.velocity.y += 50
	if player.velocity.y > 0:
		player.velocity.y = 0

	if player.wall_latching_modifer and player.latch_hold and player.movement_input_monitoring == Vector2(true, true):
		player.velocity.x = 0


func handle_animations():
	player.flip_player()
	player.sprite.play("wall_slide")
