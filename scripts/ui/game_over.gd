extends "res://scripts/ui/base_menu.gd"

# Referências para autoloads
@onready var game_manager = get_node("/root/GameManager")
@onready var state_manager = get_node("/root/GameStateManager")
@onready var scene_manager = get_node("/root/SceneManager")
@onready var gift_manager = get_node("/root/GiftManager")
@onready var lucidity_manager = get_node("/root/LucidityManager")

func _ready():
	super._ready()
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
	
	# Zera as munições (gifts)
	_reset_ammo()
	
	# Preserva pontos de lucidez (não faz nada - eles já estão preservados)
	print("🧠 [GameOver] Pontos de lucidez preservados")
	
	# Volta para o quarto (world.tscn)
	print("🏠 [GameOver] Voltando para o quarto...")
	state_manager.change_state(state_manager.GameState.PLAYING)
	scene_manager.change_scene("world")
	
	# Anima a saída do menu
	animate_menu_out()

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

func _reset_ammo():
	"""Zera todas as munições (gifts) do player"""
	print("🔫 [GameOver] Zerando munições...")
	
	if gift_manager:
		# Zera todos os tipos de gifts
		gift_manager.set_gift_count("negacao", 0)
		gift_manager.set_gift_count("raiva", 0)
		gift_manager.set_gift_count("barganha", 0)
		gift_manager.set_gift_count("depressao", 0)
		gift_manager.set_gift_count("aceitacao", 0)
		
		print("🔫 [GameOver] Todas as munições foram zeradas")
	else:
		print("⚠️ [GameOver] GiftManager não encontrado")

func _on_main_menu_pressed():
	print("🏠 [GameOver] Botão Menu Principal pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/MainMenuButton)
	
	# Muda o estado do jogo
	state_manager.change_state(state_manager.GameState.MAIN_MENU)
	
	# Carrega a cena do menu principal
	scene_manager.change_scene("main_menu")
	
	# Anima a saída do menu
	animate_menu_out()

func _on_quit_pressed():
	print("❌ [GameOver] Botão Sair pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/QuitButton)
	
	# Sai do jogo
	get_tree().quit() 