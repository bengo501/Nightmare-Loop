extends Node

# Sinais para comunicação entre os componentes do sistema de batalha
signal player_turn_started  # Emitido quando o turno do jogador começa
signal ghost_turn_started   # Emitido quando o turno do fantasma começa
signal battle_ended(victory) # Emitido quando a batalha termina (true = vitória, false = derrota)
signal ghost_sequence_updated(sequence) # Emitido quando a sequência de cores do fantasma é atualizada
signal ghost_stunned(turns) # Emitido quando o fantasma é atordoado

@onready var ghost_actions = $GhostActions

# Variável que controla de quem é o turno atual
var is_player_turn = true

# Estatísticas do jogador
var player_stats = {
	"hp": 100,          # Pontos de vida atuais
	"max_hp": 100,      # Pontos de vida máximos
	"mp": 50,           # Pontos de magia atuais
	"max_mp": 50,       # Pontos de magia máximos
	"xp": 0,            # Pontos de experiência
	"consciencia": 100, # Nível de consciência (afeta a eficácia de certas ações)
	"defesa": 10,       # Reduz o dano recebido
	"ataque": 15,       # Aumenta o dano causado
	"velocidade": 10    # Afeta a ordem dos turnos
}

# Estatísticas do fantasma
var ghost_stats = {
	"hp": 150,              # Pontos de vida atuais
	"max_hp": 150,          # Pontos de vida máximos
	"defesa": 8,            # Reduz o dano recebido
	"ataque": 12,           # Aumenta o dano causado
	"velocidade": 12,       # Afeta a ordem dos turnos
	"stunned": 0,           # Número de turnos que o fantasma está atordoado
	"power_multiplier": 1.0 # Multiplicador de poder (aumenta com gifts errados)
}

# Sequência de cores que o fantasma precisa receber para ser derrotado
var ghost_color_sequence = []
var current_color_index = 0

# Cores associadas a cada estágio do luto
var grief_colors = {
	"negacao": Color(0.8, 0.8, 0.8),  # Cinza claro
	"raiva": Color(0.8, 0.2, 0.2),    # Vermelho
	"barganha": Color(0.8, 0.6, 0.2), # Laranja
	"depressao": Color(0.2, 0.2, 0.8), # Azul
	"aceitacao": Color(0.2, 0.8, 0.2)  # Verde
}

# Quantidade disponível de cada estágio do luto
var grief_quantities = {
	"negacao": 3,
	"raiva": 2,
	"barganha": 4,
	"depressao": 1,
	"aceitacao": 5
}

func _ready():
	# Conecta os sinais do fantasma para gerenciar suas ações
	ghost_actions.ghost_attack.connect(_on_ghost_attack)
	ghost_actions.ghost_haunt.connect(_on_ghost_haunt)
	ghost_actions.ghost_scare.connect(_on_ghost_scare)
	
	# Gera a sequência inicial de cores que o fantasma precisa receber
	generate_ghost_sequence()
	
	# Inicia o primeiro turno (sempre começa com o jogador)
	start_player_turn()

# Gera uma sequência aleatória de 3 cores que o fantasma precisa receber
func generate_ghost_sequence():
	ghost_color_sequence.clear()
	var colors = grief_colors.keys()
	colors.shuffle()
	
	# Seleciona 3 cores aleatórias para a sequência
	for i in range(3):
		ghost_color_sequence.append(colors[i])
	
	emit_signal("ghost_sequence_updated", ghost_color_sequence)

# Inicia o turno do jogador
func start_player_turn():
	is_player_turn = true
	print("Turno do jogador iniciado")
	emit_signal("player_turn_started")

# Finaliza o turno do jogador e inicia o turno do fantasma
func end_player_turn():
	is_player_turn = false
	print("Turno do jogador finalizado")
	start_ghost_turn()

# Inicia o turno do fantasma
func start_ghost_turn():
	print("Turno do fantasma iniciado")
	emit_signal("ghost_turn_started")
	
	# Verifica se o fantasma está atordoado
	if ghost_stats.stunned > 0:
		ghost_stats.stunned -= 1
		print("Fantasma está atordoado! Pulando turno...")
		end_ghost_turn()
		return
	
	# Executa a ação do fantasma
	ghost_actions.execute_ghost_turn()

# Finaliza o turno do fantasma e volta para o turno do jogador
func end_ghost_turn():
	print("Turno do fantasma finalizado")
	start_player_turn()

# Processa o ataque do fantasma
func _on_ghost_attack(attack_data):
	print("Fantasma atacou com ", attack_data.name)
	# Calcula o dano considerando a defesa do jogador e o multiplicador de poder do fantasma
	var damage = attack_data.damage * ghost_stats.power_multiplier - player_stats.defesa
	if damage < 0:
		damage = 1  # Garante um dano mínimo
	
	player_stats.hp -= damage
	print("Jogador recebeu ", damage, " de dano")
	
	# Verifica se o jogador foi derrotado
	if player_stats.hp <= 0:
		player_stats.hp = 0
		print("Jogador derrotado!")
		emit_signal("battle_ended", false)
		return
	
	end_ghost_turn()

# Processa a assombração do fantasma
func _on_ghost_haunt(haunt_data):
	print("Fantasma usou ", haunt_data.name)
	
	match haunt_data.name:
		"Roubo de Experiência":
			player_stats.xp -= haunt_data.amount
			if player_stats.xp < 0:
				player_stats.xp = 0
			print("Jogador perdeu ", haunt_data.amount, " de XP")
		
		"Roubo de Consciência":
			player_stats.consciencia -= haunt_data.amount
			if player_stats.consciencia < 0:
				player_stats.consciencia = 0
			print("Jogador perdeu ", haunt_data.amount, " de consciência")
		
		"Roubo de Luto":
			# Rouba um estágio do luto aleatório
			var stages = grief_quantities.keys()
			stages.shuffle()
			for stage in stages:
				if grief_quantities[stage] > 0:
					grief_quantities[stage] -= 1
					print("Jogador perdeu 1 ponto de ", stage)
					break
	
	end_ghost_turn()

