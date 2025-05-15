extends CanvasLayer

@onready var health_label = $HealthLabel
@onready var ammo_label = $AmmoLabel
@onready var player_name_label = $PlayerNameLabel
@onready var message_label = $MessageLabel

var health: int = 100
var max_health: int = 100
var ammo: int = 30
var max_ammo: int = 30
var player_name: String = "Player"

func _ready():
	update_hud()

func set_health(value: int):
	health = clamp(value, 0, max_health)
	update_hud()

func set_ammo(value: int):
	ammo = clamp(value, 0, max_ammo)
	update_hud()

func set_player_name(name: String):
	player_name = name
	update_hud()

func show_message(msg: String, duration: float = 2.0):
	message_label.text = msg
	message_label.visible = true
	await get_tree().create_timer(duration).timeout
	message_label.visible = false

func update_hud():
	health_label.text = "Vida: %d/%d" % [health, max_health]
	ammo_label.text = "Munição: %d/%d" % [ammo, max_ammo]
	player_name_label.text = player_name 