class_name PlayerOld extends CharacterBody2D


@export_category("L/R Movement")
##The max speed your player will move
@export_range(50, 500) var maxSpeed: float = 200.0
##How fast your player will reach max speed from rest (in seconds)
@export_range(0, 4) var timeToReachMaxSpeed: float = 0.2
##How fast your player will reach zero speed from max speed (in seconds)
@export_range(0, 4) var timeToReachZeroSpeed: float = 0.2
##If true, player will instantly move and switch directions. Overrides the "timeToReach" variables, setting them to 0.
@export var directionalSnap: bool = false
##If enabled, the default movement speed will by 1/2 of the maxSpeed and the player must hold a "run" button to accelerate to max speed. Assign "run" (case sensitive) in the project input settings.
@export var runningModifier: bool = false
##The amount of pixels that will be shifted in the sprite when the player turns around.
@export var shiftAmount: int = 10

@export_category("Jumping and Gravity")
##The peak height of your player's jump
@export_range(0, 20) var jumpHeight: float = 2.0
##How many jumps your character can do before needing to touch the ground again. Giving more than 1 jump disables jump buffering and coyote time.
@export_range(0, 4) var jumps: int = 1
##The strength at which your character will be pulled to the ground.
@export_range(0, 100) var gravityScale: float = 20.0
##The fastest your player can fall
@export_range(0, 1000) var terminalVelocity: float = 500.0
##Your player will move this amount faster when falling providing a less floaty jump curve.
@export_range(0.5, 3) var descendingGravityFactor: float = 1.3
##Enabling this toggle makes it so that when the player releases the jump key while still ascending, their vertical velocity will cut by the height cut, providing variable jump height.
@export var shortHopAkaVariableJumpHeight: bool = true
##How much the jump height is cut by.
@export_range(1, 10) var jumpVariable: float = 2
##How much extra time (in seconds) your player will be given to jump after falling off an edge. This is set to 0.2 seconds by default.
@export_range(0, 0.5) var coyoteTime: float = 0.2
##The window of time (in seconds) that your player can press the jump button before hitting the ground and still have their input registered as a jump. This is set to 0.2 seconds by default.
@export_range(0, 0.5) var jumpBuffering: float = 0.2

@export_category("Wall Jumping")
##Allows your player to jump off of walls. Without a Wall Kick Angle, the player will be able to scale the wall.
@export var wallJump: bool = false
##How long the player's movement input will be ignored after wall jumping.
@export_range(0, 0.5) var inputPauseAfterWallJump: float = 0.1
##The angle at which your player will jump away from the wall. 0 is straight away from the wall, 90 is straight up. Does not account for gravity
@export_range(0, 90) var wallKickAngle: float = 60.0
##The player's gravity will be divided by this number when touch a wall and descending. Set to 1 by default meaning no change will be made to the gravity and there is effectively no wall sliding. THIS IS OVERRIDDED BY WALL LATCH.
@export_range(1, 20) var wallSliding: float = 1.0
##If enabled, the player's gravity will be set to 0 when touching a wall and descending. THIS WILL OVERRIDE WALLSLIDING.
@export var wallLatching: bool = false
##wall latching must be enabled for this to work. If enabled, the player must hold down the "latch" key to wall latch. Assign "latch" in the project input settings. The player's input will be ignored when latching.
@export var wallLatchingModifer: bool = false

@export_category("Animations (Check Box if has animation)")
##Animations must be named "run" all lowercase as the check box says
@export var run: bool
##Animations must be named "jump" all lowercase as the check box says
@export var jump: bool
##Animations must be named "idle" all lowercase as the check box says
@export var idle: bool
##Animations must be named "walk" all lowercase as the check box says
@export var walk: bool
##Animations must be named "slide" all lowercase as the check box says
@export var slide: bool
##Animations must be named "latch" all lowercase as the check box says
@export var latch: bool
##Animations must be named "falling" all lowercase as the check box says
@export var falling: bool
##Animations must be named "crouch_idle" all lowercase as the check box says
@export var crouch_idle: bool
##Animations must be named "crouch_walk" all lowercase as the check box says
@export var crouch_walk: bool
##Animations must be named "roll" all lowercase as the check box says
@export var roll: bool


var appliedGravity: float
var maxSpeedLock: float
var appliedTerminalVelocity: float

var friction: float
var acceleration: float
var deceleration: float
var instantAccel: bool = false
var instantStop: bool = false

var jumpMagnitude: float = 500.0
var jumpCount: int
var jumpWasPressed: bool = false
var coyoteActive: bool = false
var gravityActive: bool = true
var dashing: bool = false
var dashCount: int
var rolling: bool = false

var wasMovingR: bool
var wasPressingR: bool

# movementInputMonitoring.x addresses right direction while .y addresses left direction
var movementInputMonitoring: Vector2 = Vector2(true, true)

var latched: bool = false
var wasLatched: bool = false
var crouching: bool = false
var groundPounding: bool = false

var leftHold: bool = false
var leftTap: bool = false
var leftRelease: bool = false
var rightHold: bool = false
var rightTap: bool = false
var rightRelease: bool = false
var runHold: bool = false
var jumpTap: bool = false
var jumpRelease: bool = false
var latchHold: bool = false

