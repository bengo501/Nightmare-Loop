extends CanvasLayer

# Referências para os elementos da HUD (atualizadas para nova estrutura)
@onready var health_bar = $PlayerIcon/HealthBar
@onready var xp_bar = $PlayerIcon/XPBar
@onready var ammo_label = null  # Removido temporariamente - não existe na nova estrutura
@onready var player_name_image = $PlayerIcon/PlayerNameImage
@onready var player_icon = $PlayerIcon
@onready var weapon_icon = $WeaponPanel/WeaponIcon
@onready var stage_image = $StageImage
@onready var minimap = $MinimapPanel/Minimap/Minimap
@onready var score_label = $TopBar/TopBar_ScoreLevelVBox/ScoreLabel
@onready var level_label = $TopBar/TopBar_ScoreLevelVBox/LevelLabel
@onready var lucidity_label = $LucidityPanel/LucidityContainer/LucidityLabel
@onready var crosshair = $Crosshair
@onready var gift_color_indicator = $WeaponPanel/GiftColorIndicator
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
	"negacao": $GiftsPainel/GiftsList/NegacaoVBox/NegacaoLabel,
	"raiva": $GiftsPainel/GiftsList/RaivaVBox/RaivaLabel,
	"barganha": $GiftsPainel/GiftsList/BarganhaVBox/BarganhaLabel,
	"depressao": $GiftsPainel/GiftsList/DepressaoVBox/DepressaoLabel,
	"aceitacao": $GiftsPainel/GiftsList/AceitacaoVBox/AceitacaoLabel
}

# Referências para os ícones de gifts
@onready var gift_icons = {
	"negacao": $GiftsPainel/GiftsList/NegacaoVBox/NegacaoIcon,
	"raiva": $GiftsPainel/GiftsList/RaivaVBox/RaivaIcon,
	"barganha": $GiftsPainel/GiftsList/BarganhaVBox/BarganhaIcon,
	"depressao": $GiftsPainel/GiftsList/DepressaoVBox/DepressaoIcon,
	"aceitacao": $GiftsPainel/GiftsList/AceitacaoVBox/AceitacaoIcon
}

