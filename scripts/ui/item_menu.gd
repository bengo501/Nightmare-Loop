extends Control

signal item_selected(item_data)

var available_items = {
	"healing": {
		"potion": {"name": "Poção de Vida", "quantity": 3, "effect": "restore_hp", "value": 50, "description": "Restaura 50 pontos de vida"},
		"elixir": {"name": "Elixir de Cura", "quantity": 2, "effect": "restore_hp_mp", "value": 30, "description": "Restaura 30 pontos de vida e mana"},
		"balm": {"name": "Bálsamo Restaurador", "quantity": 1, "effect": "restore_all", "value": 100, "description": "Restaura completamente vida e mana"}
	},
	"status": {
		"antidote": {"name": "Antídoto", "quantity": 2, "effect": "cure_poison", "value": 0, "description": "Cura efeitos de veneno"},
		"perfume": {"name": "Perfume de Proteção", "quantity": 1, "effect": "boost_defense", "value": 20, "description": "Aumenta a defesa em 20 pontos"},
		"amulet": {"name": "Amuleto da Sorte", "quantity": 1, "effect": "boost_luck", "value": 15, "description": "Aumenta a sorte em 15 pontos"}
	},

}

@onready var healing_list = $MenuContainer/Categories/HealingItems/ItemList
@onready var status_list = $MenuContainer/Categories/StatusItems/ItemList

@onready var description_label = $MenuContainer/Description
@onready var close_button = $MenuContainer/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	_populate_item_lists()

func _populate_item_lists():
	# Limpa as listas existentes
	for child in healing_list.get_children():
		child.queue_free()
	for child in status_list.get_children():
		child.queue_free()

	
	# Adiciona itens de cura
	for item_id in available_items.healing:
		var item = available_items.healing[item_id]
		var button = _create_item_button(item, "healing", item_id)
		healing_list.add_child(button)
	
	# Adiciona itens de status
	for item_id in available_items.status:
		var item = available_items.status[item_id]
		var button = _create_item_button(item, "status", item_id)
		status_list.add_child(button)
	


func _create_item_button(item_data, category, item_id):
	var button = Button.new()
	button.text = "%s (x%d)" % [item_data.name, item_data.quantity]
	button.custom_minimum_size = Vector2(150, 30)
	button.disabled = item_data.quantity <= 0
	button.pressed.connect(_on_item_button_pressed.bind(category, item_id))
	return button

func _on_item_button_pressed(category, item_id):
	var item_data = available_items[category][item_id]
	description_label.text = "%s\n%s" % [item_data.name, item_data.description]
	emit_signal("item_selected", item_data)

func _on_close_pressed():
	queue_free()

func show_menu():
	show()
	description_label.text = "Selecione um item para ver sua descrição"
	_populate_item_lists()  # Atualiza as quantidades ao abrir o menu 