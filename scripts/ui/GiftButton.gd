extends Button

@onready var name_label = $NameLabel
@onready var quantity_label = $QuantityLabel
@onready var description_label = $DescriptionLabel
@onready var effect_label = $EffectLabel

func setup(gift_data: Dictionary):
	name_label.text = gift_data.name
	quantity_label.text = "x" + str(gift_data.quantity)
	description_label.text = gift_data.description
	effect_label.text = "Efeito: " + gift_data.effect
	
	# Adiciona tooltip com informações detalhadas
	tooltip_text = "%s\nQuantidade: %d\n%s\nEfeito: %s" % [
		gift_data.name,
		gift_data.quantity,
		gift_data.description,
		gift_data.effect
	] 