# Referências para os marcadores de gifts
@onready var gift_markers = {
	"negacao": $GiftsPainel/GiftsList/NegacaoVBox/NegacaoMarker,
	"raiva": $GiftsPainel/GiftsList/RaivaVBox/RaivaMarker,
	"barganha": $GiftsPainel/GiftsList/BarganhaVBox/BarganhaMarker,
	"depressao": $GiftsPainel/GiftsList/DepressaoVBox/DepressaoMarker,
	"aceitacao": $GiftsPainel/GiftsList/AceitacaoVBox/AceitacaoMarker
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
var current_scene_path: String = ""

# Texturas para indicadores de cenário
var quarto_texture: Texture2D = preload("res://assets/textures/quartoTitle.png")
var estagio1_texture: Texture2D = preload("res://assets/textures/estagio1Title.png")
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

# Variáveis para o sistema de marcador de gifts
var current_gift_index: int = 0
var gift_order: Array[String] = ["negacao", "raiva", "barganha", "depressao", "aceitacao"]

# Cores correspondentes a cada gift
var gift_colors: Dictionary = {
	"negacao": Color(0, 0.6, 0.8, 1),      # Azul ciano/escuro
	"raiva": Color(0.2, 0.8, 0.2, 1),      # Verde
	"barganha": Color(0.5, 0.6, 0.7, 1),   # Cinza azulado
	"depressao": Color(0.3, 0.1, 0.6, 1),  # Roxo escuro
	"aceitacao": Color(1, 0.8, 0.2, 1)     # Amarelo/dourado
}

func _ready():
	# Adiciona ao grupo hud para facilitar localização
	add_to_group("hud")
	
	# Verifica se os nós essenciais existem
	_verify_nodes()
	
	# Aplica fontes customizadas
	_aplicar_fontes()
	
	# Conecta aos sinais do LucidityManager
	var lucidity_manager = get_node("/root/LucidityManager")
	if lucidity_manager:
		lucidity_manager.connect("lucidity_points_changed", _on_lucidity_points_changed)
		print("[HUD] Conectado ao LucidityManager com sucesso")
		# Inicializa com os pontos atuais
		set_lucidity_points(lucidity_manager.get_lucidity_points())
	else:
		print("[HUD] ERRO: LucidityManager não encontrado!")
	
	# Conectar ao GiftManager
	var gift_manager = get_node("/root/GiftManager")
	if gift_manager:
		gift_manager.connect("gift_collected", _on_gift_collected)
		gift_manager.connect("gifts_changed", _on_gifts_changed)
		# Inicializa os gifts com os valores atuais
		set_all_gifts(gift_manager.get_all_gifts())
	
	# Inicializa o marcador de gifts
	_update_gift_marker()
	
	# Detecta o cenário atual e atualiza a imagem
	_detect_and_update_scene()
	
	update_hud()

# Verifica se os nós essenciais existem e reporta problemas
func _verify_nodes():
	var missing_nodes = []
	
	if not health_bar:
		missing_nodes.append("PlayerIcon/HealthBar")
	if not player_icon:
		missing_nodes.append("PlayerIcon")
	if not lucidity_label:
		missing_nodes.append("LucidityPanel/LucidityContainer/LucidityLabel")
	if not stage_image:
		missing_nodes.append("StageImage")
	if not weapon_icon:
		missing_nodes.append("WeaponPanel/WeaponIcon")
	if not gift_color_indicator:
		missing_nodes.append("WeaponPanel/GiftColorIndicator")
	
	if missing_nodes.size() > 0:
		print("[HUD] AVISO: Nós não encontrados: ", missing_nodes)
		print("[HUD] Algumas funcionalidades podem não funcionar corretamente")
	else:
		print("[HUD] Todos os nós essenciais foram encontrados com sucesso")

func _input(event):
	# Controle do marcador de gifts pelas teclas 1-5
	if event.is_action_pressed("key_1"):
		_set_gift_marker(0)
	elif event.is_action_pressed("key_2"):
		_set_gift_marker(1)
	elif event.is_action_pressed("key_3"):
		_set_gift_marker(2)
	elif event.is_action_pressed("key_4"):
		_set_gift_marker(3)
	elif event.is_action_pressed("key_5"):
		_set_gift_marker(4)

# Atualiza a barra de vida
func set_health(value: float, max_value: float = 100.0):
	print("[HUD] set_health chamado: ", value, "/", max_value)
	health = value
	max_health = max_value
	
	if health_bar and is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = health
	else:
		print("[HUD] AVISO: health_bar não está disponível")
	
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
	# Verificações de segurança para evitar erros de null instance
	if health_bar and is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = health
	
	if xp_bar and is_instance_valid(xp_bar):
		xp_bar.max_value = max_xp
		xp_bar.value = xp
	
	# player_name_image é uma imagem fixa, não precisa de atualização
	
	# Detecta e atualiza a imagem do cenário automaticamente
	_detect_and_update_scene()
	
	if score_label and is_instance_valid(score_label):
		score_label.text = "Score: %d" % score
	
	if level_label and is_instance_valid(level_label):
		level_label.text = "Level: %d" % level
	
	if lucidity_label and is_instance_valid(lucidity_label):
		lucidity_label.text = str(lucidity_points)
	
	# Atualiza os labels de gifts
	for gift_type in gift_labels:
		var label = gift_labels[gift_type]
		if label and is_instance_valid(label):
			label.text = "%s: %d" % [gift_type.capitalize(), gifts[gift_type]]
	
	if weapon_icon_texture and weapon_icon and is_instance_valid(weapon_icon):
		weapon_icon.texture = weapon_icon_texture
	
	if player_icon_texture and player_icon and is_instance_valid(player_icon):
		player_icon.texture = player_icon_texture
	
	if minimap_texture and minimap and is_instance_valid(minimap):
		minimap.texture = minimap_texture
	
	# Atualiza itens do inventário
	for i in range(5):
		if i < item_icons.size() and item_icons[i] and is_instance_valid(item_icons[i]):
			if items[i]:
				item_icons[i].texture = items[i]["icon"]
			else:
				item_icons[i].texture = null
		
		if i < item_counts.size() and item_counts[i] and is_instance_valid(item_counts[i]):
			if items[i]:
				item_counts[i].text = "x%d" % items[i]["count"]
			else:
				item_counts[i].text = "x0"

# Aplica fontes customizadas aos principais elementos
func _aplicar_fontes():
	if font_title:
		if level_label and is_instance_valid(level_label):
			level_label.add_theme_font_override("font", font_title)
		if lucidity_label and is_instance_valid(lucidity_label):
			lucidity_label.add_theme_font_override("font", font_title)
		var gifts_title = get_node_or_null("GiftsPainel/GiftsTitle")
		if gifts_title and is_instance_valid(gifts_title):
			gifts_title.add_theme_font_override("font", font_title)
	
	if font_label:
		# ammo_label foi removido temporariamente
		# player_name_image é uma imagem, não precisa de fonte
		
		for i in range(item_counts.size()):
			if item_counts[i] and is_instance_valid(item_counts[i]):
				item_counts[i].add_theme_font_override("font", font_label)
		
		for label in gift_labels.values():
			if label and is_instance_valid(label):
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
	print("[HUD] Pontos de lucidez atualizados: ", points)
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

# Funções para o sistema de marcador de gifts
func _set_gift_marker(index: int):
	if index >= 0 and index < gift_order.size():
		current_gift_index = index
		_update_gift_marker()

func _update_gift_marker():
	# Esconde todos os marcadores
	for marker in gift_markers.values():
		if marker and is_instance_valid(marker):
			marker.visible = false
	
	# Mostra o marcador atual
	if current_gift_index >= 0 and current_gift_index < gift_order.size():
		var current_gift = gift_order[current_gift_index]
		if current_gift in gift_markers:
			var marker = gift_markers[current_gift]
			if marker and is_instance_valid(marker):
				marker.visible = true
		
		# Atualiza o indicador de cor perto da arma
		if current_gift in gift_colors and gift_color_indicator and is_instance_valid(gift_color_indicator):
			gift_color_indicator.color = gift_colors[current_gift]

# Função para obter o gift atualmente selecionado
func get_selected_gift() -> String:
	if current_gift_index >= 0 and current_gift_index < gift_order.size():
		return gift_order[current_gift_index]
	return ""

# Função para obter o índice do gift selecionado
func get_selected_gift_index() -> int:
	return current_gift_index

# Detecta o cenário atual e atualiza a imagem correspondente
func _detect_and_update_scene():
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene_path = current_scene.scene_file_path
		print("[HUD] Cenário atual detectado: ", current_scene_path)
		_update_stage_image()

# Atualiza a imagem do cenário baseado na cena atual
func _update_stage_image():
	if not stage_image:
		return
		
	if current_scene_path.contains("map_2.tscn"):
		stage_image.texture = estagio1_texture
		print("[HUD] Imagem atualizada para Estágio 1")
	else:
		# Para hub/world ou qualquer outra cena
		stage_image.texture = quarto_texture
		print("[HUD] Imagem atualizada para Quarto")

# Função para ser chamada quando a cena muda
func update_scene_indicator():
	_detect_and_update_scene()
