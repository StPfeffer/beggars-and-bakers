class_name Player extends CharacterBody2D


#region Player Variables

@export_category("L/R Movement")
## The max speed your player will move
@export_range(50, 500) var max_speed: float = 200.0
## How fast your player will reach max speed from rest (in seconds)
@export_range(0, 4) var time_to_reach_max_speed: float = 0.2
## How fast your player will reach zero speed from max speed (in seconds)
@export_range(0, 4) var time_to_reach_zero_speed: float = 0.2
## If true, player will instantly move and switch directions. Overrides the "timeToReach" variables, setting them to 0.
@export var directional_snap: bool = false
## If enabled, the default movement speed will by 1/2 of the max_speed and the player must hold a "run" button to accelerate to max speed. Assign "run" (case sensitive) in the project input settings.
@export var running_modifier: bool = false
## The amount of pixels that will be shifted in the sprite when the player turns around.
@export var shift_amount: int = 10

@export_category("Jumping and Gravity")
## The peak height of your player's jump
@export_range(0, 20) var jump_height: float = 2.0
## How many jumps your character can do before needing to touch the ground again. Giving more than 1 jump disables jump buffering and coyote time.
@export_range(0, 4) var jumps: int = 1
## The strength at which your character will be pulled to the ground.
@export_range(0, 100) var gravity_scale: float = 20.0
## The fastest your player can fall
@export_range(0, 1000) var terminal_velocity: float = 500.0
## Your player will move this amount faster when falling providing a less floaty jump curve.
@export_range(0.5, 3) var descending_gravity_factor: float = 1.3
## Enabling this toggle makes it so that when the player releases the jump key while still ascending, their vertical velocity will cut by the height cut, providing variable jump height.
@export var short_hop_aka_variable_jump_height: bool = true
## How much the jump height is cut by.
@export_range(1, 10) var jump_variable: float = 2
## How much extra time (in seconds) your player will be given to jump after falling off an edge. This is set to 0.2 seconds by default.
@export_range(0, 0.5) var coyote_time: float = 0.2
## The window of time (in seconds) that your player can press the jump button before hitting the ground and still have their input registered as a jump. This is set to 0.2 seconds by default.
@export_range(0, 0.5) var jump_buffering: float = 0.2

@export_category("Wall Jumping")
## Allows your player to jump off of walls. Without a Wall Kick Angle, the player will be able to scale the wall.
@export var can_wall_jump: bool = false
## How long the player's movement input will be ignored after wall jumping.
@export_range(0, 0.5) var input_pause_after_wall_jump: float = 0.1
## The angle at which your player will jump away from the wall. 0 is straight away from the wall, 90 is straight up. Does not account for gravity
@export_range(0, 90) var wall_kick_angle: float = 60.0
## Allows your player to slide off of walls.
@export var can_wall_slide: bool = false
## The player's gravity will be divided by this number when touch a wall and descending. Set to 1 by default meaning no change will be made to the gravity and there is effectively no wall sliding. THIS IS OVERRIDDED BY WALL LATCH.
@export_range(1, 20) var wall_sliding: float = 1.0
## If enabled, the player's gravity will be set to 0 when touching a wall and descending. THIS WILL OVERRIDE WALLSLIDING.
@export var wall_latching: bool = false
## wall latching must be enabled for this to work. If enabled, the player must hold down the "latch" key to wall latch. Assign "latch" in the project input settings. The player's input will be ignored when latching.
@export var wall_latching_modifer: bool = false

@export_category("Animations (Check Box if has animation)")
## Animations must be named "run" all lowercase as the check box says
@export var run: bool
## Animations must be named "jump" all lowercase as the check box says
@export var jump: bool
## Animations must be named "idle" all lowercase as the check box says
@export var idle: bool
## Animations must be named "walk" all lowercase as the check box says
@export var walk: bool
## Animations must be named "slide" all lowercase as the check box says
@export var slide: bool
## Animations must be named "latch" all lowercase as the check box says
@export var latch: bool
## Animations must be named "falling" all lowercase as the check box says
@export var falling: bool
## Animations must be named "crouch_idle" all lowercase as the check box says
@export var crouch_idle: bool
## Animations must be named "crouch_walk" all lowercase as the check box says
@export var crouch_walk: bool
## Animations must be named "roll" all lowercase as the check box says
@export var roll: bool

#endregion


#region Helper Variables

var applied_gravity: float
var max_speed_lock: float
var applied_terminal_velocity: float

var friction: float
var acceleration: float
var deceleration: float
var instant_acceleration: bool = false
var instant_stop: bool = false

var jump_magnitude: float = 500.0
var jump_count: int
var jump_was_pressed: bool = false
var coyote_active: bool = false
var gravity_active: bool = true
var dashing: bool = false
var dash_count: int
var rolling: bool = false

var was_moving_right: bool
var was_pressing_right: bool

# movement_input_monitoring.x addresses right direction while .y addresses left direction
var movement_input_monitoring: Vector2 = Vector2(true, true)

var latched: bool = false
var was_latched: bool = false
var crouching: bool = false
var ground_pounding: bool = false

