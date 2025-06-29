extends Node3D

# Referências aos managers (autoloads)
@onready var game_manager = get_node_or_null("/root/GameManager")
@onready var state_manager = get_node_or_null("/root/GameStateManager")
@onready var ui_manager = get_node_or_null("/root/UIManager")
@onready var scene_manager = get_node_or_null("/root/SceneManager")

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
	# Verifica se os managers foram carregados corretamente
	if not _validate_managers():
		push_error("[World] Erro: Alguns managers não foram carregados corretamente!")
		return
	
	# Inicializa o estado do jogo como PLAYING
	if state_manager:
		state_manager.change_state(state_manager.GameState.PLAYING)
	
	# Mouse sempre visível
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Conecta sinais do jogador
	if player:
		player.connect("health_changed", _on_player_health_changed)
		player.connect("game_over", _on_player_game_over)
	
	# Conecta sinais do SceneManager
	if scene_manager:
		scene_manager.connect("map_changed", _on_map_changed)
	
	# Inicia a sequência de diálogos de introdução
	if not intro_dialog_shown:
		start_intro_dialog()
	
	print("🌍 [World] Efeitos PSX aplicados automaticamente via GlobalPSXEffect!")

func _validate_managers() -> bool:
	"""Valida se todos os managers necessários estão disponíveis"""
	var missing_managers = []
	
	if not game_manager:
		missing_managers.append("GameManager")
	if not state_manager:
		missing_managers.append("GameStateManager")
	if not ui_manager:
		missing_managers.append("UIManager")
	if not scene_manager:
		missing_managers.append("SceneManager")
	
	if missing_managers.size() > 0:
		print("[World] ERRO: Managers não encontrados: ", missing_managers)
		return false
	
	print("[World] ✅ Todos os managers carregados com sucesso!")
	return true

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
	
	if state_manager:
		state_manager.change_state(state_manager.GameState.PAUSED)
	
	# Mostra o menu de pause
	if ui_manager:
		ui_manager.show_ui("pause_menu")
		# Conecta aos sinais do menu
		_connect_pause_menu_signals()

func unpause_game():
	"""Despausa o jogo"""
	print("[World] Despausando o jogo...")
	is_paused = false
	get_tree().paused = false
	
	if state_manager:
		state_manager.change_state(state_manager.GameState.PLAYING)
	
	# Esconde o menu de pause
	if ui_manager:
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
	if game_manager:
		game_manager.player_health = new_health
		game_manager.health_changed.emit(new_health)
	else:
		print("[World] AVISO: GameManager não disponível para atualizar vida")

func _on_player_game_over():
	# Quando o jogador morre
	if game_manager:
		game_manager.game_over.emit()
	
	if state_manager:
		state_manager.change_state(state_manager.GameState.GAME_OVER)

# Função para reiniciar o jogo
func restart_game():
	if game_manager and game_manager.has_method("reset_game"):
		game_manager.reset_game()
	else:
		print("[World] AVISO: GameManager não disponível ou método reset_game não encontrado")
	
	if state_manager:
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
	if game_manager and game_manager.has_method("save_game"):
		game_manager.save_game()
	else:
		print("[World] AVISO: GameManager não disponível ou método save_game não encontrado")

# Função para carregar o estado do jogo
func load_game_state():
	if game_manager and game_manager.has_method("load_game"):
		game_manager.load_game()
	else:
		print("[World] AVISO: GameManager não disponível ou método load_game não encontrado")

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
