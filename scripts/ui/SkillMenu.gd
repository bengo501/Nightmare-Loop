extends Control

signal skill_selected(skill_data)

@onready var skill_list = $SkillList
@onready var skill_template = preload("res://scenes/ui/SkillButton.tscn")

var available_skills = [
	{
		"name": "Ataque Elemental",
		"type": "elemental",
		"mp_cost": 10,
		"power": 120,
		"description": "Causa dano elemental ao inimigo"
	},
	{
		"name": "Barreira Espiritual",
		"type": "support",
		"mp_cost": 15,
		"power": 0,
		"description": "Aumenta a defesa por 3 turnos"
	},
	{
		"name": "Purificação",
		"type": "support",
		"mp_cost": 20,
		"power": 0,
		"description": "Remove efeitos negativos e cura 30 HP"
	},
	{
		"name": "Maldição do Silêncio",
		"type": "curse",
		"mp_cost": 25,
		"power": 0,
		"description": "Impede o inimigo de usar habilidades por 2 turnos"
	}
]

func _ready():
	populate_skills()

func populate_skills():
	# Limpa a lista atual
	for child in skill_list.get_children():
		child.queue_free()
	
	# Adiciona as habilidades disponíveis
	for skill in available_skills:
		var skill_button = skill_template.instantiate()
		skill_list.add_child(skill_button)
		
		# Configura o botão
		skill_button.setup(skill)
		skill_button.pressed.connect(_on_skill_button_pressed.bind(skill))

func _on_skill_button_pressed(skill_data):
	skill_selected.emit(skill_data)
	hide() 