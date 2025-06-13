extends Node

# Player stats
var player_health: int = 100
var player_max_health: int = 100
var player_score: int = 0
var player_level: int = 1

# Game progression
var current_level: int = 1
var enemies_defeated: int = 0
var game_time: float = 0.0

# Signals
signal health_changed(new_health: int)
signal score_changed(new_score: int)
signal level_up(new_level: int)
signal game_over
signal enemy_defeated

# References to other managers
@onready var scene_manager = get_node("/root/SceneManager")
@onready var state_manager = get_node("/root/GameStateManager")

# Configurações de opções
var settings = {
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"fullscreen": false,
	"vsync": true,
	"invert_y": false,
	"mouse_sensitivity": 1.0
}

func _ready():
	print("[GameManager] Iniciando GameManager...")
	# Initialize game
	reset_game()
	load_settings()
	
	# Conectar ao sinal node_added para detectar novos fantasmas
	get_tree().node_added.connect(_on_node_added)
	
	# Conectar ao sinal ghost_defeated de todos os fantasmas já presentes
	print("[GameManager] Procurando fantasmas na cena...")
	var ghosts = get_tree().get_nodes_in_group("ghosts")
	print("[GameManager] Fantasmas encontrados: ", ghosts.size())
	
	for ghost in ghosts:
		print("[GameManager] Conectando sinal ghost_defeated ao fantasma: " + ghost.name)
		if ghost.has_signal("ghost_defeated"):
			if not ghost.is_connected("ghost_defeated", _on_ghost_defeated):
				var error = ghost.ghost_defeated.connect(_on_ghost_defeated)
				if error != OK:
					push_error("[GameManager] Erro ao conectar sinal ghost_defeated: " + str(error))
				else:
					print("[GameManager] Sinal ghost_defeated conectado com sucesso ao fantasma: " + ghost.name)
		else:
			push_error("[GameManager] Fantasma não tem sinal ghost_defeated: " + ghost.name)
	
	print("[GameManager] Referência ao state_manager: ", state_manager)
	print("[GameManager] Referência ao scene_manager: ", scene_manager)

func _process(delta):
	if state_manager.current_state == state_manager.GameState.PLAYING:
		game_time += delta

# Game control functions
func reset_game() -> void:
	player_health = player_max_health
	player_score = 0
	player_level = 1
	current_level = 1
	enemies_defeated = 0
	game_time = 0.0
	health_changed.emit(player_health)
	score_changed.emit(player_score)

func take_damage(amount: int) -> void:
	player_health = max(0, player_health - amount)
	health_changed.emit(player_health)
	
	if player_health <= 0:
		game_over.emit()
		state_manager.change_state(state_manager.GameState.GAME_OVER)

func heal(amount: int) -> void:
	player_health = min(player_max_health, player_health + amount)
	health_changed.emit(player_health)

func add_score(points: int) -> void:
	player_score += points
	score_changed.emit(player_score)
	
	# Check for level up
	if player_score >= player_level * 1000:
		handle_level_up()

func handle_level_up() -> void:
	player_level += 1
	player_max_health += 20
	player_health = player_max_health
	level_up.emit(player_level)
	health_changed.emit(player_health)

func handle_enemy_defeated(enemy_type: String, points: int) -> void:
	enemies_defeated += 1
	add_score(points)
	enemy_defeated.emit(enemy_type)

# Save/Load game functions
func save_game() -> void:
	var save_data = {
		"player_health": player_health,
		"player_max_health": player_max_health,
		"player_score": player_score,
		"player_level": player_level,
		"current_level": current_level,
		"enemies_defeated": enemies_defeated,
		"game_time": game_time
	}
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_file.store_var(save_data)

func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.save"):
		return
		
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var save_data = save_file.get_var()
	
	player_health = save_data.player_health
	player_max_health = save_data.player_max_health
	player_score = save_data.player_score
	player_level = save_data.player_level
	current_level = save_data.current_level
	enemies_defeated = save_data.enemies_defeated
	game_time = save_data.game_time
	
	health_changed.emit(player_health)
	score_changed.emit(player_score)

func get_settings() -> Dictionary:
	return settings.duplicate()

func set_master_volume(value: float) -> void:
	settings["master_volume"] = value
	# Aqui você pode aplicar o volume no AudioServer, se desejar

func set_music_volume(value: float) -> void:
	settings["music_volume"] = value

func set_sfx_volume(value: float) -> void:
	settings["sfx_volume"] = value

func set_fullscreen(enabled: bool) -> void:
	settings["fullscreen"] = enabled
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)

func set_vsync(enabled: bool) -> void:
	settings["vsync"] = enabled
	# Implemente a lógica de VSync se necessário

func set_invert_y(enabled: bool) -> void:
	settings["invert_y"] = enabled

func set_mouse_sensitivity(value: float) -> void:
	settings["mouse_sensitivity"] = value

func save_settings() -> void:
	var config = ConfigFile.new()
	for key in settings.keys():
		config.set_value("options", key, settings[key])
	config.save("user://options.cfg")

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load("user://options.cfg") == OK:
		for key in settings.keys():
			settings[key] = config.get_value("options", key, settings[key]) 

func _on_ghost_defeated():
	print("\n[GameManager] ====== SINAL RECEBIDO ======")
	print("[GameManager] Função _on_ghost_defeated chamada!")
	print("[GameManager] Estado atual do jogo: ", state_manager.current_state)
	
	if not is_instance_valid(state_manager):
		push_error("[GameManager] Erro: state_manager não é válido!")
		return
		
	if not is_instance_valid(scene_manager):
		push_error("[GameManager] Erro: scene_manager não é válido!")
		return
	
	print("[GameManager] Mudando para a cena de batalha...")
	# Garante que a cena de batalha existe antes de tentar mudar
	var battle_scene = load("res://battle_scene.tscn")
	if battle_scene:
		scene_manager.change_scene("battle")
		print("[GameManager] Cena de batalha carregada com sucesso!")
		
		print("[GameManager] Fantasma derrotado! Trocando para estado BATTLE...")
		state_manager.change_state(state_manager.GameState.BATTLE)
		print("[GameManager] Estado após mudança: ", state_manager.current_state)
	else:
		push_error("[GameManager] Erro: Não foi possível carregar a cena de batalha!")
	print("[GameManager] ====== FIM DO SINAL ======\n")

func _on_node_added(node: Node) -> void:
	print("[GameManager] node_added chamado para: ", node.name)
	if node.is_in_group("ghosts"):
		print("[GameManager] Novo fantasma detectado: " + node.name)
		node.call_deferred("_connect_ghost_signal")

#func _on_node_added(node: Node) -> void:
	print("[GameManager] node_added chamado para: ", node.name)
	if node.is_in_group("ghosts"):
		print("[GameManager] Novo fantasma detectado: " + node.name)
		if node.has_signal("ghost_defeated"):
			if not node.is_connected("ghost_defeated", _on_ghost_defeated):
				var error = node.ghost_defeated.connect(_on_ghost_defeated)
				if error != OK:
					push_error("[GameManager] Erro ao conectar sinal ghost_defeated ao novo fantasma: " + str(error))
				else:
					print("[GameManager] Sinal ghost_defeated conectado com sucesso ao novo fantasma: " + node.name)
		else:
			push_error("[GameManager] Novo fantasma não tem sinal ghost_defeated: " + node.name) 
