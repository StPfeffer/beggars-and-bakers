extends PlayerState


func enter_state():
	state_name = "FALL"
	player.handle_gravity_and_terminal_velocity()


func update(delta: float):
	player.handle_gravity(delta)
	player.handle_horizontal_movement(delta)
	player.handle_landing()

	handle_animations()


func handle_animations():
	player.sprite.play("fall")