var lastFacingDirection: int = 1
var is_turning: bool = false


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D


enum State {
	IDLE,
	RUNNING,
	FALLING,
	JUMPING,
	DASHING,
	CROUCHING,
	LATCHING,
	ATTACKING,
	WALL_SLIDING,
	WALL_JUMPING,
	TURNING
}

var current_state: State


func _ready():
	current_state = State.IDLE

	_updateData()


func _updateData():
	acceleration = maxSpeed / timeToReachMaxSpeed
	deceleration = -maxSpeed / timeToReachZeroSpeed

	jumpMagnitude = (10.0 * jumpHeight) * gravityScale
	jumpCount = jumps

	maxSpeedLock = maxSpeed

	instantAccel = _handleInstantLogic(timeToReachMaxSpeed, "acceleration")
	timeToReachMaxSpeed = abs(timeToReachMaxSpeed)

	instantStop = _handleInstantLogic(timeToReachZeroSpeed, "stop")
	timeToReachZeroSpeed = abs(timeToReachZeroSpeed)

	if jumps > 1:
		jumpBuffering = 0
		coyoteTime = 0
	
	coyoteTime = abs(coyoteTime)
	jumpBuffering = abs(jumpBuffering)

	if directionalSnap:
		instantAccel = true
		instantStop = true


func _handleInstantLogic(timeValue: float, type: String) -> bool:
	if timeValue == 0:
		return true

	if timeValue < 0:
		return false

	return false


func _physics_process(delta: float) -> void:
	_update_input_states()

	$Label.text = "State: " + State.keys()[current_state]

	player_falling(delta)
	player_idle(delta)
	player_run(delta)
	player_jump(delta)

	move_and_slide()

	player_animation()


func _update_input_states():
	leftHold = Input.is_action_pressed("left")
	rightHold = Input.is_action_pressed("right")
	#upHold = Input.is_action_pressed("up")
	#downHold = Input.is_action_pressed("down")
	leftTap = Input.is_action_just_pressed("left")
	rightTap = Input.is_action_just_pressed("right")
	leftRelease = Input.is_action_just_released("left")
	rightRelease = Input.is_action_just_released("right")
	jumpTap = Input.is_action_just_pressed("jump")
	jumpRelease = Input.is_action_just_released("jump")
	runHold = Input.is_action_pressed("run")
	#dashTap = Input.is_action_just_pressed("dash")
	#rollTap = Input.is_action_just_pressed("roll")
	#downTap = Input.is_action_just_pressed("down")
	#twirlTap = Input.is_action_just_pressed("twirl")


func player_falling(delta):
	if velocity.y > 0:
		appliedGravity = gravityScale * descendingGravityFactor
	else:
		appliedGravity = gravityScale

	if gravityActive:
		_apply_gravity()

	if !is_on_floor() and !is_on_wall() and velocity.y > 0:
		current_state = State.FALLING


func _apply_gravity():
	if velocity.y < appliedTerminalVelocity:
		velocity.y += appliedGravity
	elif velocity.y > appliedTerminalVelocity:
		velocity.y = appliedTerminalVelocity


func player_idle(delta):
	if is_on_floor() and current_state != State.LATCHING:
		current_state = State.IDLE


func player_jump(delta):
	_handle_gravity_and_terminal_velocity()
	_handle_variable_jump_height()

	if jumps == 1:
		_handle_single_jump()
	elif jumps > 1:
		_handle_multi_jump()

	if velocity.y < 0 and jump and !dashing:
		sprite.speed_scale = 1
		sprite.play("jump")

	if velocity.y > 40 and falling and !dashing and !crouching:
		sprite.speed_scale = 1
		sprite.play("falling")


func _handle_gravity_and_terminal_velocity():
	if is_on_wall() and !groundPounding:
		_handle_wall_gravity_and_velocity()
	elif !is_on_wall() and !groundPounding:
		appliedTerminalVelocity = terminalVelocity


func _handle_wall_gravity_and_velocity():
	appliedTerminalVelocity = terminalVelocity / wallSliding

	current_state = State.WALL_SLIDING

	if wallLatching and ((wallLatchingModifer and latchHold) or !wallLatchingModifer):
		appliedGravity = 0
		_handle_wall_latching_velocity()
	elif wallSliding != 1 and velocity.y > 0:
		appliedGravity = appliedGravity / wallSliding


func _handle_wall_latching_velocity():
	if velocity.y < 0:
		velocity.y += 50
	if velocity.y > 0:
		velocity.y = 0

	if wallLatchingModifer and latchHold and movementInputMonitoring == Vector2(true, true):
		velocity.x = 0


func _handle_variable_jump_height():
	if shortHopAkaVariableJumpHeight and jumpRelease and velocity.y < 0:
		velocity.y = velocity.y / jumpVariable


func _handle_single_jump():
	if !is_on_floor() and !is_on_wall():
		_handle_coyote_time()

	if jumpTap:
		_handle_jump_input()

	if is_on_floor():
		_reset_jump_state()


