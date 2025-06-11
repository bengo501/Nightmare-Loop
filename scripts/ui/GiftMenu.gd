extends Control

signal gift_selected(gift_type)

var gifts = [
	{
		"name": "Negação",
		"type": "negacao",
		"description": "Causa 10 de dano ao fantasma"
	},
	{
		"name": "Raiva",
		"type": "raiva",
		"description": "Causa 15 de dano ao fantasma"
	},
	{
		"name": "Barganha",
		"type": "barganha",
		"description": "Causa 20 de dano ao fantasma"
	},
	{
		"name": "Depressão",
		"type": "depressao",
		"description": "Causa 25 de dano ao fantasma"
	},
	{
		"name": "Aceitação",
		"type": "aceitacao",
		"description": "Causa 30 de dano ao fantasma"
	}
]

@onready var gift_list = $GiftList
@onready var gift_buttons = []

func _ready():
	populate_gifts()

func populate_gifts():
	# Limpa a lista atual
	for button in gift_buttons:
		button.queue_free()
	gift_buttons.clear()
	
	# Cria botões para cada gift
	for gift in gifts:
		var button = Button.new()
		button.text = "%s\n%s" % [gift.name, gift.description]
		button.custom_minimum_size = Vector2(200, 60)
		button.pressed.connect(_on_gift_button_pressed.bind(gift.type))
		gift_list.add_child(button)
		gift_buttons.append(button)

func _on_gift_button_pressed(gift_type):
	emit_signal("gift_selected", gift_type)
	queue_free() 