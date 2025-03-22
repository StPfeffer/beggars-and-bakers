extends PlayerState


func enter_state():
	state_name = "JUMP_PEAK"


func update(delta: float):
	player.change_state(states.FALL)


func handle_animations():
	player.sprite.play("jump")
