extends Control

signal talk_option_selected(option_id)

@onready var option_list = $OptionList
@onready var option_template = preload("res://scenes/ui/TalkOptionButton.tscn")

var talk_options = [
	{
		"id": 0,
		"text": "Perguntar sobre o passado",
		"description": "Tenta entender a história do fantasma"
	},
	{
		"id": 1,
		"text": "Perguntar sobre o presente",
		"description": "Investiga a situação atual do fantasma"
	},
	{
		"id": 2,
		"text": "Perguntar sobre o futuro",
		"description": "Tenta descobrir os planos do fantasma"
	},
	{
		"id": 3,
		"text": "Tentar convencer",
		"description": "Tenta persuadir o fantasma a desistir"
	}
]

func _ready():
	populate_options()

func populate_options():
	# Limpa a lista atual
	for child in option_list.get_children():
		child.queue_free()
	
	# Adiciona as opções de conversa
	for option in talk_options:
		var option_button = option_template.instantiate()
		option_list.add_child(option_button)
		
		# Configura o botão
		option_button.setup(option)
		option_button.pressed.connect(_on_option_button_pressed.bind(option.id))

func _on_option_button_pressed(option_id):
	talk_option_selected.emit(option_id)
	hide() 