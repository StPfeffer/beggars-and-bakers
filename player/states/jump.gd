extends PlayerState


func enter_state():
	state_name = "JUMP"

	player.handle_gravity_and_terminal_velocity()
	handle_variable_jump_height()

	if player.velocity.y < 0 and player.jump and !player.dashing:
		player.sprite.speed_scale = 1

	if player.velocity.y > 40 and player.falling and !player.dashing and !player.crouching:
		player.sprite.speed_scale = 1


func update(delta: float):
	player.handle_gravity()
	player.handle_horizontal_movement(delta)

	handle_jump_to_fall()
	handle_animations()


func handle_variable_jump_height():
	if player.short_hop_aka_variable_jump_height and player.jump_release and player.velocity.y < 0:
		player.velocity.y = player.velocity.y / player.jump_variable


func handle_jump_to_fall():
	if player.velocity.y >= 0:
		player.change_state(states.JUMP_PEAK)
	# elif !player.jump_tap:
	# 	player.velocity.y = player.jump_variable
	# 	player.change_state(states.JUMP_PEAK)


func handle_animations():
	player.sprite.play("jump")
	player.flip_player()
