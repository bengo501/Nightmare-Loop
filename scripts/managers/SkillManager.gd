extends Node

# Sinal emitido quando os pontos de habilidade mudam
signal skill_points_changed(new_points)
signal skill_upgraded(branch, level)

# Referência ao LucidityManager
var lucidity_manager: Node = null

# Habilidades adquiridas (branch -> level)
var acquired_skills: Dictionary = {
	"speed": 0,
	"damage": 0,
	"health": 0
}

# Custos por nível de habilidade
var skill_costs: Dictionary = {
	"speed": [1, 2, 3],   # Nível 1: 1 ponto, Nível 2: 2 pontos, Nível 3: 3 pontos
	"damage": [1, 2, 3],
	"health": [1, 2, 3]
}

# Descrições das habilidades
var skill_descriptions: Dictionary = {
	"speed": [
		"Velocidade +10%",
		"Velocidade +20% (total)",
		"Velocidade +30% (total)"
	],
	"damage": [
		"Dano +15%",
		"Dano +25% (total)",
		"Dano +35% (total)"
	],
	"health": [
		"Vida Máxima +20%",
		"Vida Máxima +30% (total)",
		"Vida Máxima +40% (total)"
	]
}

# Nomes das habilidades
var skill_names: Dictionary = {
	"speed": "Velocidade",
	"damage": "Dano",
	"health": "Resistência"
}

func _ready():
	print("[SkillManager] Inicializando SkillManager...")
	
	# Conecta ao LucidityManager
	lucidity_manager = get_node("/root/LucidityManager")
	if lucidity_manager:
		lucidity_manager.connect("lucidity_points_changed", _on_lucidity_points_changed)
		print("[SkillManager] ✓ Conectado ao LucidityManager")
		print("[SkillManager] Pontos iniciais: ", lucidity_manager.get_lucidity_points())
	else:
		print("[SkillManager] ❌ ERRO: LucidityManager não encontrado!")
	
	print("[SkillManager] Sistema de habilidades inicializado com sucesso")

# Callback para quando os pontos de lucidez mudam
func _on_lucidity_points_changed(new_points: int):
	print("[SkillManager] Callback: Pontos de lucidez atualizados para: ", new_points)
	skill_points_changed.emit(new_points)

# Adiciona pontos de habilidade (agora usa LucidityManager)
func add_skill_points(amount: int):
	if lucidity_manager:
		print("[SkillManager] Adicionando ", amount, " pontos via LucidityManager")
		lucidity_manager.add_lucidity_point(amount)
	else:
		print("[SkillManager] ERRO: LucidityManager não disponível para adicionar pontos")

# Gasta pontos de habilidade para melhorar uma habilidade
func upgrade_skill(branch: String, level: int) -> bool:
	print("\n[SkillManager] ====== PROCESSANDO UPGRADE ======")
	print("[SkillManager] Solicitação: ", branch, " nível ", level)
	
	# Verifica se a habilidade existe
	if not branch in acquired_skills:
		print("[SkillManager] ❌ Ramo de habilidade inválido: ", branch)
		return false
	
	var current_level = acquired_skills[branch]
	print("[SkillManager] Nível atual de ", branch, ": ", current_level)
	
	# Verifica se o nível é válido (deve ser sequencial)
	if level != current_level + 1:
		print("[SkillManager] ❌ Nível de habilidade inválido. Atual: ", current_level, " Tentando: ", level)
		return false
	
	# Verifica se não excede o máximo (3 níveis por habilidade)
	if level > 3:
		print("[SkillManager] ❌ Nível máximo de habilidade atingido")
		return false
	
	# Verifica se tem pontos suficientes
	var cost = get_skill_cost(branch, level)
	var current_points = get_skill_points()
	print("[SkillManager] Custo necessário: ", cost)
	print("[SkillManager] Pontos disponíveis: ", current_points)
	
	if current_points < cost:
		print("[SkillManager] ❌ Pontos insuficientes. Necessário: ", cost, " Disponível: ", current_points)
		return false
	
	# Gasta os pontos via LucidityManager
	print("[SkillManager] Tentando gastar ", cost, " pontos...")
	if lucidity_manager and lucidity_manager.use_lucidity_point(cost):
		# Aplica o upgrade
		acquired_skills[branch] = level
		
		print("[SkillManager] ✅ UPGRADE REALIZADO COM SUCESSO!")
		print("[SkillManager] ", branch, " agora está no nível ", level)
		print("[SkillManager] Pontos restantes: ", lucidity_manager.get_lucidity_points())
		
		# Emite sinal
		skill_upgraded.emit(branch, level)
		
		print("[SkillManager] ====== FIM DO UPGRADE ======\n")
		return true
	else:
		print("[SkillManager] ❌ ERRO: Não foi possível gastar pontos de lucidez")
		print("[SkillManager] ====== FIM DO UPGRADE ======\n")
		return false

