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
var is_skill_tree_open: bool = false
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
	
	# Verifica se a skill tree deve ser aberta
	if Input.is_action_just_pressed("skill_tree"):  # Tecla H
		toggle_skill_tree()

func toggle_pause():
	print("[World] Alternando estado de pausa...")
	
	if state_manager.current_state == state_manager.GameState.PLAYING:
		# Pausa o jogo
		print("[World] Pausando o jogo...")
		state_manager.change_state(state_manager.GameState.PAUSED)
		get_tree().paused = true
		is_paused = true
		# Mostra o menu de pause
		ui_manager.show_ui("pause_menu")
	else:
		# Despausa o jogo
		print("[World] Despausando o jogo...")
		state_manager.change_state(state_manager.GameState.PLAYING)
		get_tree().paused = false
		is_paused = false
		# Esconde o menu de pause
		ui_manager.hide_ui("pause_menu")

func toggle_skill_tree():
	print("[World] Alternando estado da skill tree...")
	
	if state_manager.current_state == state_manager.GameState.PLAYING:
		# Abre a skill tree
		print("[World] Abrindo skill tree...")
		state_manager.change_state(state_manager.GameState.SKILL_TREE)
		get_tree().paused = true
		is_skill_tree_open = true
		# Mostra a skill tree
		ui_manager.show_ui("skill_tree")
		# Esconde a HUD
		if ui_manager.hud_instance and is_instance_valid(ui_manager.hud_instance):
			ui_manager.hud_instance.visible = false
	else:
		# Fecha a skill tree
		print("[World] Fechando skill tree...")
		state_manager.change_state(state_manager.GameState.PLAYING)
		get_tree().paused = false
		is_skill_tree_open = false
		# Esconde a skill tree
		ui_manager.hide_ui("skill_tree")
		# Mostra a HUD
		if ui_manager.hud_instance and is_instance_valid(ui_manager.hud_instance):
			ui_manager.hud_instance.visible = true

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
	is_skill_tree_open = false
	
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
