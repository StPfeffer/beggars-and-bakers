extends Node2D

@onready
var player = $Player
@onready
var coin = $Player/Camera2D/coin
@onready
var coinLabel = $Player/Camera2D/CoinLabel
@onready
var villageMusic = $VillageCenter/VillageMusic
@onready
var villageAtmosphere = $VillageCenter/VillageAtmosphere


func _ready() -> void:
	player.set_camera_offset(player.camera.offset.x, -250)
	coin.sprite.position.y = -250
	coinLabel.position.y = -250


func _on_village_atmosphere_finished() -> void:
	villageAtmosphere.play();


func _on_village_music_finished() -> void:
	villageMusic.play();
