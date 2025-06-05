extends Button

@onready var name_label = $NameLabel
@onready var quantity_label = $QuantityLabel
@onready var description_label = $DescriptionLabel

func setup(item_data: Dictionary):
	name_label.text = item_data.name
	quantity_label.text = "x" + str(item_data.quantity)
	description_label.text = item_data.description
	
	# Adiciona tooltip com informações detalhadas
	tooltip_text = "%s\nQuantidade: %d\n%s" % [
		item_data.name,
		item_data.quantity,
		item_data.description
	] 