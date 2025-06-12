extends Node

# Sinais
signal health_changed(new_health: int)
signal game_over
signal skill_unlocked(skill_name: String)

# Variáveis do jogador
var player_health: int = 100
var player_max_health: int = 100
var player_level: int = 1
var player_experience: int = 0
var player_experience_to_next_level: int = 100
var player_score: int = 0
var player_lucidity_points: int = 0
var player_skill_points: int = 3  # Pontos iniciais de habilidade

# Variáveis do jogo
var current_level: int = 1
var is_game_over: bool = false
var is_paused: bool = false

# Dicionário para armazenar habilidades desbloqueadas
var unlocked_skills: Dictionary = {
	"speed": false,
	"damage": false,
	"health": false
}

func _ready():
	print("[GameManager] Inicializando...")
	reset_game()

func reset_game():
	print("[GameManager] Resetando jogo...")
	player_health = player_max_health
	player_level = 1
	player_experience = 0
	player_experience_to_next_level = 100
	player_score = 0
	player_lucidity_points = 0
	player_skill_points = 3
	is_game_over = false
	is_paused = false
	
	# Reseta habilidades
	for skill in unlocked_skills:
		unlocked_skills[skill] = false

func add_experience(amount: int):
	player_experience += amount
	print("[GameManager] Experiência adicionada: %d (Total: %d)" % [amount, player_experience])
	
	# Verifica se subiu de nível
	while player_experience >= player_experience_to_next_level:
		level_up()

func level_up():
	player_level += 1
	player_experience -= player_experience_to_next_level
	player_experience_to_next_level = int(player_experience_to_next_level * 1.5)
	player_skill_points += 1  # Adiciona um ponto de habilidade ao subir de nível
	
	print("[GameManager] Jogador subiu para o nível %d!" % player_level)
	print("[GameManager] Pontos de habilidade disponíveis: %d" % player_skill_points)

func add_score(points: int):
	player_score += points
	print("[GameManager] Pontos adicionados: %d (Total: %d)" % [points, player_score])

func add_lucidity_point():
	player_lucidity_points += 1
	print("[GameManager] Ponto de lucidez adicionado (Total: %d)" % player_lucidity_points)

func use_lucidity_point() -> bool:
	if player_lucidity_points > 0:
		player_lucidity_points -= 1
		print("[GameManager] Ponto de lucidez usado (Restantes: %d)" % player_lucidity_points)
		return true
	return false

func unlock_skill(skill_name: String) -> bool:
	if player_skill_points > 0 and not unlocked_skills.get(skill_name, false):
		player_skill_points -= 1
		unlocked_skills[skill_name] = true
		print("[GameManager] Habilidade '%s' desbloqueada!" % skill_name)
		skill_unlocked.emit(skill_name)
		return true
	return false

func save_game():
	var save_data = {
		"player_health": player_health,
		"player_max_health": player_max_health,
		"player_level": player_level,
		"player_experience": player_experience,
		"player_experience_to_next_level": player_experience_to_next_level,
		"player_score": player_score,
		"player_lucidity_points": player_lucidity_points,
		"player_skill_points": player_skill_points,
		"unlocked_skills": unlocked_skills
	}
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_file.store_var(save_data)
	print("[GameManager] Jogo salvo!")

func load_game():
	if FileAccess.file_exists("user://savegame.save"):
		var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
		var save_data = save_file.get_var()
		
		player_health = save_data.player_health
		player_max_health = save_data.player_max_health
		player_level = save_data.player_level
		player_experience = save_data.player_experience
		player_experience_to_next_level = save_data.player_experience_to_next_level
		player_score = save_data.player_score
		player_lucidity_points = save_data.player_lucidity_points
		player_skill_points = save_data.player_skill_points
		unlocked_skills = save_data.unlocked_skills
		
		print("[GameManager] Jogo carregado!")
		return true
	return false 