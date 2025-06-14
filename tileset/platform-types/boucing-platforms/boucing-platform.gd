extends Area2D

@onready var Collider: CollisionShape2D = $CollisionShape2D
@onready var Sprite: Sprite2D = $Sprite
@onready var Animator: AnimationPlayer = $Animator

@export_category("Platform Properties")
@export var bounceAmount: float = 1.5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Animator.play("Normal")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if (body is PlayerController):
		if (Animator.current_animation == "Normal"):
			Animator.play("Launch")
			body.velocity.y = body.jumpSpeed * bounceAmount
	if (body is Carryable):
		if (Animator.current_animation == "Normal"):
			Animator.play("Launch")
			body.velocity = Vector2(sign(body.velocity.x) * 10, body.throwVelocity.y * 2)
			body.state = body.States.Launched

func _on_animator_animation_finished(anim_name: StringName) -> void:
	if (anim_name == "Launch"):
		Animator.play("Recoil")
	if (anim_name == "Recoil"):
		Animator.play("Normal")
