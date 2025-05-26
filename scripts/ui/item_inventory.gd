extends Control

# Sinal emitido quando um item é selecionado
signal item_selected(item_data)

# Dicionário com todos os itens disponíveis no jogo, organizados por categoria
var available_items = {
	# Itens de cura - Restauram HP do jogador
	"healing": {
		"vela_abencoada": {
			"name": "Vela Abençoada",
			"quantity": 2,
			"type": "heal",
			"value": 30,
			"description": "Uma vela que emana energia curativa."
		},
		"agua_sagrada": {
			"name": "Água Sagrada",
			"quantity": 3,
			"type": "heal",
			"value": 20,
			"description": "Água abençoada que cura ferimentos."
		},
		"incenso_protetor": {
			"name": "Incenso Protetor",
			"quantity": 1,
			"type": "heal",
			"value": 50,
			"description": "Incenso que restaura completamente sua energia."
		}
	},
	# Itens de proteção - Enfraquecem o fantasma
	"protection": {
		"amuleto_protetor": {
			"name": "Amuleto Protetor",
			"quantity": 1,
			"type": "ghost_weaken",
			"value": 0,
			"description": "Reduz temporariamente o poder do fantasma."
		},
		"sal_abencoado": {
			"name": "Sal Abençoado",
			"quantity": 2,
			"type": "ghost_weaken",
			"value": 0,
			"description": "Cria uma barreira protetora contra ataques."
		},
		"cruz_antiga": {
			"name": "Cruz Antiga",
			"quantity": 1,
			"type": "ghost_weaken",
			"value": 0,
			"description": "Um símbolo sagrado que enfraquece espíritos malignos."
		}
	},
	# Itens de suporte - Aumentam a eficácia dos gifts
	"support": {
		"vela_espiritual": {
			"name": "Vela Espiritual",
			"quantity": 2,
			"type": "gift_boost",
			"value": 0,
			"description": "Aumenta a eficácia dos próximos gifts."
		},
		"essencia_espiritual": {
			"name": "Essência Espiritual",
			"quantity": 1,
			"type": "gift_boost",
			"value": 0,
			"description": "Fortalece sua conexão com o mundo espiritual."
		},
		"cristal_espiritual": {
			"name": "Cristal Espiritual",
			"quantity": 1,
			"type": "gift_boost",
			"value": 0,
			"description": "Amplifica o poder dos seus gifts."
		}
	}
}

# Referências aos elementos da interface
@onready var healing_list = $MainContainer/HealingList    # Lista de itens de cura
@onready var protection_list = $MainContainer/ProtectionList  # Lista de itens de proteção
@onready var support_list = $MainContainer/SupportList    # Lista de itens de suporte
@onready var description_label = $MainContainer/DescriptionLabel  # Label para descrição do item
@onready var close_button = $MainContainer/CloseButton    # Botão para fechar o inventário

func _ready():
	# Conecta o sinal do botão de fechar
	close_button.pressed.connect(_on_close_pressed)
	# Popula as listas com os itens disponíveis
	_populate_item_lists()

# Popula as listas de itens com os dados do dicionário
func _populate_item_lists():
	# Limpa as listas existentes
	for list in [healing_list, protection_list, support_list]:
		for child in list.get_children():
			child.queue_free()
	
	# Popula as listas com os itens
	for category in available_items:
		var list = get_node("MainContainer/" + category.capitalize() + "List")
		for item_id in available_items[category]:
			var item_data = available_items[category][item_id]
			var button = _create_item_button(item_data, category, item_id)
			list.add_child(button)

# Cria um botão para um item específico
func _create_item_button(item_data, category, item_id):
	var button = Button.new()
	# Mostra o nome do item e sua quantidade
	button.text = "%s (x%d)" % [item_data.name, item_data.quantity]
	button.custom_minimum_size = Vector2(200, 40)
	# Conecta o sinal de pressionar ao handler
	button.pressed.connect(_on_item_button_pressed.bind(category, item_id))
	return button

# Handler para quando um item é selecionado
func _on_item_button_pressed(category, item_id):
	var item_data = available_items[category][item_id]
	# Atualiza a descrição do item
	description_label.text = item_data.description
	# Emite o sinal de item selecionado
	emit_signal("item_selected", item_data)

# Handler para quando o botão de fechar é pressionado
func _on_close_pressed():
	queue_free()

# Mostra o menu do inventário
func show_menu():
	show()
	description_label.text = "Selecione um item para ver sua descrição."

# Atualiza a quantidade de um item específico
func update_item_quantity(category, item_id, new_quantity):
	if available_items.has(category) and available_items[category].has(item_id):
		available_items[category][item_id].quantity = new_quantity
		_populate_item_lists() 