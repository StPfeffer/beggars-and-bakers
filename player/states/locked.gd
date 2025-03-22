extends PlayerState


func enter_state():
	state_name = "LOCKED"


func update(delta: float):
	player.change_state(states.FALL)


func handle_animations():
	player.sprite.play("jump")
