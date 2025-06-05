extends Button

@onready var name_label = $NameLabel
@onready var mp_cost_label = $MPCostLabel
@onready var description_label = $DescriptionLabel

func setup(skill_data: Dictionary):
	name_label.text = skill_data.name
	mp_cost_label.text = "MP: " + str(skill_data.mp_cost)
	description_label.text = skill_data.description
	
	# Adiciona tooltip com informações detalhadas
	tooltip_text = "%s\nCusto: %d MP\n%s" % [
		skill_data.name,
		skill_data.mp_cost,
		skill_data.description
	] 