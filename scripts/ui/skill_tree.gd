extends Control

# Referências aos botões
@onready var speed_buttons = [
	$Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed1,
	$Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed2,
	$Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed3
]

@onready var damage_buttons = [
	$Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage1,
	$Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage2,
	$Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage3
]

@onready var health_buttons = [
	$Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health1,
	$Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health2,
	$Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health3
]

# Variáveis de estado
var skill_points: int = 0
var unlocked_skills = {
	"speed": 0,
	"damage": 0,
	"health": 0
}

# Referência ao jogador
var player: Node

func _ready():
	# Conecta os sinais dos botões
	for button in speed_buttons:
		button.pressed.connect(_on_speed_button_pressed.bind(button))
	
	for button in damage_buttons:
		button.pressed.connect(_on_damage_button_pressed.bind(button))
	
	for button in health_buttons:
		button.pressed.connect(_on_health_button_pressed.bind(button))
	
	$Panel/CloseButton.pressed.connect(_on_close_button_pressed)
	
	# Busca o jogador
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# Inicialmente esconde a UI
	hide()
	
	# Atualiza o estado dos botões
	_update_button_states()

func _input(event):
	if event.is_action_pressed("skill_tree"): # Tecla H
		if visible:
			hide()
			get_tree().paused = false
		else:
			show()
			_update_button_states()
			get_tree().paused = true

func _update_button_states():
	# Atualiza os botões de velocidade
	for i in range(speed_buttons.size()):
		var button = speed_buttons[i]
		button.disabled = i > unlocked_skills.speed or skill_points < 1
	
	# Atualiza os botões de dano
	for i in range(damage_buttons.size()):
		var button = damage_buttons[i]
		button.disabled = i > unlocked_skills.damage or skill_points < 1
	
	# Atualiza os botões de vida
	for i in range(health_buttons.size()):
		var button = health_buttons[i]
		button.disabled = i > unlocked_skills.health or skill_points < 1
	
	# Atualiza o texto dos pontos
	$Panel/SkillPoints.text = "Pontos de Habilidade: " + str(skill_points)

func _on_speed_button_pressed(button: Button):
	var index = speed_buttons.find(button)
	if index > unlocked_skills.speed and skill_points >= 1:
		unlocked_skills.speed = index
		skill_points -= 1
		_apply_speed_upgrade()
		_update_button_states()

func _on_damage_button_pressed(button: Button):
	var index = damage_buttons.find(button)
	if index > unlocked_skills.damage and skill_points >= 1:
		unlocked_skills.damage = index
		skill_points -= 1
		_apply_damage_upgrade()
		_update_button_states()

func _on_health_button_pressed(button: Button):
	var index = health_buttons.find(button)
	if index > unlocked_skills.health and skill_points >= 1:
		unlocked_skills.health = index
		skill_points -= 1
		_apply_health_upgrade()
		_update_button_states()

func _on_close_button_pressed():
	hide()
	get_tree().paused = false

# Funções de aplicação das habilidades
func _apply_speed_upgrade():
	if player:
		var speed_multiplier = 1.0 + (unlocked_skills.speed * 0.1) # +10% por nível
		player.set_speed_multiplier(speed_multiplier)

func _apply_damage_upgrade():
	if player:
		var damage_multiplier = 1.0 + (unlocked_skills.damage * 0.15) # +15% por nível
		player.set_damage_multiplier(damage_multiplier)

func _apply_health_upgrade():
	if player:
		var health_multiplier = 1.0 + (unlocked_skills.health * 0.2) # +20% por nível
		player.set_health_multiplier(health_multiplier)

# Função para adicionar pontos de habilidade
func add_skill_points(amount: int):
	skill_points += amount
	_update_button_states()

# Função para salvar o progresso
func save_progress():
	var save_data = {
		"skill_points": skill_points,
		"unlocked_skills": unlocked_skills
	}
	return save_data

# Função para carregar o progresso
func load_progress(data: Dictionary):
	skill_points = data.get("skill_points", 0)
	unlocked_skills = data.get("unlocked_skills", {
		"speed": 0,
		"damage": 0,
		"health": 0
	})
	
	# Aplica todas as habilidades desbloqueadas
	_apply_speed_upgrade()
	_apply_damage_upgrade()
	_apply_health_upgrade()
	_update_button_states() 