var left_hold: bool = false
var left_tap: bool = false
var left_release: bool = false
var right_hold: bool = false
var right_tap: bool = false
var right_release: bool = false
var run_hold: bool = false
var jump_tap: bool = false
var jump_release: bool = false
var latch_hold: bool = false

var last_facing_direction: int = 1
var is_turning: bool = false

#endregion


var current_state = null
var previous_state = null

var coin_counter = 0


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var state_machine = $StateMachine
@onready var coin_label: Label = $Camera2D/CoinLabel

#region Main Loop Functions


func _ready():
	for state in state_machine.get_children():
		state.states = state_machine
		state.player = self

	previous_state = state_machine.FALL
	current_state = state_machine.FALL

	_updateData()


func _updateData():
	acceleration = max_speed / time_to_reach_max_speed
	deceleration = -max_speed / time_to_reach_zero_speed

	jump_magnitude = (10.0 * jump_height) * gravity_scale
	jump_count = jumps

	max_speed_lock = max_speed

	instant_acceleration = _handle_instant_logic(time_to_reach_max_speed, "acceleration")
	time_to_reach_max_speed = abs(time_to_reach_max_speed)

	instant_stop = _handle_instant_logic(time_to_reach_zero_speed, "stop")
	time_to_reach_zero_speed = abs(time_to_reach_zero_speed)

	if jumps > 1:
		jump_buffering = 0
		coyote_time = 0

	coyote_time = abs(coyote_time)
	jump_buffering = abs(jump_buffering)

	if directional_snap:
		instant_acceleration = true
		instant_stop = true


func _handle_instant_logic(timeValue: float, type: String) -> bool:
	if timeValue == 0:
		return true

	if timeValue < 0:
		return false

	return false


func _physics_process(delta: float) -> void:
	get_input_states()

	current_state.update(delta)

	handle_horizontal_movement(delta)
	handle_jump()

	move_and_slide()


#endregion


func get_input_states():
	left_hold = Input.is_action_pressed("left")
	right_hold = Input.is_action_pressed("right")
	#upHold = Input.is_action_pressed("up")
	#downHold = Input.is_action_pressed("down")
	left_tap = Input.is_action_just_pressed("left")
	right_tap = Input.is_action_just_pressed("right")
	left_release = Input.is_action_just_released("left")
	right_release = Input.is_action_just_released("right")
	jump_tap = Input.is_action_just_pressed("jump")
	jump_release = Input.is_action_just_released("jump")
	run_hold = Input.is_action_pressed("run")
	#dashTap = Input.is_action_just_pressed("dash")
	#rollTap = Input.is_action_just_pressed("roll")
	#downTap = Input.is_action_just_pressed("down")
	#twirlTap = Input.is_action_just_pressed("twirl")


func draw():
	current_state.draw()


func change_state(next_state):
	if next_state != null:
		previous_state = current_state
		current_state = next_state

		previous_state.exit_state()
		current_state.enter_state()

		#print("State Change from: " + previous_state.name + " to: " + current_state.name)


func handle_horizontal_movement(delta):
	_handle_movement(delta)
	_update_was_pressing_r()
	_adjust_max_speed()
	_handle_deceleration(delta)

	if left_hold or right_hold:
		flip_player()


func flip_player():
	if velocity.x > 0:
		if last_facing_direction == -1:
			sprite.position.x += shift_amount
			sprite.flip_h = false

		last_facing_direction = 1
		was_moving_right = true
	elif velocity.x < 0:
		if last_facing_direction == 1:
			sprite.position.x -= shift_amount
			sprite.flip_h = true

		last_facing_direction = -1
		was_moving_right = false


func _handle_movement(delta):
	if right_hold and left_hold and movement_input_monitoring:
		_handle_opposite_movement(delta)
	elif right_hold and movement_input_monitoring.x:
		_handle_right_movement(delta)
	elif left_hold and movement_input_monitoring.y:
		_handle_left_movement(delta)


func _handle_opposite_movement(delta):
	if !instant_stop:
		_decelerate(delta, false)
	else:
		velocity.x = -0.1


func _handle_right_movement(delta):
	if velocity.x > max_speed or instant_acceleration:
		velocity.x = max_speed
	else:
		velocity.x += acceleration * delta

	if velocity.x < 0:
		_handle_deceleration(delta)


func _handle_left_movement(delta):
	if velocity.x < -max_speed or instant_acceleration:
		velocity.x = -max_speed
	else:
		velocity.x -= acceleration * delta

	if velocity.x > 0:
		_handle_deceleration(delta)


func _update_was_pressing_r():
	if right_tap:
		was_pressing_right = true
	if left_tap:
		was_pressing_right = false


func _adjust_max_speed():
	if running_modifier and !run_hold:
		max_speed = max_speed_lock / 2
	elif is_on_floor():
		max_speed = max_speed_lock


func _handle_deceleration(delta):
	if left_hold or right_hold:
		return

	if !instant_stop:
		_decelerate(delta, false)
	else:
		velocity.x = 0


