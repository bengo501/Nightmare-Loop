extends Control

signal item_selected(item_id)

@onready var item_list = $ItemList
@onready var item_template = preload("res://scenes/ui/ItemButton.tscn")

var available_items = [
	{
		"id": 0,
		"name": "Negação",
		"quantity": 3,
		"description": "Reduz o dano recebido em 50% por 1 turno"
	},
	{
		"id": 1,
		"name": "Raiva",
		"quantity": 2,
		"description": "Aumenta o dano causado em 50% por 1 turno"
	},
	{
		"id": 2,
		"name": "Barganha",
		"quantity": 4,
		"description": "Recupera 30% do HP máximo"
	},
	{
		"id": 3,
		"name": "Depressão",
		"quantity": 1,
		"description": "Reduz a velocidade do inimigo por 2 turnos"
	},
	{
		"id": 4,
		"name": "Aceitação",
		"quantity": 5,
		"description": "Remove todos os efeitos negativos"
	}
]

func _ready():
	populate_items()

func populate_items():
	# Limpa a lista atual
	for child in item_list.get_children():
		child.queue_free()
	
	# Adiciona os itens disponíveis
	for item in available_items:
		var item_button = item_template.instantiate()
		item_list.add_child(item_button)
		
		# Configura o botão
		item_button.setup(item)
		item_button.pressed.connect(_on_item_button_pressed.bind(item.id))

func _on_item_button_pressed(item_id):
	item_selected.emit(item_id)
	hide() 