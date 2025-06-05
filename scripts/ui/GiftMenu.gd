extends Control

signal gift_selected(gift_id)

@onready var gift_list = $GiftList
@onready var gift_template = preload("res://scenes/ui/GiftButton.tscn")

var available_gifts = [
	{
		"id": 0,
		"name": "Flor",
		"quantity": 3,
		"description": "Um símbolo de paz e respeito",
		"effect": "Reduz a agressividade do fantasma"
	},
	{
		"id": 1,
		"name": "Chocolate",
		"quantity": 2,
		"description": "Um doce para adoçar o humor",
		"effect": "Aumenta a chance de sucesso na conversa"
	},
	{
		"id": 2,
		"name": "Livro",
		"quantity": 1,
		"description": "Uma história para compartilhar",
		"effect": "Revela informações sobre o fantasma"
	},
	{
		"id": 3,
		"name": "Jóia",
		"quantity": 1,
		"description": "Um objeto precioso",
		"effect": "Aumenta significativamente a chance de sucesso"
	}
]

func _ready():
	populate_gifts()

func populate_gifts():
	# Limpa a lista atual
	for child in gift_list.get_children():
		child.queue_free()
	
	# Adiciona os presentes disponíveis
	for gift in available_gifts:
		var gift_button = gift_template.instantiate()
		gift_list.add_child(gift_button)
		
		# Configura o botão
		gift_button.setup(gift)
		gift_button.pressed.connect(_on_gift_button_pressed.bind(gift.id))

func _on_gift_button_pressed(gift_id):
	gift_selected.emit(gift_id)
	hide() 