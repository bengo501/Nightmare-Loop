extends Control

signal skill_selected(skill_data)

var available_skills = {
	"elemental": {
		"espirito_do_vento": {
			"name": "Espírito do Vento",
			"mp_cost": 5,
			"power": 15,
			"type": "wind",
			"description": "Invoca uma rajada de vento espiritual que causa dano ao inimigo."
		},
		"chama_espiritual": {
			"name": "Chama Espiritual",
			"mp_cost": 8,
			"power": 20,
			"type": "fire",
			"description": "Uma chama azulada que queima a essência espiritual do inimigo."
		},
		"gelo_do_abismo": {
			"name": "Gelo do Abismo",
			"mp_cost": 10,
			"power": 25,
			"type": "ice",
			"description": "Congela o inimigo com o frio do além."
		}
	},
	"support": {
		"barreira_espiritual": {
			"name": "Barreira Espiritual",
			"mp_cost": 12,
			"power": 0,
			"type": "support",
			"description": "Cria uma barreira que reduz o dano recebido."
		},
		"purificacao": {
			"name": "Purificação",
			"mp_cost": 15,
			"power": 0,
			"type": "heal",
			"description": "Remove efeitos negativos e cura uma pequena quantidade de HP."
		},
		"visao_espiritual": {
			"name": "Visão Espiritual",
			"mp_cost": 5,
			"power": 0,
			"type": "support",
			"description": "Revela fraquezas do inimigo."
		}
	},
	"curse": {
		"maldicao_do_silencio": {
			"name": "Maldição do Silêncio",
			"mp_cost": 20,
			"power": 30,
			"type": "curse",
			"description": "Silencia o inimigo, impedindo-o de usar habilidades."
		},
		"pesadelo_eterno": {
			"name": "Pesadelo Eterno",
			"mp_cost": 25,
			"power": 35,
			"type": "curse",
			"description": "Invoca os piores pesadelos do inimigo, causando dano mental."
		},
		"correntes_do_abismo": {
			"name": "Correntes do Abismo",
			"mp_cost": 18,
			"power": 0,
			"type": "curse",
			"description": "Prende o inimigo em correntes espirituais, reduzindo sua velocidade."
		}
	}
}

@onready var elemental_list = $MainContainer/ElementalList
@onready var support_list = $MainContainer/SupportList
@onready var curse_list = $MainContainer/CurseList
@onready var description_label = $MainContainer/DescriptionLabel
@onready var close_button = $MainContainer/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	_populate_skill_lists()

func _populate_skill_lists():
	# Limpa as listas existentes
	for list in [elemental_list, support_list, curse_list]:
		for child in list.get_children():
			child.queue_free()
	
	# Popula as listas com as habilidades
	for category in available_skills:
		var list = get_node("MainContainer/" + category.capitalize() + "List")
		for skill_id in available_skills[category]:
			var skill_data = available_skills[category][skill_id]
			var button = _create_skill_button(skill_data, category, skill_id)
			list.add_child(button)

func _create_skill_button(skill_data, category, skill_id):
	var button = Button.new()
	button.text = "%s (MP: %d)" % [skill_data.name, skill_data.mp_cost]
	button.custom_minimum_size = Vector2(200, 40)
	button.pressed.connect(_on_skill_button_pressed.bind(category, skill_id))
	return button

func _on_skill_button_pressed(category, skill_id):
	var skill_data = available_skills[category][skill_id]
	description_label.text = skill_data.description
	emit_signal("skill_selected", skill_data)

func _on_close_pressed():
	queue_free()

func show_menu():
	show()
	description_label.text = "Selecione uma habilidade para ver sua descrição." 