func _handle_coyote_time():
	if coyoteTime > 0:
		coyoteActive = true
		_coyoteTime()


func _handle_jump_input():
	if !is_on_wall():
		if coyoteActive:
			coyoteActive = false
			_jump()
		if jumpBuffering > 0:
			jumpWasPressed = true
			_bufferJump()
		elif jumpBuffering == 0 and coyoteTime == 0 and is_on_floor():
			_jump()
	elif is_on_wall() and !is_on_floor():
		if wallJump:
			_wallJump()
	elif is_on_floor():
		_jump()


func _reset_jump_state():
	jumpCount = jumps
	if coyoteTime > 0:
		coyoteActive = true
	else:
		coyoteActive = false
	if jumpWasPressed:
		_jump()


func _handle_multi_jump():
	if is_on_floor():
		jumpCount = jumps
	if jumpTap:
		if is_on_wall() and wallJump:
			_wallJump()
		elif jumpCount > 0:
			_jump()
			jumpCount -= 1
			_endGroundPound()


func _bufferJump():
	await get_tree().create_timer(jumpBuffering).timeout
	jumpWasPressed = false


func _coyoteTime():
	await get_tree().create_timer(coyoteTime).timeout
	coyoteActive = false
	jumpCount -= 1


func _jump():
	if jumpCount > 0:
		current_state = State.JUMPING
		velocity.y = -jumpMagnitude
		jumpCount -= 1


func _wallJump():
	current_state = State.WALL_JUMPING

	var horizontalWallKick = abs(jumpMagnitude * cos(wallKickAngle * (PI / 180)))
	var verticalWallKick = abs(jumpMagnitude * sin(wallKickAngle * (PI / 180)))

	velocity.y = -verticalWallKick

	var dir = 1
	if wallLatchingModifer and latchHold:
		dir = -1
	if wasMovingR:
		velocity.x = -horizontalWallKick * dir
	else:
		velocity.x = horizontalWallKick * dir

	if inputPauseAfterWallJump != 0:
		movementInputMonitoring = Vector2(false, false)
		_inputPauseReset(inputPauseAfterWallJump)


func _groundPound():
	appliedTerminalVelocity = terminalVelocity * 10
	velocity.y = jumpMagnitude * 2


func _endGroundPound():
	groundPounding = false
	appliedTerminalVelocity = terminalVelocity
	gravityActive = true


func _inputPauseReset(time):
	await get_tree().create_timer(time).timeout
	movementInputMonitoring = Vector2(true, true)


func player_run(delta):
	if (leftHold or rightHold) and ![State.JUMPING, State.FALLING].has(current_state):
		current_state = State.RUNNING

	_handle_movement(delta)
	_update_was_pressing_r()
	_adjust_max_speed()
	_handle_deceleration(delta)

	if leftHold or rightHold:
		flip_player()


func player_animation():
	match current_state:
		State.IDLE:
			sprite.play("idle")
		State.RUNNING:
			sprite.play("run")
		State.JUMPING:
			sprite.play("jump")
		State.FALLING:
			sprite.play("fall")
		State.LATCHING:
			sprite.play("wall_climb")


func flip_player():
	if velocity.x > 0:
		if lastFacingDirection == -1:
			play_turn_animation()
			sprite.position.x += shiftAmount
			sprite.flip_h = false

		lastFacingDirection = 1
		wasMovingR = true
	elif velocity.x < 0:
		if lastFacingDirection == 1:
			play_turn_animation()
			sprite.position.x -= shiftAmount
			sprite.flip_h = true

		lastFacingDirection = -1
		wasMovingR = false


func play_turn_animation():
	if is_turning:
		return

	is_turning = true
	sprite.play("turn_around")

	await sprite.animation_finished  
	is_turning = false


func _handle_movement(delta):
	if rightHold and leftHold and movementInputMonitoring:
		_handle_opposite_movement(delta)
	elif rightHold and movementInputMonitoring.x:
		_handle_right_movement(delta)
	elif leftHold and movementInputMonitoring.y:
		_handle_left_movement(delta)


func _handle_opposite_movement(delta):
	if !instantStop:
		_decelerate(delta, false)
	else:
		velocity.x = -0.1


func _handle_right_movement(delta):
	if velocity.x > maxSpeed or instantAccel:
		velocity.x = maxSpeed
	else:
		velocity.x += acceleration * delta
	if velocity.x < 0:
		_handle_deceleration(delta)


func _handle_left_movement(delta):
	if velocity.x < -maxSpeed or instantAccel:
		velocity.x = -maxSpeed
	else:
		velocity.x -= acceleration * delta
	if velocity.x > 0:
		_handle_deceleration(delta)


func _update_was_pressing_r():
	if rightTap:
		wasPressingR = true
	if leftTap:
		wasPressingR = false


func _adjust_max_speed():
	if runningModifier and !runHold:
		maxSpeed = maxSpeedLock / 2
	elif is_on_floor():
		maxSpeed = maxSpeedLock


func _handle_deceleration(delta):
	if !(leftHold or rightHold):
		if !instantStop:
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