# Processa o susto do fantasma
func _on_ghost_scare(scare_data):
	print("Fantasma usou ", scare_data.name)
	
	match scare_data.effect:
		"reduz_defesa":
			player_stats.defesa -= scare_data.amount
			if player_stats.defesa < 0:
				player_stats.defesa = 0
			print("Defesa do jogador reduzida em ", scare_data.amount)
		
		"reduz_ataque":
			player_stats.ataque -= scare_data.amount
			if player_stats.ataque < 0:
				player_stats.ataque = 0
			print("Ataque do jogador reduzido em ", scare_data.amount)
		
		"reduz_velocidade":
			player_stats.velocidade -= scare_data.amount
			if player_stats.velocidade < 0:
				player_stats.velocidade = 0
			print("Velocidade do jogador reduzida em ", scare_data.amount)
	
	end_ghost_turn()

# Processa o uso de habilidade pelo jogador
func player_use_skill(skill_data):
	if not is_player_turn:
		return
	
	print("Jogador usou ", skill_data.name)
	
	# Verifica se tem MP suficiente
	if player_stats.mp < skill_data.mp_cost:
		print("MP insuficiente!")
		return
	
	# Deduz o custo de MP
	player_stats.mp -= skill_data.mp_cost
	
	match skill_data.type:
		"attack":
			# Aplica o dano ao fantasma
			var damage = skill_data.power - ghost_stats.defesa
			if damage < 0:
				damage = 1  # Dano mínimo
			
			ghost_stats.hp -= damage
			print("Fantasma recebeu ", damage, " de dano")
			
			# Aumenta o poder dos outros fantasmas
			ghost_stats.power_multiplier += 0.2
			print("Poder do fantasma aumentou para ", ghost_stats.power_multiplier)
		
		"stun":
			# Atordoa o fantasma
			ghost_stats.stunned = 1
			emit_signal("ghost_stunned", 1)
			print("Fantasma atordoado por 1 turno!")
		
		"gift_boost":
			# Aumenta a eficácia dos próximos gifts
			print("Eficácia dos gifts aumentada!")
	
	# Verifica se o fantasma foi derrotado
	if ghost_stats.hp <= 0:
		ghost_stats.hp = 0
		print("Fantasma derrotado!")
		emit_signal("battle_ended", true)
		return
	
	end_player_turn()

# Processa o uso de item pelo jogador
func player_use_item(item_data):
	if not is_player_turn:
		return
	
	print("Jogador usou ", item_data.name)
	
	# Aplica o efeito do item
	match item_data.type:
		"heal":
			player_stats.hp += item_data.value
			if player_stats.hp > player_stats.max_hp:
				player_stats.hp = player_stats.max_hp
			print("Jogador recuperou ", item_data.value, " de HP")
		
		"mp_restore":
			player_stats.mp += item_data.value
			if player_stats.mp > player_stats.max_mp:
				player_stats.mp = player_stats.max_mp
			print("Jogador recuperou ", item_data.value, " de MP")
		
		"gift_boost":
			# Aumenta a eficácia dos próximos gifts
			print("Eficácia dos gifts aumentada!")
		
		"ghost_weaken":
			# Reduz o poder do fantasma
			ghost_stats.power_multiplier = max(1.0, ghost_stats.power_multiplier - 0.1)
			print("Poder do fantasma reduzido para ", ghost_stats.power_multiplier)
	
	end_player_turn()

# Processa o uso de gift pelo jogador
func player_use_gift(gift_type):
	if not is_player_turn:
		return
	
	if grief_quantities[gift_type] <= 0:
		print("Não há mais gifts deste tipo disponível!")
		return
	
	print("Jogador usou gift: ", gift_type)
	
	# Verifica se é a cor correta na sequência
	if gift_type == ghost_color_sequence[current_color_index]:
		print("Gift correto! Avançando na sequência...")
		current_color_index += 1
		
		# Verifica se completou a sequência
		if current_color_index >= ghost_color_sequence.size():
			print("Sequência completa! Fantasma derrotado!")
			emit_signal("battle_ended", true)
			return
	else:
		print("Gift incorreto! Fantasma ficou mais forte!")
		ghost_stats.power_multiplier += 0.3
	
	# Deduz o gift usado
	grief_quantities[gift_type] -= 1
	
	# Implementar lógica de efeito do gift
	match gift_type:
		"negacao":
			ghost_stats.hp -= 10
		"raiva":
			ghost_stats.hp -= 15
		"barganha":
			ghost_stats.hp -= 20
		"depressao":
			ghost_stats.hp -= 25
		"aceitacao":
			ghost_stats.hp -= 30
	
	if ghost_stats.hp <= 0:
		ghost_stats.hp = 0
		print("Fantasma derrotado!")
		emit_signal("battle_ended", true)
		return
	
	end_player_turn()

# Processa a tentativa de fuga do jogador
func player_flee():
	if not is_player_turn:
		return
	
	print("Jogador tentou fugir")
	
	# 50% de chance de fugir com sucesso
	if randf() < 0.5:
		print("Fuga bem-sucedida!")
		emit_signal("battle_ended", false)
	else:
		print("Fuga falhou!")
		end_player_turn()

# Função para passar o turno
func next_turn():
	if not is_player_turn:
		return
	
	end_player_turn() 