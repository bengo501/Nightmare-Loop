extends CanvasLayer

@onready var health_label = $HealthLabel
@onready var ammo_label = $WeaponInfo/AmmoLabel
@onready var player_name_label = $PlayerInfo/PlayerNameLabel
@onready var player_icon = $PlayerInfo/PlayerIcon
@onready var weapon_icon = $WeaponInfo/WeaponIcon
@onready var xp_label = $XPLabel
@onready var stage_name_label = $StageNameLabel
@onready var minimap = $MinimapContainer/Minimap
@onready var item_icons = [
	$ItemsContainer/ItemSlot1/ItemIcon1,
	$ItemsContainer/ItemSlot2/ItemIcon2,
	$ItemsContainer/ItemSlot3/ItemIcon3,
	$ItemsContainer/ItemSlot4/ItemIcon4,
	$ItemsContainer/ItemSlot5/ItemIcon5
]
@onready var item_counts = [
	$ItemsContainer/ItemSlot1/ItemCount1,
	$ItemsContainer/ItemSlot2/ItemCount2,
	$ItemsContainer/ItemSlot3/ItemCount3,
	$ItemsContainer/ItemSlot4/ItemCount4,
	$ItemsContainer/ItemSlot5/ItemCount5
]

var health: int = 100
var max_health: int = 100
var ammo: int = 30
var max_ammo: int = 30
var player_name: String = "Player"
var xp: int = 0
var stage_name: String = "Fase 1"
var weapon_icon_texture: Texture2D = null
var player_icon_texture: Texture2D = null
var minimap_texture: Texture2D = null
var item_data := [null, null, null, null, null] # cada item: {icon, count}

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

func set_xp(value: int):
	xp = value
	update_hud()

func set_stage_name(name: String):
	stage_name = name
	update_hud()

func set_weapon_icon(texture: Texture2D):
	weapon_icon_texture = texture
	update_hud()

func set_player_icon(texture: Texture2D):
	player_icon_texture = texture
	update_hud()

func set_minimap(texture: Texture2D):
	minimap_texture = texture
	update_hud()

func set_item(slot: int, icon: Texture2D, count: int):
	if slot >= 0 and slot < 5:
		item_data[slot] = {"icon": icon, "count": count}
	update_hud()

func update_hud():
	health_label.text = "Vida: %d/%d" % [health, max_health]
	ammo_label.text = "Munição: %d/%d" % [ammo, max_ammo]
	player_name_label.text = player_name
	xp_label.text = "XP: %d" % xp
	stage_name_label.text = "Fase: %s" % stage_name
	if weapon_icon_texture:
		weapon_icon.texture = weapon_icon_texture
	if player_icon_texture:
		player_icon.texture = player_icon_texture
	if minimap_texture:
		minimap.texture = minimap_texture
	for i in range(5):
		if item_data[i]:
			item_icons[i].texture = item_data[i]["icon"]
			item_counts[i].text = "x%d" % item_data[i]["count"]
		else:
			item_icons[i].texture = null
			item_counts[i].text = "x0"
