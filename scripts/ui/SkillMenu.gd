extends Control

signal skill_selected(skill_data)

var skills = [
	{
		"name": "Aumentar Dano",
		"type": "damage_boost",
		"mp_cost": 10,
		"description": "Aumenta o dano do próximo ataque"
	},
	{
		"name": "Cura",
		"type": "heal",
		"mp_cost": 20,
		"description": "Recupera 30 HP"
	},
	{
		"name": "Potencializar Gift",
		"type": "gift_boost",
		"mp_cost": 15,
		"description": "Aumenta a eficácia do próximo gift"
	}
]

@onready var skill_list = $SkillList
@onready var skill_buttons = []

func _ready():
	populate_skills()

func populate_skills():
	# Limpa a lista atual
	for button in skill_buttons:
		button.queue_free()
	skill_buttons.clear()
	
	# Cria botões para cada habilidade
	for skill in skills:
		var button = Button.new()
		button.text = "%s (MP: %d)\n%s" % [skill.name, skill.mp_cost, skill.description]
		button.custom_minimum_size = Vector2(200, 60)
		button.pressed.connect(_on_skill_button_pressed.bind(skill))
		skill_list.add_child(button)
		skill_buttons.append(button)

func _on_skill_button_pressed(skill_data):
	emit_signal("skill_selected", skill_data)
	queue_free() 