extends Control

signal talk_option_selected(option_data)

# Dicionário com as opções de diálogo disponíveis
var talk_options = {
	"questions": {
		"origem": {
			"text": "De onde você veio?",
			"response": "Um sussurro ecoa: 'Do vazio entre os mundos...'",
			"effect": "neutral"
		},
		"motivo": {
			"text": "Por que você está aqui?",
			"response": "O espírito parece hesitar antes de responder: 'Busco vingança... ou talvez redenção...'",
			"effect": "neutral"
		},
		"memorias": {
			"text": "Você se lembra de sua vida anterior?",
			"response": "Fragmentos de memórias dolorosas parecem aflorar na presença do espírito.",
			"effect": "emotional"
		}
	},
	"conversations": {
		"compreensao": {
			"text": "Entendo sua dor...",
			"response": "O espírito parece se acalmar momentaneamente com suas palavras.",
			"effect": "positive"
		},
		"medo": {
			"text": "Você me assusta...",
			"response": "O espírito se alimenta de seu medo, ficando mais agressivo.",
			"effect": "negative"
		},
		"esperanca": {
			"text": "Existe esperança para você...",
			"response": "Uma luz tênue parece brilhar nos olhos do espírito.",
			"effect": "positive"
		}
	},
	"negotiations": {
		"paz": {
			"text": "Podemos resolver isso pacificamente?",
			"response": "O espírito considera sua proposta com cautela.",
			"effect": "negotiation"
		},
		"acordo": {
			"text": "Que tal fazermos um acordo?",
			"response": "O espírito parece interessado em negociar.",
			"effect": "negotiation"
		},
		"desafio": {
			"text": "Você não me intimida!",
			"response": "O espírito se prepara para o confronto.",
			"effect": "negative"
		}
	}
}

@onready var questions_list = $MainContainer/QuestionsList
@onready var conversations_list = $MainContainer/ConversationsList
@onready var negotiations_list = $MainContainer/NegotiationsList
@onready var response_label = $MainContainer/ResponseLabel
@onready var close_button = $MainContainer/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	_populate_talk_options()

func _populate_talk_options():
	# Limpa as listas existentes
	for list in [questions_list, conversations_list, negotiations_list]:
		for child in list.get_children():
			child.queue_free()
	
	# Popula as listas com as opções de diálogo
	for category in talk_options:
		var list = get_node("MainContainer/" + category.capitalize() + "List")
		for option_id in talk_options[category]:
			var option_data = talk_options[category][option_id]
			var button = _create_talk_button(option_data, category, option_id)
			list.add_child(button)

func _create_talk_button(option_data, category, option_id):
	var button = Button.new()
	button.text = option_data.text
	button.custom_minimum_size = Vector2(200, 40)
	button.pressed.connect(_on_talk_button_pressed.bind(category, option_id))
	return button

func _on_talk_button_pressed(category, option_id):
	var option_data = talk_options[category][option_id]
	response_label.text = option_data.response
	emit_signal("talk_option_selected", option_data)

func _on_close_pressed():
	queue_free()

func show_menu():
	show()
	response_label.text = "Selecione uma opção para conversar com o espírito." 
