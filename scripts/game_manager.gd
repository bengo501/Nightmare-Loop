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

func _ready():
	# Initialize game
	reset_game()

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