extends Node

# Sinais para notificar sobre as ações do fantasma
signal ghost_attack(attack_data)
signal ghost_haunt(haunt_data)
signal ghost_scare(scare_data)

# Ataques disponíveis para o fantasma
var ghost_attacks = {
	"golpe_espiritual": {
		"name": "Golpe Espiritual",
		"damage": 15,
		"description": "Um golpe direto com energia espiritual."
	},
	"explosao_ectoplasmica": {
		"name": "Explosão Ectoplásmica",
		"damage": 25,
		"description": "Uma explosão de energia ectoplásmica."
	},
	"lancamento_espiritual": {
		"name": "Lançamento Espiritual",
		"damage": 20,
		"description": "Um projétil de energia espiritual."
	},
	"onda_do_abismo": {
		"name": "Onda do Abismo",
		"damage": 30,
		"description": "Uma onda de energia negativa do abismo."
	},
	"garras_espirituais": {
		"name": "Garras Espirituais",
		"damage": 18,
		"description": "Ataque com garras feitas de energia espiritual."
	}
}

# Opções de assombração
var haunt_options = {
	"roubar_xp": {
		"name": "Roubo de Experiência",
		"amount": 10,
		"description": "O fantasma rouba parte da sua experiência."
	},
	"roubar_consciencia": {
		"name": "Roubo de Consciência",
		"amount": 5,
		"description": "O fantasma rouba parte da sua consciência."
	},
	"roubar_luto": {
		"name": "Roubo de Luto",
		"amount": 2,
		"description": "O fantasma rouba parte da sua energia de luto."
	}
}

# Opções de susto
var scare_options = {
	"grito_aterrorizante": {
		"name": "Grito Aterrorizante",
		"effect": "reduz_defesa",
		"amount": 10,
		"description": "Um grito que reduz sua defesa."
	},
	"visao_do_abismo": {
		"name": "Visão do Abismo",
		"effect": "reduz_ataque",
		"amount": 10,
		"description": "Uma visão que reduz seu poder de ataque."
	},
	"presenca_do_mal": {
		"name": "Presença do Mal",
		"effect": "reduz_velocidade",
		"amount": 10,
		"description": "Uma presença que reduz sua velocidade."
	}
}

func execute_ghost_turn():
	# Escolhe aleatoriamente uma ação
	var action = randi() % 3  # 0: atacar, 1: assombrar, 2: assustar
	
	match action:
		0:
			execute_attack()
		1:
			execute_haunt()
		2:
			execute_scare()

func execute_attack():
	# Escolhe 3 ataques aleatórios
	var available_attacks = ghost_attacks.keys()
	available_attacks.shuffle()
	var selected_attacks = available_attacks.slice(0, 2)
	
	# Escolhe um dos 3 ataques aleatoriamente
	var chosen_attack = selected_attacks[randi() % 3]
	var attack_data = ghost_attacks[chosen_attack]
	
	print("Fantasma usou: ", attack_data.name)
	emit_signal("ghost_attack", attack_data)

func execute_haunt():
	# Escolhe uma opção de assombração aleatoriamente
	var haunt_keys = haunt_options.keys()
	var chosen_haunt = haunt_keys[randi() % haunt_keys.size()]
	var haunt_data = haunt_options[chosen_haunt]
	
	print("Fantasma usou: ", haunt_data.name)
	emit_signal("ghost_haunt", haunt_data)

func execute_scare():
	# Escolhe uma opção de susto aleatoriamente
	var scare_keys = scare_options.keys()
	var chosen_scare = scare_keys[randi() % scare_keys.size()]
	var scare_data = scare_options[chosen_scare]
	
	print("Fantasma usou: ", scare_data.name)
	emit_signal("ghost_scare", scare_data) 