extends Node3D

# Referências aos managers (autoloads)
@onready var game_manager = get_node("/root/GameManager")
@onready var state_manager = get_node("/root/GameStateManager")
@onready var ui_manager = get_node("/root/UIManager")
@onready var scene_manager = get_node("/root/SceneManager")

# Referência ao jogador
@onready var player = $Player

# Variáveis do mundo
var is_paused: bool = false
var current_map: Node = null
var dialog_system: CanvasLayer = null
var intro_dialog_shown: bool = false

# Cena do sistema de diálogos
var dialog_scene = preload("res://scenes/ui/dialog_system.tscn")

func _ready():
	# Inicializa o estado do jogo como PLAYING
	state_manager.change_state(state_manager.GameState.PLAYING)
	# Mouse sempre visível
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Conecta sinais do jogador
	if player:
		player.connect("health_changed", _on_player_health_changed)
		player.connect("game_over", _on_player_game_over)
	
	# Conecta sinais do SceneManager
	scene_manager.connect("map_changed", _on_map_changed)
	
	# Inicia a sequência de diálogos de introdução
	if not intro_dialog_shown:
		start_intro_dialog()

func _on_map_changed(map_path: String):
	# Remove o mapa atual se existir
	if current_map:
		current_map.queue_free()
	
	# Carrega e instancia o novo mapa
	var map_scene = load(map_path)
	if map_scene:
		current_map = map_scene.instantiate()
		add_child(current_map)
		# Posiciona o mapa na posição correta (ajuste conforme necessário)
		current_map.position = Vector3.ZERO

func _process(_delta):
	# Verifica se o jogo está pausado
	if Input.is_action_just_pressed("ui_cancel"):  # Tecla ESC
		toggle_pause()

func toggle_pause():
	print("[World] Alternando estado de pausa...")
	
	if not is_paused:
		# Pausa o jogo
		pause_game()
	else:
		# Despausa o jogo
		unpause_game()

func pause_game():
	"""Pausa o jogo"""
	print("[World] Pausando o jogo...")
	is_paused = true
	get_tree().paused = true
	state_manager.change_state(state_manager.GameState.PAUSED)
	# Mostra o menu de pause
	ui_manager.show_ui("pause_menu")
	# Conecta aos sinais do menu
	_connect_pause_menu_signals()

func unpause_game():
	"""Despausa o jogo"""
	print("[World] Despausando o jogo...")
	is_paused = false
	get_tree().paused = false
	state_manager.change_state(state_manager.GameState.PLAYING)
	# Esconde o menu de pause
	ui_manager.hide_ui("pause_menu")

func _connect_pause_menu_signals():
	"""Conecta aos sinais do menu de pause"""
	if ui_manager and ui_manager.active_ui.has("pause_menu"):
		var pause_menu = ui_manager.active_ui["pause_menu"]
		if pause_menu and is_instance_valid(pause_menu):
			# Conecta ao botão Continuar
			var resume_button = pause_menu.get_node_or_null("MenuContainer/ResumeButton")
			if resume_button and not resume_button.is_connected("pressed", unpause_game):
				resume_button.pressed.connect(unpause_game)
				print("[World] Conectado ao botão Continuar do menu de pause")
			
			# Conecta ao botão Menu Principal
			var main_menu_button = pause_menu.get_node_or_null("MenuContainer/MainMenuButton")
			if main_menu_button and not main_menu_button.is_connected("pressed", _on_main_menu_pressed):
				main_menu_button.pressed.connect(_on_main_menu_pressed)
				print("[World] Conectado ao botão Menu Principal do menu de pause")

func _on_main_menu_pressed():
	"""Chamado quando o botão de menu principal é pressionado"""
	print("[World] Botão Menu Principal pressionado - resetando estado")
	is_paused = false
	get_tree().paused = false

func _on_player_health_changed(new_health: int):
	# Atualiza a vida do jogador no GameManager
	game_manager.player_health = new_health
	game_manager.health_changed.emit(new_health)

func _on_player_game_over():
	# Quando o jogador morre
	game_manager.game_over.emit()
	state_manager.change_state(state_manager.GameState.GAME_OVER)

# Função para reiniciar o jogo
func restart_game():
	game_manager.reset_game()
	state_manager.change_state(state_manager.GameState.PLAYING)
	get_tree().paused = false
	is_paused = false
	
	# Reposiciona o jogador e reseta sua vida
	if player:
		# Posição inicial do jogador (ajuste conforme necessário)
		player.global_position = Vector3(0, 0, 0)
		player.current_health = player.max_health
		player.emit_signal("health_changed", player.current_health)

# Função para salvar o estado do jogo
func save_game_state():
	game_manager.save_game()

# Função para carregar o estado do jogo
func load_game_state():
	game_manager.load_game()

# Função para iniciar a sequência de diálogos de introdução
func start_intro_dialog():
	print("[World] Iniciando sequência de diálogos de introdução...")
	
	# Pausa o jogador durante os diálogos
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
	
	# Instancia o sistema de diálogos
	dialog_system = dialog_scene.instantiate()
	add_child(dialog_system)
	
	# Conecta o sinal de finalização (quando o sistema se remove)
	dialog_system.tree_exiting.connect(_on_dialog_finished)
	
	intro_dialog_shown = true

# Função chamada quando os diálogos terminam
func _on_dialog_finished():
	print("[World] Diálogos finalizados, liberando controle do jogador...")
	
	# Libera o jogador para se mover
	if player:
		player.set_physics_process(true)
		player.set_process_input(true)
	
	dialog_system = null 
