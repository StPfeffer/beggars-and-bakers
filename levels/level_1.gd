extends Node2D

@onready
var player = $Player
@onready
var coin = $Player/Camera2D/coin
@onready
var coinLabel = $Player/Camera2D/CoinLabel

func _ready() -> void:
	player.set_camera_offset(player.camera.offset.x, -250)
	coin.sprite.position.y = -250
	coinLabel.position.y = -250
