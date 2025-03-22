extends CharacterBody2D


@export var player: CharacterBody2D
@export var speed: int = 50
@export var chaseSpeed: int = 150
@export var acceleration: int = 300
@export var jumpForce: float = -300.0
@export var attackRange: float = 50.0

@export var boundDistance: int = 125

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast: RayCast2D = $AnimatedSprite2D/RayCast2D
@onready var timer: Timer = $Timer

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: Vector2
var right_bounds: Vector2
var left_bounds: Vector2

enum States {
	IDLE,
	FALLING,
	WANDER,
	CHASE,
	ATTACK
}

var current_state = States.WANDER


func _ready() -> void:
	left_bounds = self.position + Vector2(-boundDistance, 0)
	right_bounds = self.position + Vector2(boundDistance, 0)


func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_movement(delta)
	change_direction()
	look_for_player()

	$Label.text = "State: " + States.keys()[current_state]

	update_animation()


func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func handle_movement(delta: float) -> void:
	if current_state == States.WANDER:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(direction * chaseSpeed, acceleration * delta)

	move_and_slide()


func change_direction() -> void:
	if current_state == States.WANDER:
		if !sprite.flip_h:
			# moving right
			if self.position.x <= right_bounds.x:
				sprite.flip_h = false
				direction = Vector2(1, 0)
			else:
				# flip to left
				sprite.flip_h = true
				ray_cast.target_position = Vector2(-boundDistance, 0)
		else:
			# moving left
			if self.position.x >= left_bounds.x:
				sprite.flip_h = true
				direction = Vector2(-1, 0)
			else:
				# flip to right
				sprite.flip_h = false
				ray_cast.target_position = Vector2(boundDistance, 0)
	else:
		direction = (player.position - self.position).normalized()
		direction = sign(direction)

		if direction.x == 1:
			# flip right
			sprite.flip_h = false
			ray_cast.target_position = Vector2(boundDistance, 0)
		else:
			# flip left
			sprite.flip_h = true
			ray_cast.target_position = Vector2(-boundDistance, 0)


func look_for_player() -> void:
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()

		if collider == player:
			chase_player()
		elif current_state == States.CHASE:
			stop_chase()
	elif current_state == States.CHASE:
		stop_chase()


func chase_player() -> void:
	timer.stop()
	current_state = States.CHASE


func stop_chase() -> void:
	if timer.time_left <= 0:
		timer.start()


func update_animation() -> void:
	match current_state:
		States.IDLE:
			sprite.play("idle")
		States.WANDER:
			sprite.play("walk")
		States.CHASE:
			sprite.play("run")
		States.ATTACK:
			sprite.play("attack")
		States.FALLING:
			sprite.play("fall")


func _on_timer_timeout() -> void:
	current_state = States.WANDER


func check_for_attack() -> void:
	if current_state == States.CHASE:
		if self.position.distance_to(player.position) <= attackRange:
			current_state == States.ATTACK


func try_jump() -> void:
	if is_on_floor() and current_state == States.CHASE:
		velocity.y = jumpForce
