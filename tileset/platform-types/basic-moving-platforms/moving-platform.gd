@tool
class_name MovingPlatform extends Path2D

@onready var Path: PathFollow2D = $PathFollow2D
@onready var Transform: RemoteTransform2D = $PathFollow2D/RemoteTransform2D
@onready var Body: AnimatableBody2D = $AnimatableBody2D
@onready var Sprite: Sprite2D = $AnimatableBody2D/Sprite2D
@onready var Collider: CollisionShape2D = $AnimatableBody2D/CollisionShape2D

@export_category("Platform Properties")
@export var platformTexture: Texture2D
@export var scaleWidth: float = 1.0
@export var scaleHeight: float = 1.0
@export var oneWay: bool = false

@export_category("Platform Movement")
@export var speed = 25
var pathProgress = 0

var previousPlatformPosition: Vector2
var platformPosition: Vector2
var platformVelocity: Vector2
var platformExtents: Vector2

func _ready() -> void:
	Sprite.texture = platformTexture
	#Body.scale = Vector2(scaleWidth, scaleHeight)
	Sprite.scale = Vector2(scaleWidth, scaleHeight)
	Path.progress = 0
	pathProgress = 0
	Collider.one_way_collision = oneWay
	
	ResizeColliderToSprite()
	platformExtents = Collider.shape.extents


func _process(delta: float) -> void:
	# Only move the platforms in game, not the editor
	if (!Engine.is_editor_hint()):
		pathProgress += (speed * delta)
		Path.set_progress(pathProgress)
	
	if (platformPosition != global_position):
		previousPlatformPosition = platformPosition
		platformPosition = Body.global_position
		platformVelocity = (platformPosition - previousPlatformPosition) / delta


func GetPlatformPosition() -> Vector2:
	return platformPosition

func GetPlatformVelocity() -> Vector2:
	return platformVelocity

func GetExtents() -> Vector2:
	return platformExtents

func ResizeColliderToSprite():
	# Ensure the sprite has a valid texture
	if (Sprite.texture):
		var _spriteSize = Sprite.get_rect().size * Sprite.scale
		# Check if the collider has a shape
		if (Collider.shape is RectangleShape2D):
			# Adjust the size of the RectangleShape2D
			Collider.shape.extents = _spriteSize / 2
		elif (Collider.shape is CircleShape2D):
			# Adjust the radius of the CircleShape2D (if appropriate)
			Collider.shape.radius = max(_spriteSize.x, _spriteSize.y) / 2
		else:
			print("Unsupported collider shape.")
	else:
		print("Sprite texture is missing!")