# Retorna o custo de uma habilidade específica
func get_skill_cost(branch: String, level: int) -> int:
	if branch in skill_costs and level > 0 and level <= skill_costs[branch].size():
		return skill_costs[branch][level - 1]
	return 1  # Custo padrão

# Retorna a descrição de uma habilidade específica
func get_skill_description(branch: String, level: int) -> String:
	if branch in skill_descriptions and level > 0 and level <= skill_descriptions[branch].size():
		return skill_descriptions[branch][level - 1]
	return "Descrição não disponível"

# Retorna o nome de uma habilidade
func get_skill_name(branch: String) -> String:
	if branch in skill_names:
		return skill_names[branch]
	return branch.capitalize()

# Retorna o nível atual de uma habilidade
func get_skill_level(branch: String) -> int:
	if branch in acquired_skills:
		return acquired_skills[branch]
	return 0

# Retorna os pontos de habilidade disponíveis (agora do LucidityManager)
func get_skill_points() -> int:
	if lucidity_manager:
		var points = lucidity_manager.get_lucidity_points()
		return points
	else:
		print("[SkillManager] ERRO: LucidityManager não disponível - retornando 0")
		return 0

# Retorna todas as habilidades adquiridas
func get_all_skills() -> Dictionary:
	return acquired_skills.duplicate()

# Reseta todas as habilidades (para novo jogo)
func reset_skills():
	if lucidity_manager:
		lucidity_manager.reset_lucidity_points()
	acquired_skills = {
		"speed": 0,
		"damage": 0,
		"health": 0
	}
	print("[SkillManager] Habilidades resetadas")

# Verifica se uma habilidade pode ser melhorada
func can_upgrade_skill(branch: String, level: int) -> bool:
	if not branch in acquired_skills:
		return false
	
	var current_level = acquired_skills[branch]
	if level != current_level + 1:
		return false
	
	if level > 3:
		return false
	
	var cost = get_skill_cost(branch, level)
	var current_points = get_skill_points()
	if current_points < cost:
		return false
	
	return true

# Sistema para ganhar pontos de habilidade automaticamente
func award_skill_points_for_action(action: String):
	var points_awarded = 0
	
	match action:
		"ghost_defeated":
			points_awarded = 1
		"level_completed":
			points_awarded = 2
		"boss_defeated":
			points_awarded = 3
		"special_achievement":
			points_awarded = 1
	
	if points_awarded > 0:
		add_skill_points(points_awarded)
		print("[SkillManager] Pontos concedidos por '", action, "': ", points_awarded)

# Função de teste para testar compra de habilidade
func test_upgrade_skill():
	print("\n[SkillManager] ====== TESTE DE COMPRA ======")
	print("[SkillManager] Tentando comprar Velocidade nível 1...")
	
	var success = upgrade_skill("speed", 1)
	print("[SkillManager] Resultado: ", "SUCESSO" if success else "FALHA")
	print("[SkillManager] ====== FIM DO TESTE ======\n")

# Função de teste para adicionar pontos (tecla P)
func _input(event):
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_P):
		print("[SkillManager] Tecla P pressionada - adicionando 1 ponto de teste")
		add_skill_points(1)
	elif event.is_action_pressed("ui_cancel") and Input.is_key_pressed(KEY_T):
		print("[SkillManager] Tecla T pressionada - testando compra de habilidade")
		test_upgrade_skill()

# Salva o estado das habilidades
func save_skills() -> Dictionary:
	return {
		"acquired_skills": acquired_skills.duplicate()
	}

# Carrega o estado das habilidades
func load_skills(data: Dictionary):
	if "acquired_skills" in data:
		acquired_skills = data.acquired_skills.duplicate()
		print("[SkillManager] Habilidades carregadas: ", acquired_skills)