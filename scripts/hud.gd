extends CanvasLayer

# Referências para os elementos da HUD
@onready var health_bar = $TopBar/TopBar_PlayerInfoVBox/HealthBar
@onready var xp_bar = $TopBar/TopBar_PlayerInfoVBox/XPBar
@onready var ammo_label = $WeaponPanel/WeaponInfo/WeaponInfo/AmmoLabel
@onready var player_name_label = $TopBar/TopBar_PlayerInfoVBox/PlayerNameLabel
@onready var player_icon = $TopBar/PlayerIcon
@onready var weapon_icon = $WeaponPanel/WeaponInfo/WeaponInfo/WeaponIcon
@onready var stage_name_label = $TopBar/TopBar_ScoreLevelVBox/StageNameLabel
@onready var minimap = $TopBar/TopBar_ScoreLevelVBox/MinimapPanel/Minimap/Minimap
@onready var score_label = $TopBar/TopBar_ScoreLevelVBox/ScoreLabel
@onready var level_label = $TopBar/TopBar_ScoreLevelVBox/LevelLabel
@onready var lucidity_points_label = $TopBar/TopBar_ScoreLevelVBox/LucidityPointsLabel
@onready var crosshair = $Crosshair
@onready var item_icons = [
	$ItemsPanel/ItemsContainer/ItemsContainer/ItemSlot1/ItemsContainer_ItemSlot1/ItemIcon1,
	$ItemsPanel/ItemsContainer/ItemsContainer/ItemSlot2/ItemsContainer_ItemSlot2/ItemIcon2,
	$ItemsPanel/ItemsContainer/ItemsContainer/ItemSlot3/ItemsContainer_ItemSlot3/ItemIcon3,
	$ItemsPanel/ItemsContainer/ItemsContainer/ItemSlot4/ItemsContainer_ItemSlot4/ItemIcon4,
	$ItemsPanel/ItemsContainer/ItemsContainer/ItemSlot5/ItemsContainer_ItemSlot5/ItemIcon5
]
@onready var item_counts = [
	$ItemsPanel/ItemsContainer/ItemsContainer/ItemSlot1/ItemsContainer_ItemSlot1/ItemCount1,
	$ItemsPanel/ItemsContainer/ItemsContainer/ItemSlot2/ItemsContainer_ItemSlot2/ItemCount2,
	$ItemsPanel/ItemsContainer/ItemsContainer/ItemSlot3/ItemsContainer_ItemSlot3/ItemCount3,
	$ItemsPanel/ItemsContainer/ItemsContainer/ItemSlot4/ItemsContainer_ItemSlot4/ItemCount4,
	$ItemsPanel/ItemsContainer/ItemsContainer/ItemSlot5/ItemsContainer_ItemSlot5/ItemCount5
]

# Referências para os labels de gifts
@onready var gift_labels = {
	"negacao": $GiftsPainel/GiftsList/NegacaoHBox/NegacaoLabel,
	"raiva": $GiftsPainel/GiftsList/RaivaHBox/RaivaLabel,
	"barganha": $GiftsPainel/GiftsList/BarganhaHBox/BarganhaLabel,
	"depressao": $GiftsPainel/GiftsList/DepressaoHBox/DepressaoLabel,
	"aceitacao": $GiftsPainel/GiftsList/AceitacaoHBox/AceitacaoLabel
}

# Referências para os ícones de gifts
@onready var gift_icons = {
	"negacao": $GiftsPainel/GiftsList/NegacaoHBox/NegacaoIcon,
	"raiva": $GiftsPainel/GiftsList/RaivaHBox/RaivaIcon,
	"barganha": $GiftsPainel/GiftsList/BarganhaHBox/BarganhaIcon,
	"depressao": $GiftsPainel/GiftsList/DepressaoHBox/DepressaoIcon,
	"aceitacao": $GiftsPainel/GiftsList/AceitacaoHBox/AceitacaoIcon
}

# Variáveis de estado da HUD
var health: float = 100.0
var max_health: float = 100.0
var xp: float = 0.0
var max_xp: float = 100.0
var ammo: int = 30
var max_ammo: int = 30
var player_name: String = "Player"
var stage_name: String = "Fase 1"
var score: int = 0
var level: int = 1
var lucidity_points: int = 0
var weapon_icon_texture: Texture2D = null
var player_icon_texture: Texture2D = null
var minimap_texture: Texture2D = null
var items: Array = [null, null, null, null, null] # Inicializa com 5 slots vazios

# Variáveis para os gifts
var gifts: Dictionary = {
	"negacao": 0,
	"raiva": 0,
	"barganha": 0,
	"depressao": 0,
	"aceitacao": 0
}

# Fontes customizadas
var font_title: Font = null # preload("res://assets/fonts/Orbitron-Bold.ttf")
var font_label: Font = null # preload("res://assets/fonts/Roboto-Regular.ttf")

