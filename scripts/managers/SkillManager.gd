extends Node

# Sinal emitido quando os pontos de habilidade mudam
signal skill_points_changed(new_points)
signal skill_upgraded(branch, level)

# Pontos de habilidade disponíveis
var skill_points: int = 3

# Habilidades adquiridas (branch -> level)
var acquired_skills: Dictionary = {
	"speed": 0,
	"damage": 0,
	"health": 0
}

func _ready():
	print("[SkillManager] Sistema de habilidades inicializado")

# Adiciona pontos de habilidade
func add_skill_points(amount: int):
	skill_points += amount
	skill_points_changed.emit(skill_points)
	print("[SkillManager] Adicionados ", amount, " pontos de habilidade. Total: ", skill_points)

# Gasta pontos de habilidade para melhorar uma habilidade
func upgrade_skill(branch: String, level: int) -> bool:
	# Verifica se tem pontos suficientes
	if skill_points <= 0:
		print("[SkillManager] Sem pontos de habilidade suficientes")
		return false
	
	# Verifica se a habilidade existe
	if not branch in acquired_skills:
		print("[SkillManager] Ramo de habilidade inválido: ", branch)
		return false
	
	# Verifica se o nível é válido (deve ser sequencial)
	if level != acquired_skills[branch] + 1:
		print("[SkillManager] Nível de habilidade inválido. Atual: ", acquired_skills[branch], " Tentando: ", level)
		return false
	
	# Verifica se não excede o máximo (3 níveis por habilidade)
	if level > 3:
		print("[SkillManager] Nível máximo de habilidade atingido")
		return false
	
	# Aplica o upgrade
	skill_points -= 1
	acquired_skills[branch] = level
	
	# Emite sinais
	skill_points_changed.emit(skill_points)
	skill_upgraded.emit(branch, level)
	
	print("[SkillManager] Habilidade melhorada: ", branch, " para nível ", level)
	return true

# Retorna o nível atual de uma habilidade
func get_skill_level(branch: String) -> int:
	if branch in acquired_skills:
		return acquired_skills[branch]
	return 0

# Retorna os pontos de habilidade disponíveis
func get_skill_points() -> int:
	return skill_points

# Retorna todas as habilidades adquiridas
func get_all_skills() -> Dictionary:
	return acquired_skills.duplicate()

# Reseta todas as habilidades (para novo jogo)
func reset_skills():
	skill_points = 3
	acquired_skills = {
		"speed": 0,
		"damage": 0,
		"health": 0
	}
	skill_points_changed.emit(skill_points)
	print("[SkillManager] Habilidades resetadas")

# Verifica se uma habilidade pode ser melhorada
func can_upgrade_skill(branch: String, level: int) -> bool:
	if skill_points <= 0:
		return false
	
	if not branch in acquired_skills:
		return false
	
	if level != acquired_skills[branch] + 1:
		return false
	
	if level > 3:
		return false
	
	return true 