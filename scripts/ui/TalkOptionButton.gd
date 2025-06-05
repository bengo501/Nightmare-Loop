extends Button

@onready var text_label = $TextLabel
@onready var description_label = $DescriptionLabel

func setup(option_data: Dictionary):
	text_label.text = option_data.text
	description_label.text = option_data.description
	
	# Adiciona tooltip com a descrição
	tooltip_text = option_data.description 