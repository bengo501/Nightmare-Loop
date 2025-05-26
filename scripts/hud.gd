extends CanvasLayer

# Referências para os elementos da HUD
@onready var health_label = $TopBar_PlayerInfoVBox#HealthBar
@onready var xp_bar = $TopBar_PlayerInfoVBox#XPBar
@onready var ammo_label = $WeaponPanel#WeaponInfo/WeaponInfo#AmmoLabel
@onready var player_name_label = $TopBar_PlayerInfoVBox#PlayerNameLabel
@onready var player_icon = $TopBar#PlayerIcon
@onready var weapon_icon = $WeaponPanel#WeaponInfo/WeaponInfo#WeaponIcon
@onready var stage_name_label = $TopBar_ScoreLevelVBox#StageNameLabel
@onready var minimap = $TopBar_ScoreLevelVBox#MinimapPanel#Minimap
@onready var score_label = $TopBar_ScoreLevelVBox#ScoreLabel
@onready var level_label = $TopBar_ScoreLevelVBox#LevelLabel
@onready var crosshair = $Crosshair
@onready var item_icons = [$"ItemsPanel#ItemsContainer/ItemsContainer#ItemSlot1/ItemsContainer_ItemSlot1#ItemIcon1", $"ItemsPanel#ItemsContainer/ItemsContainer#ItemSlot2/ItemsContainer_ItemSlot2#ItemIcon2", $"ItemsPanel#ItemsContainer/ItemsContainer#ItemSlot3/ItemsContainer_ItemSlot3#ItemIcon3", $"ItemsPanel#ItemsContainer/ItemsContainer#ItemSlot4/ItemsContainer_ItemSlot4#ItemIcon4", $"ItemsPanel#ItemsContainer/ItemsContainer#ItemSlot5/ItemsContainer_ItemSlot5#ItemIcon5"]
@onready var item_counts = [$"ItemsPanel#ItemsContainer/ItemsContainer#ItemSlot1/ItemsContainer_ItemSlot1#ItemCount1", $"ItemsPanel#ItemsContainer/ItemsContainer#ItemSlot2/ItemsContainer_ItemSlot2#ItemCount2", $"ItemsPanel#ItemsContainer/ItemsContainer#ItemSlot3/ItemsContainer_ItemSlot3#ItemCount3", $"ItemsPanel#ItemsContainer/ItemsContainer#ItemSlot4/ItemsContainer_ItemSlot4#ItemCount4", $"ItemsPanel#ItemsContainer/ItemsContainer#ItemSlot5/ItemsContainer_ItemSlot5#ItemCount5"]

# Variáveis de estado da HUD
var health: int = 100
var max_health: int = 100
var xp: int = 0
var max_xp: int = 100
var ammo: int = 30
var max_ammo: int = 30
var player_name: String = "Player"
var stage_name: String = "Fase 1"
var score: int = 0
var level: int = 1
var weapon_icon_texture: Texture2D = null
var player_icon_texture: Texture2D = null
var minimap_texture: Texture2D = null
var item_data := [null, null, null, null, null] # cada item: {icon, count}

# Fontes customizadas
var font_title: Font = null # preload("res://assets/fonts/Orbitron-Bold.ttf")
var font_label: Font = null # preload("res://assets/fonts/Roboto-Regular.ttf")

# Variável para controlar o modo da crosshair
var is_first_person_mode: bool = false

func _ready():
	# Aplica fontes customizadas
	_aplicar_fontes()
	update_hud()

# Atualiza a barra de vida
func set_health(value: int):
	health = clamp(value, 0, max_health)
	update_hud()

# Atualiza a barra de XP
func set_xp(value: int, max_value: int = 100):
	xp = value
	max_xp = max_value
	update_hud()

# Atualiza munição
func set_ammo(value: int, max_value: int = 30):
	ammo = clamp(value, 0, max_value)
	max_ammo = max_value
	update_hud()

# Atualiza nome do jogador
func set_player_name(name: String):
	player_name = name
	update_hud()

# Atualiza nome da fase
func set_stage_name(name: String):
	stage_name = name
	update_hud()

# Atualiza score
func set_score(value: int):
	score = value
	update_hud()

# Atualiza level
func set_level(value: int):
	level = value
	update_hud()

# Atualiza ícone da arma
func set_weapon_icon(texture: Texture2D):
	weapon_icon_texture = texture
	update_hud()

# Atualiza ícone do jogador
func set_player_icon(texture: Texture2D):
	player_icon_texture = texture
	update_hud()

# Atualiza minimapa
func set_minimap(texture: Texture2D):
	minimap_texture = texture
	update_hud()

# Atualiza um item do inventário
func set_item(slot: int, icon: Texture2D, count: int):
	if slot >= 0 and slot < 5:
		item_data[slot] = {"icon": icon, "count": count}
	update_hud()

# Atualiza todos os elementos da HUD
func update_hud():
	health_label.value = health
	health_label.max_value = max_health
	xp_bar.value = xp
	xp_bar.max_value = max_xp
	ammo_label.text = "Munição: %d/%d" % [ammo, max_ammo]
	player_name_label.text = player_name
	stage_name_label.text = "Fase: %s" % stage_name
	score_label.text = "Score: %d" % score
	level_label.text = "Level: %d" % level
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

# Aplica fontes customizadas aos principais elementos
func _aplicar_fontes():
	if font_title:
		stage_name_label.add_theme_font_override("font", font_title)
		score_label.add_theme_font_override("font", font_title)
		level_label.add_theme_font_override("font", font_title)
	if font_label:
		ammo_label.add_theme_font_override("font", font_label)
		player_name_label.add_theme_font_override("font", font_label)
		for label in item_counts:
			label.add_theme_font_override("font", font_label)

# Define o modo da crosshair (primeira pessoa ou terceira pessoa)
# Chame este método ao alternar o modo de câmera
func set_crosshair_mode(first_person: bool):
	is_first_person_mode = first_person
	if is_first_person_mode:
		# Centraliza a crosshair
		crosshair.anchor_left = 0.5
		crosshair.anchor_top = 0.5
		crosshair.anchor_right = 0.5
		crosshair.anchor_bottom = 0.5
		crosshair.offset_left = -crosshair.rect_size.x / 2
		crosshair.offset_top = -crosshair.rect_size.y / 2
		crosshair.offset_right = crosshair.rect_size.x / 2
		crosshair.offset_bottom = crosshair.rect_size.y / 2
	else:
		# Faz a crosshair seguir o mouse
		crosshair.anchor_left = 0
		crosshair.anchor_top = 0
		crosshair.anchor_right = 0
		crosshair.anchor_bottom = 0
		crosshair.offset_left = 0
		crosshair.offset_top = 0
		crosshair.offset_right = 0
		crosshair.offset_bottom = 0
		update_crosshair_position()

# Atualiza a posição da crosshair para seguir o mouse (modo terceira pessoa)
func update_crosshair_position():
	if crosshair:
		var mouse_pos = get_viewport().get_mouse_position()
		print("Mouse pos:", mouse_pos)
		crosshair.rect_position = mouse_pos - crosshair.rect_size / 2

# Atualiza a crosshair em tempo real no _process
func _process(delta):
	if not is_first_person_mode:
		update_crosshair_position()