# Variável para controlar o modo da crosshair
var is_first_person_mode: bool = false

func _ready():
	# Aplica fontes customizadas
	_aplicar_fontes()
	
	# Conecta aos sinais do LucidityManager
	var lucidity_manager = get_node("/root/LucidityManager")
	if lucidity_manager:
		lucidity_manager.connect("lucidity_points_changed", _on_lucidity_points_changed)
	
	# Conectar ao GiftManager
	var gift_manager = get_node("/root/GiftManager")
	if gift_manager:
		gift_manager.connect("gift_collected", _on_gift_collected)
		gift_manager.connect("gifts_changed", _on_gifts_changed)
		# Inicializa os gifts com os valores atuais
		set_all_gifts(gift_manager.get_all_gifts())
	
	update_hud()

# Atualiza a barra de vida
func set_health(value: float, max_value: float = 100.0):
	print("[HUD] set_health chamado: ", value, "/", max_value)
	health = value
	max_health = max_value
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	update_hud()

# Atualiza a barra de XP
func set_xp(value: float, max_value: float = 100.0):
	xp = value
	max_xp = max_value
	update_hud()

# Atualiza munição
func set_ammo(value: int, max_value: int = 30):
	ammo = value
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

# Atualiza pontos de lucidez
func set_lucidity_points(value: int):
	lucidity_points = value
	update_hud()

# Atualiza gifts
func set_gift(gift_type: String, amount: int):
	if gift_type in gifts:
		gifts[gift_type] = amount
		update_hud()

# Atualiza todos os gifts
func set_all_gifts(new_gifts: Dictionary):
	for gift_type in gifts:
		if gift_type in new_gifts:
			gifts[gift_type] = new_gifts[gift_type]
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
		items[slot] = {"icon": icon, "count": count}
	update_hud()

# Atualiza todos os elementos da HUD
func update_hud():
	health_bar.max_value = max_health
	health_bar.value = health
	xp_bar.max_value = max_xp
	xp_bar.value = xp
	ammo_label.text = "Munição: %d/%d" % [ammo, max_ammo]
	player_name_label.text = player_name
	stage_name_label.text = "Fase: %s" % stage_name
	score_label.text = "Score: %d" % score
	level_label.text = "Level: %d" % level
	lucidity_points_label.text = "Pontos de Lucidez: %d" % lucidity_points
	
	# Atualiza os labels de gifts
	for gift_type in gift_labels:
		gift_labels[gift_type].text = "%s: %d" % [gift_type.capitalize(), gifts[gift_type]]
	
	if weapon_icon_texture:
		weapon_icon.texture = weapon_icon_texture
	if player_icon_texture:
		player_icon.texture = player_icon_texture
	if minimap_texture:
		minimap.texture = minimap_texture
	for i in range(5):
		if items[i]:
			item_icons[i].texture = items[i]["icon"]
			item_counts[i].text = "x%d" % items[i]["count"]
		else:
			item_icons[i].texture = null
			item_counts[i].text = "x0"

# Aplica fontes customizadas aos principais elementos
func _aplicar_fontes():
	if font_title:
		stage_name_label.add_theme_font_override("font", font_title)
		score_label.add_theme_font_override("font", font_title)
		level_label.add_theme_font_override("font", font_title)
		lucidity_points_label.add_theme_font_override("font", font_title)
		$GiftsPainel/GiftsTitle.add_theme_font_override("font", font_title)
	if font_label:
		ammo_label.add_theme_font_override("font", font_label)
		player_name_label.add_theme_font_override("font", font_label)
		for label in item_counts:
			label.add_theme_font_override("font", font_label)
		for label in gift_labels.values():
			label.add_theme_font_override("font", font_label)

# Define o modo da crosshair (primeira pessoa ou terceira pessoa)
func set_first_person_mode(is_first_person: bool):
	is_first_person_mode = is_first_person
	if crosshair and is_instance_valid(crosshair):
		crosshair.visible = is_first_person_mode

# Alias para compatibilidade
func set_crosshair_mode(is_first_person: bool):
	set_first_person_mode(is_first_person)

# Callback para quando os pontos de lucidez mudarem
func _on_lucidity_points_changed(points: int):
	set_lucidity_points(points)

# Callback para quando os gifts mudarem
func _on_gifts_changed(new_gifts: Dictionary):
	set_all_gifts(new_gifts)

# Callback para quando um presente for coletado
func _on_gift_collected(gift_type: String):
	if gift_type in gifts:
		gifts[gift_type] += 1
		update_hud()

# Função para resetar gifts ao iniciar novo jogo
func reset_gifts_on_new_game():
	var gift_manager = get_node("/root/GiftManager")
	if gift_manager:
		gift_manager.reset_gifts()
		set_all_gifts(gift_manager.get_all_gifts())
