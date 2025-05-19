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

func _ready():
	# Inicializa o estado do jogo como PLAYING
	state_manager.change_state(state_manager.GameState.PLAYING)
	
	# Conecta sinais do jogador
	if player:
		player.connect("health_changed", _on_player_health_changed)
		player.connect("died", _on_player_died)
	
	# Conecta sinais do SceneManager
	scene_manager.connect("map_changed", _on_map_changed)

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
	is_paused = !is_paused
	if is_paused:
		state_manager.change_state(state_manager.GameState.PAUSED)
		get_tree().paused = true
	else:
		state_manager.change_state(state_manager.GameState.PLAYING)
		get_tree().paused = false

func _on_player_health_changed(new_health: int):
	# Atualiza a vida do jogador no GameManager
	game_manager.player_health = new_health
	game_manager.health_changed.emit(new_health)

func _on_player_died():
	# Quando o jogador morre
	game_manager.game_over.emit()
	state_manager.change_state(state_manager.GameState.GAME_OVER)

# Função para reiniciar o jogo
func restart_game():
	game_manager.reset_game()
	state_manager.change_state(state_manager.GameState.PLAYING)
	get_tree().paused = false
	is_paused = false
	
	# Reposiciona o jogador se necessário
	if player:
		player.global_position = Vector3(0, 0, 0)  # Ajuste para a posição inicial desejada
		player.health = player.max_health

# Função para salvar o estado do jogo
func save_game_state():
	game_manager.save_game()

# Função para carregar o estado do jogo
func load_game_state():
	game_manager.load_game() 
