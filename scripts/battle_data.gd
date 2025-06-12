extends Node

# Sinal para notificar quando um presente é coletado
signal gift_collected(grief_stage: String)

# Dados dos presentes coletados
var collected_gifts: Dictionary = {
	"negacao": 0,
	"raiva": 0,
	"barganha": 0,
	"depressao": 0,
	"aceitacao": 0
}

# Dados da batalha
var current_battle_data: Dictionary = {
	"player_health": 100,
	"player_energy": 100,
	"enemy_health": 100,
	"enemy_energy": 100,
	"current_turn": "player"
}

var enemy_data = null 

func _ready():
	print("BattleData singleton initialized")
	print("Available grief stages: ", collected_gifts.keys())

# Função para adicionar um presente ao inventário
func add_gift(grief_stage: String) -> void:
	print("Attempting to add gift: ", grief_stage)
	if not collected_gifts.has(grief_stage):
		collected_gifts[grief_stage] = 0
	collected_gifts[grief_stage] += 1
	emit_signal("gift_collected", grief_stage)
	print("Presente coletado: ", grief_stage)

# Função para verificar se um presente específico foi coletado
func has_gift(grief_stage: String) -> bool:
	return collected_gifts.has(grief_stage) and collected_gifts[grief_stage] > 0

# Função para obter a quantidade de um presente específico
func get_gift_count(grief_stage: String) -> int:
	return collected_gifts.get(grief_stage, 0)

# Função para obter todos os presentes coletados
func get_all_gifts() -> Dictionary:
	return collected_gifts.duplicate()

# Função para resetar os presentes (útil para reiniciar o jogo)
func reset_gifts() -> void:
	collected_gifts.clear()
	print("Presentes resetados")

# Funções para gerenciar a batalha
func use_gift_in_battle(grief_stage: String) -> bool:
	if has_gift(grief_stage):
		collected_gifts[grief_stage] -= 1
		return true
	return false

func update_battle_data(data: Dictionary) -> void:
	current_battle_data.merge(data)

func get_battle_data() -> Dictionary:
	return current_battle_data.duplicate()

func reset_battle_data() -> void:
	current_battle_data = {
		"player_health": 100,
		"player_energy": 100,
		"enemy_health": 100,
		"enemy_energy": 100,
		"current_turn": "player"
	}

# Funções para atualizar a vida e energia
func update_player_health(amount: int) -> void:
	current_battle_data.player_health = max(0, min(100, current_battle_data.player_health + amount))
	print("Player health updated: ", current_battle_data.player_health)

func update_player_energy(amount: int) -> void:
	current_battle_data.player_energy = max(0, min(100, current_battle_data.player_energy + amount))
	print("Player energy updated: ", current_battle_data.player_energy)

func update_enemy_health(amount: int) -> void:
	current_battle_data.enemy_health = max(0, min(100, current_battle_data.enemy_health + amount))
	print("Enemy health updated: ", current_battle_data.enemy_health)

func update_enemy_energy(amount: int) -> void:
	current_battle_data.enemy_energy = max(0, min(100, current_battle_data.enemy_energy + amount))
	print("Enemy energy updated: ", current_battle_data.enemy_energy) 