extends CanvasLayer

# Referências para autoloads
@onready var game_manager = get_node_or_null("/root/GameManager")
@onready var state_manager = get_node_or_null("/root/GameStateManager")
@onready var scene_manager = get_node_or_null("/root/SceneManager")
@onready var gift_manager = get_node_or_null("/root/GiftManager")
@onready var lucidity_manager = get_node_or_null("/root/LucidityManager")

func _ready():
	connect_buttons()

func connect_buttons():
	# Conecta os botões aos seus respectivos handlers
	var wake_up_button = $MenuContainer/WakeUpButton
	var main_menu_button = $MenuContainer/MainMenuButton
	var quit_button = $MenuContainer/QuitButton
	
	if wake_up_button:
		wake_up_button.pressed.connect(_on_wake_up_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_wake_up_pressed():
	print("🌅 [GameOver] Botão Acordar/Continuar pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/WakeUpButton)
	
	# Restaura o player com vida máxima
	_restore_player_after_death()
	
	# PRESERVA PONTOS DE LUCIDEZ - NÃO ZERA NADA!
	print("🧠 [GameOver] Pontos de lucidez mantidos intactos")
	print("🔫 [GameOver] Munições (gifts) mantidas intactas")
	
	# Volta para o quarto (world.tscn)
	print("🏠 [GameOver] Voltando para o quarto...")
	state_manager.change_state(state_manager.GameState.PLAYING)
	scene_manager.change_scene("world")
	
	# Remove o menu após um pequeno delay
	await get_tree().create_timer(0.3).timeout
	queue_free()

func animate_button_press(button: Button):
	"""Anima o pressionamento de um botão"""
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(button, "scale", Vector2(1, 1), 0.1)

func _restore_player_after_death():
	"""Restaura o player com vida máxima após a morte"""
	print("❤️ [GameOver] Restaurando vida do player...")
	
	# Busca o player na cena atual
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		# Restaura vida máxima
		player.stats.hp = player.stats.max_hp
		player.current_health = player.max_health
		player.can_move = true  # Permite movimento novamente
		
		# Emite sinais de atualização
		player.emit_signal("health_changed", player.stats.hp)
		player.emit_signal("player_health_changed", player.stats.hp, player.stats.max_hp)
		
		print("❤️ [GameOver] Player restaurado com ", player.stats.hp, " HP")
	else:
		print("⚠️ [GameOver] Player não encontrado para restaurar")

func _on_main_menu_pressed():
	print("🏠 [GameOver] Botão Menu Principal pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/MainMenuButton)
	
	# Muda o estado do jogo
	state_manager.change_state(state_manager.GameState.MAIN_MENU)
	
	# Carrega a cena do menu principal
	scene_manager.change_scene("main_menu")
	
	# Remove o menu após um pequeno delay
	await get_tree().create_timer(0.3).timeout
	queue_free()

func _on_quit_pressed():
	print("❌ [GameOver] Botão Sair pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/QuitButton)
	
	# Sai do jogo
	get_tree().quit() 