func _decelerate(delta, vertical):
	if !vertical:
		if (abs(velocity.x) > 0) and (abs(velocity.x) <= abs(deceleration * delta)):
			velocity.x = 0 
		elif velocity.x > 0:
			velocity.x += deceleration * delta
		elif velocity.x < 0:
			velocity.x -= deceleration * delta
	elif vertical and velocity.y > 0:
		velocity.y += deceleration * delta


func handle_gravity():
	if velocity.y > 0:
		applied_gravity = gravity_scale * descending_gravity_factor
	else:
		applied_gravity = gravity_scale

	if gravity_active:
		_apply_gravity()

	if !is_on_floor() and !is_on_wall() and velocity.y > 0:
		change_state(state_machine.FALL)


func _apply_gravity():
	if velocity.y < applied_terminal_velocity:
		velocity.y += applied_gravity
	elif velocity.y > applied_terminal_velocity:
		velocity.y = applied_terminal_velocity


func handle_jump():
	handle_gravity_and_terminal_velocity();

	if jumps == 1:
		_handle_single_jump()
	elif jumps > 1:
		_handle_multi_jump()


func handle_gravity_and_terminal_velocity():
	if is_on_wall() and !ground_pounding:
		handle_wall_gravity_and_velocity()
	elif !is_on_wall() and !ground_pounding:
		applied_terminal_velocity = terminal_velocity


func handle_wall_gravity_and_velocity():
	if can_wall_slide:
		applied_terminal_velocity = terminal_velocity / wall_sliding

		change_state(state_machine.WALL_SLIDING)


func _handle_single_jump():
	if !is_on_floor() and !is_on_wall():
		_handle_coyote_time()

	if jump_tap:
		_handle_jump_input()

	if is_on_floor():
		_reset_jump_state()


func _handle_coyote_time():
	if coyote_time > 0:
		coyote_active = true
		_coyoteTime()


func _handle_jump_input():
	if !is_on_wall():
		if coyote_active:
			coyote_active = false
			_jump()
		if jump_buffering > 0:
			jump_was_pressed = true
			_bufferJump()
		elif jump_buffering == 0 and coyote_time == 0 and is_on_floor():
			_jump()
	elif is_on_wall() and !is_on_floor():
		if can_wall_jump:
			_wallJump()
	elif is_on_floor():
		_jump()


func _reset_jump_state():
	jump_count = jumps

	if coyote_time > 0:
		coyote_active = true
	else:
		coyote_active = false
	if jump_was_pressed:
		_jump()


func _handle_multi_jump():
	if is_on_floor():
		jump_count = jumps
	if jump_tap:
		if is_on_wall() and can_wall_jump:
			_wallJump()
		elif jump_count > 0:
			_jump()
			jump_count -= 1
			_endGroundPound()


func _bufferJump():
	await get_tree().create_timer(jump_buffering).timeout
	jump_was_pressed = false


func _coyoteTime():
	await get_tree().create_timer(coyote_time).timeout
	coyote_active = false
	jump_count -= 1


func _jump():
	if jump_count > 0:
		change_state(state_machine.JUMP)
		velocity.y = -jump_magnitude
		jump_count -= 1


func _wallJump():
	#change_state(states.WALL_JUMPING)
	#current_state = State.WALL_JUMPING

	var horizontalWallKick = abs(jump_magnitude * cos(wall_kick_angle * (PI / 180)))
	var verticalWallKick = abs(jump_magnitude * sin(wall_kick_angle * (PI / 180)))

	velocity.y = -verticalWallKick

	var dir = 1
	if wall_latching_modifer and latch_hold:
		dir = -1
	if was_moving_right:
		velocity.x = -horizontalWallKick * dir
	else:
		velocity.x = horizontalWallKick * dir

	if input_pause_after_wall_jump != 0:
		movement_input_monitoring = Vector2(false, false)
		_inputPauseReset(input_pause_after_wall_jump)


func _groundPound():
	applied_terminal_velocity = terminal_velocity * 10
	velocity.y = jump_magnitude * 2


func _endGroundPound():
	ground_pounding = false
	applied_terminal_velocity = terminal_velocity
	gravity_active = true


func _inputPauseReset(time):
	await get_tree().create_timer(time).timeout
	movement_input_monitoring = Vector2(true, true)


func handle_landing():
	if (is_on_floor()):
		_reset_jump_state()
		change_state(state_machine.IDLE)


func handle_falling(delta):
	if velocity.y > 0:
		applied_gravity = gravity_scale * descending_gravity_factor
	else:
		applied_gravity = gravity_scale

	if gravity_active:
		_apply_gravity()

	if !is_on_floor() and !is_on_wall() and velocity.y > 0:
		change_state(state_machine.FALL)

#endregion

@onready var footstep_sound = $StepsAudio
@onready var jump_sound = $JumpAudio

func _process(delta):
	if current_state == state_machine.RUN:
		if !footstep_sound.playing:
			footstep_sound.play()
	else:
		footstep_sound.stop()

	if state_machine.JUMP == current_state:
		if !jump_sound.playing:
			jump_sound.play()

func set_coin(new_coin_count: int) -> void:
	coin_counter = new_coin_count
	coin_label.text = str(coin_counter)
