extends CanvasLayer

# Sinal emitido quando a sequência de diálogos termina
signal dialog_sequence_finished

# Referências aos elementos da UI
@onready var character_portrait = $CharacterContainer/CharacterPortrait
@onready var dialog_box = $DialogContainer/DialogBox
@onready var speaker_name = $DialogContainer/DialogBox/DialogContent/SpeakerName
@onready var dialog_text = $DialogContainer/DialogBox/DialogContent/DialogText
@onready var continue_prompt = $DialogContainer/DialogBox/ContinuePrompt
@onready var continue_button = $ContinueButton
@onready var skip_button = $SkipButton
@onready var typewriter_timer = $TypewriterTimer
@onready var blink_timer = $BlinkTimer
@onready var ghost_animation_timer = $GhostAnimationTimer
@onready var mc_animation_timer = $MCAnimationTimer
@onready var william_animation_timer = $WilliamAnimationTimer

# Texturas dos personagens
var mc1_texture = preload("res://assets/textures/Mc1.png")
var mc2_texture = preload("res://assets/textures/Mc2.png")
var ghost_texture = preload("res://assets/textures/ghostFriend.png")
var ghost2_texture = preload("res://assets/textures/ghostFriend2.png")
var william_texture = preload("res://assets/textures/pirate_ghost_flipped2.png")
var william2_texture = preload("res://assets/textures/pirate_ghost_flipped.png")
var dialog_texture = preload("res://assets/textures/dialog.png")
var dialog_flipped_texture = preload("res://assets/textures/dialog_flipped.png")
var dialog2_texture = preload("res://assets/textures/dialog2.png")

# Estados do diálogo
var current_dialog_index = 0
var current_char_index = 0
var is_typing = false
var dialog_finished = false
var ghost_mouth_open = false
var mc_mouth_open = false
var william_mouth_open = false

# Variáveis para animação dos botões
var button_tween: Tween

# Script completo de diálogos
var dialogs = [
	# Protagonista acordando
	{
		"speaker": "Protagonista",
		"text": "Hã...? O... meu quarto...?",
		"character": "mc1",
		"mouth_animation": true
	},
	{
		"speaker": "Protagonista", 
		"text": "Espera... isso tá... diferente...",
		"character": "mc2",
		"mouth_animation": true
	},
	{
		"speaker": "Protagonista",
		"text": "Não... não pode ser... não de novo...",
		"character": "mc1",
		"mouth_animation": true
	},
	{
		"speaker": "Protagonista",
		"text": "Essas noites... têm sido horríveis...",
		"character": "mc2",
		"mouth_animation": true
	},
	{
		"speaker": "Protagonista",
		"text": "Sonhando... sempre com o Gustavo... sempre...",
		"character": "mc1",
		"mouth_animation": true
	},
	{
		"speaker": "Protagonista",
		"text": "E... cada vez... sinto que... que algo ruim... tá chegando mais perto.",
		"character": "mc2",
		"mouth_animation": true
	},
	{
		"speaker": "Protagonista",
		"text": "Esse quarto... eu... eu já sonhei com ele antes... não é meu quarto... mas... é...?",
		"character": "mc1",
		"mouth_animation": true
	},
	{
		"speaker": "Protagonista",
		"text": "Cadê... a porta...?",
		"character": "mc2",
		"mouth_animation": true
	},
	{
		"speaker": "Protagonista",
		"text": "Ela... sumiu... não tá mais aqui...",
		"character": "mc1",
		"mouth_animation": true
	},
	{
		"speaker": "Protagonista",
		"text": "Mas... eu não tô mais dormindo... não é um sonho... isso tá... acontecendo mesmo...",
		"character": "mc2",
		"mouth_animation": true
	},
	
	# Gregor entra
	{
		"speaker": "Gregor",
		"text": "Opa, opa! Calma aí, sem pânico, tá?",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Respira, garota... eu sei que tá confuso, mas eu posso explicar.",
		"character": "ghost",
		"mouth_animation": false
	},
	
	# Protagonista assustada
	{
		"speaker": "Protagonista",
		"text": "Q-Quem... quem é você...?",
		"character": "mc1",
		"mouth_animation": true
	},
	{
		"speaker": "Protagonista",
		"text": "O que... o que tá acontecendo aqui...?",
		"character": "mc2",
		"mouth_animation": true
	},
	
	# Gregor se apresenta
	{
		"speaker": "Gregor",
		"text": "Meu nome é Gregor! Eu sou... digamos... um fantasma do bem.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "E... bom... você... você se meteu numa encrenca bem feia.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Sabe aquele site que você entrou...?",
		"character": "ghost",
		"mouth_animation": false
	},
	
	# Protagonista sobre o site
	{
		"speaker": "Protagonista",
		"text": "O site...?",
		"character": "mc1",
		"mouth_animation": true
	},
	
	# Gregor explica o site
	{
		"speaker": "Gregor",
		"text": "Aquele... que dizia que dava pra conversar com alguém que... já se foi.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Era pra ser... só uma forma de ajudar pessoas no luto... uma última conversa... um último adeus.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "MAS... você acessou esse site... vezes demais.",
		"character": "ghost",
		"mouth_animation": false
	},
	
	# Protagonista se justifica
	{
		"speaker": "Protagonista",
		"text": "Eu... eu só... eu só queria... falar com ele de novo...",
		"character": "mc2",
		"mouth_animation": true
	},
	
	# Gregor explica a maldição
	{
		"speaker": "Gregor",
		"text": "Eu sei... eu sei... mas... sem querer... você ativou uma maldição.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Agora... você tá presa... nesse ciclo.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Um ciclo de pesadelos... um loop.",
		"character": "ghost",
		"mouth_animation": false
	},
	
	# Protagonista pergunta sobre o loop
	{
		"speaker": "Protagonista",
		"text": "C-Como assim... loop...?",
		"character": "mc1",
		"mouth_animation": true
	},
	
	# Gregor explica os estágios
	{
		"speaker": "Gregor",
		"text": "Você vai precisar enfrentar... os cinco estágios do luto.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Cada estágio... virou um lugar... uma fase desse pesadelo.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "E dentro de cada fase... existem fantasmas... monstros... representando esses sentimentos.",
		"character": "ghost",
		"mouth_animation": false
	},
	
	# Protagonista assustada
	{
		"speaker": "Protagonista",
		"text": "Não... não... isso não pode estar acontecendo...",
		"character": "mc2",
		"mouth_animation": true
	},
	
	# Gregor oferece ajuda
	{
		"speaker": "Gregor",
		"text": "Olha... eu sei que parece assustador, mas... você não tá sozinha.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Eu vou te ajudar.",
		"character": "ghost",
		"mouth_animation": false
	},
	
	# Gregor explica a arma
	{
		"speaker": "Gregor",
		"text": "Aqui... essa é sua arma.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Ela dispara... raios.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Mas não qualquer raio... são raios de cores diferentes.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Cada tipo de fantasma... é vulnerável a uma cor específica.",
		"character": "ghost",
		"mouth_animation": false
	},
	
	# Gregor explica os presentes
	{
		"speaker": "Gregor",
		"text": "Além disso... você vai encontrar... Presentes de Luto.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Eles são... objetos simbólicos.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Você pode usar eles pra negociar... ou até pra enfraquecer certos fantasmas.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Nem sempre a luta é o melhor caminho... às vezes... eles só querem algo.",
		"character": "ghost",
		"mouth_animation": false
	},
	
	# Gregor explica pontos de lucidez
	{
		"speaker": "Gregor",
		"text": "E tem mais... cada vez que você falhar... cada vez que morrer nesse sonho...",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Você volta... aqui... pro começo.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "MAS... você volta mais forte.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Você ganha... Pontos de Lucidez.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Com eles... você pode melhorar suas habilidades... ficar mais rápida, mais resistente... enxergar melhor esse mundo distorcido.",
		"character": "ghost",
		"mouth_animation": false
	},
	
	# Protagonista confirma situação
	{
		"speaker": "Protagonista",
		"text": "Então... eu tô... presa aqui... até... até vencer isso...?",
		"character": "mc1",
		"mouth_animation": true
	},
	
	# Gregor confirma e explica
	{
		"speaker": "Gregor",
		"text": "Isso aí... até quebrar o ciclo.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Você vai precisar enfrentar cada fase... entender... aceitar... e superar.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "E olha... quando você dormir de novo... o loop recomeça.",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "Mas você... vai tá mais preparada.",
		"character": "ghost",
		"mouth_animation": false
	},
	
	# Gregor mostra a cama
	{
		"speaker": "Gregor",
		"text": "Quando estiver pronta... é só deitar ali...",
		"character": "ghost",
		"mouth_animation": false
	},
	{
		"speaker": "Gregor",
		"text": "E... começar de novo.",
		"character": "ghost",
		"mouth_animation": false
	},
	
	# Protagonista aceita o desafio
	{
		"speaker": "Protagonista",
		"text": "Certo... eu... eu vou fazer isso.",
		"character": "mc2",
		"mouth_animation": true
	},
	{
		"speaker": "Protagonista",
		"text": "Eu vou sair desse pesadelo.",
		"character": "mc1",
		"mouth_animation": true
	}
]

# Diálogos específicos para a TV (William)
var tv_dialogs = [
	{
		"speaker": "William",
		"text": "Ahooy! Finalmente alguém com olhos e juízo pra escutar um velho marujo preso neste caixote brilhante.",
		"character": "william",
		"mouth_animation": false
	},
	{
		"speaker": "Protagonista",
		"text": "U-um fantasma… na televisão?! O que... o que é isso?",
		"character": "mc1",
		"mouth_animation": true
	},
	{
		"speaker": "William",
		"text": "Ahn-hahn! O próprio! William Dente-de-Sombra, astro de sete mares… e de uns bons filmes de pirata nos anos 80. Agora, mentor de sonhadores perdidos como tu.",
		"character": "william",
		"mouth_animation": false
	},
	{
		"speaker": "Protagonista",
		"text": "Mentor? Do quê exatamente?",
		"character": "mc2",
		"mouth_animation": true
	},
	{
		"speaker": "William",
		"text": "Deste mundo, menina. Este ciclo maldito que te arrastou – o Loop. Aqui, a realidade se dobra, o tempo se engasga, e tu... tu vais precisar ser mais forte se quiser sair viva.",
		"character": "william",
		"mouth_animation": false
	},
	{
		"speaker": "Protagonista",
		"text": "E como eu faço isso?",
		"character": "mc1",
		"mouth_animation": true
	},
	{
		"speaker": "William",
		"text": "Toc, toc! Através desta engenhoca! Nesta TV mágica, podemos aprimorar tuas habilidades. Mas nada é de graça... vais precisar dos Pontos de Consciência.",
		"character": "william",
		"mouth_animation": false
	},
	{
		"speaker": "Protagonista",
		"text": "Pontos de... Consciência?",
		"character": "mc2",
		"mouth_animation": true
	},
	{
		"speaker": "William",
		"text": "Sim! Fragmentos da tua mente desperta. Encontrados espalhados pelas fases do Loop. Cada pedacinho te deixa mais lúcida, mais rápida, mais... letal!",
		"character": "william",
		"mouth_animation": false
	},
	{
		"speaker": "Protagonista",
		"text": "Então eu coleto esses pontos e volto aqui?",
		"character": "mc1",
		"mouth_animation": true
	},
	{
		"speaker": "William",
		"text": "Exato como uma bússola que retorna ao norte! Entregue-os a mim e, com minha sabedoria de pirata místico, destravaremos poderes, habilidades e resistência pra aguentar os terrores que te esperam.",
		"character": "william",
		"mouth_animation": false
	},
	{
		"speaker": "Protagonista",
		"text": "E se eu morrer?",
		"character": "mc2",
		"mouth_animation": true
	},
	{
		"speaker": "William",
		"text": "Arrrr! Tu vais acordar de novo, menina... neste mesmo pesadelo. Mas cada ponto guardado aqui permanece! A cada nova tentativa, estarás mais forte. Mais próxima da verdade.",
		"character": "william",
		"mouth_animation": false
	},
	{
		"speaker": "Protagonista",
		"text": "Tá... isso é meio insano. Mas se isso me ajuda a sair daqui... vou fazer funcionar.",
		"character": "mc1",
		"mouth_animation": true
	},
	{
		"speaker": "William",
		"text": "Sabes aprender rápido! Agora vá, brava navegante do pesadelo. E não esqueça: a luz da consciência é tua arma contra a escuridão.",
		"character": "william",
		"mouth_animation": false
	}
]

func _ready():
	# Conecta os timers
	print("[DialogSystem] Conectando timers...")
	typewriter_timer.timeout.connect(_on_typewriter_timer_timeout)
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	ghost_animation_timer.timeout.connect(_on_ghost_animation_timer_timeout)
	mc_animation_timer.timeout.connect(_on_mc_animation_timer_timeout)
	william_animation_timer.timeout.connect(_on_william_animation_timer_timeout)
	print("[DialogSystem] Timers conectados com sucesso")
	
	# Conecta os botões
	if continue_button:
		continue_button.pressed.connect(_on_continue_button_pressed)
	if skip_button:
		skip_button.pressed.connect(_on_skip_button_pressed)
	print("[DialogSystem] Botões conectados com sucesso")
	
	# Verifica se as texturas foram carregadas
	if not ghost_texture or not ghost2_texture or not mc1_texture or not mc2_texture or not william_texture or not william2_texture:
		print("[DialogSystem] ERRO: Algumas texturas não foram carregadas!")
	else:
		print("[DialogSystem] Todas as texturas carregadas com sucesso")
	
	# Configura o sistema para não ser pausado quando o jogo for pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("[DialogSystem] Sistema de diálogos inicializado e pronto")

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select") or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER) or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		
		if is_typing:
			# Se estiver digitando, completa o texto imediatamente
			complete_text()
		else:
			# Se o texto está completo, avança para o próximo diálogo
			next_dialog()

func show_dialog(index: int):
	print("[DialogSystem] show_dialog() chamada com index: ", index)
	print("[DialogSystem] dialogs.size(): ", dialogs.size())
	
	if index >= dialogs.size():
		print("[DialogSystem] Index maior que tamanho do array, finalizando")
		finish_dialog_sequence()
		return
	
	current_dialog_index = index
	var dialog_data = dialogs[index]
	
	print("[DialogSystem] Diálogo atual - Speaker: ", dialog_data.speaker, " Character: ", dialog_data.character)
	
	# Define o nome do falante
	if speaker_name and is_instance_valid(speaker_name):
		speaker_name.text = dialog_data.speaker
	else:
		print("[DialogSystem] ERRO: speaker_name é null!")
	
	# Define o retrato do personagem
	set_character_portrait(dialog_data.character)
	
	# Inicia o efeito typewriter
	start_typewriter(dialog_data.text)

func set_character_portrait(character: String):
	# Para todos os timers de animação antes de configurar novo personagem
	ghost_animation_timer.stop()
	mc_animation_timer.stop()
	william_animation_timer.stop()
	ghost_mouth_open = false
	mc_mouth_open = false
	william_mouth_open = false
	
	print("[DialogSystem] Configurando personagem: ", character)
	
	# Configuração padrão para todos os personagens: esquerda da tela, balão apontando para direita
	character_portrait.anchors_preset = Control.PRESET_CENTER_LEFT
	character_portrait.offset_left = 50.0
	character_portrait.offset_right = 450.0
	character_portrait.offset_top = -200.0
	character_portrait.offset_bottom = 200.0
	character_portrait.custom_minimum_size = Vector2(400, 400)
	# Usa sempre o balão dialog2 (apontando para direita)
	if dialog_box and is_instance_valid(dialog_box) and dialog2_texture:
		dialog_box.texture = dialog2_texture
	else:
		print("[DialogSystem] ERRO: dialog_box ou dialog2_texture é null!")
	
	match character:
		"mc1":
			character_portrait.texture = mc1_texture
			# Inicia animação da boca da protagonista
			mc_animation_timer.start()
			print("[DialogSystem] Protagonista MC1 configurada")
		"mc2": 
			character_portrait.texture = mc2_texture
			# Inicia animação da boca da protagonista
			mc_animation_timer.start()
			print("[DialogSystem] Protagonista MC2 configurada")
		"ghost":
			character_portrait.texture = ghost_texture
			# Inicia animação da boca do ghost
			ghost_animation_timer.start()
			print("[DialogSystem] Ghost configurado - texture: ", ghost_texture)
		"william":
			character_portrait.texture = william_texture
			# Inicia animação da boca do William
			william_animation_timer.start()
			print("[DialogSystem] William configurado - texture: ", william_texture)

func start_typewriter(text: String):
	print("[DialogSystem] Iniciando typewriter para: ", text.substr(0, 30), "...")
	
	is_typing = true
	current_char_index = 0
	if dialog_text and is_instance_valid(dialog_text):
		dialog_text.text = ""
	else:
		print("[DialogSystem] ERRO: dialog_text é null no start_typewriter!")
	
	# Mostra os botões sempre durante o diálogo
	if continue_button and is_instance_valid(continue_button):
		continue_button.visible = true
	if skip_button and is_instance_valid(skip_button):
		skip_button.visible = true
	animate_buttons()
	
	if continue_prompt and is_instance_valid(continue_prompt):
		continue_prompt.visible = false
	
	# Inicia o timer do typewriter
	typewriter_timer.start()
	print("[DialogSystem] Timer do typewriter iniciado")

func _on_typewriter_timer_timeout():
	if current_dialog_index >= dialogs.size():
		print("[DialogSystem] ERRO: current_dialog_index fora do range!")
		return
	
	var dialog_data = dialogs[current_dialog_index]
	var full_text = dialog_data.text
	
	if current_char_index < full_text.length():
		# Adiciona o próximo caractere
		current_char_index += 1
		if dialog_text and is_instance_valid(dialog_text):
			dialog_text.text = full_text.substr(0, current_char_index)
		
		# Animação da boca para protagonista
		if dialog_data.has("mouth_animation") and dialog_data.mouth_animation:
			animate_mouth()
	else:
		# Texto completo
		complete_text()

func animate_mouth():
	# Alterna entre Mc1 e Mc2 para simular movimento da boca
	var dialog_data = dialogs[current_dialog_index]
	if dialog_data.character == "mc1":
		character_portrait.texture = mc2_texture
	elif dialog_data.character == "mc2":
		character_portrait.texture = mc1_texture

func complete_text():
	is_typing = false
	typewriter_timer.stop()
	
	# Para a animação do ghost
	if dialogs[current_dialog_index].character == "ghost":
		ghost_animation_timer.stop()
		character_portrait.texture = ghost_texture  # Retorna à textura padrão
		ghost_mouth_open = false
	
	# Para a animação da protagonista
	if dialogs[current_dialog_index].character == "mc1" or dialogs[current_dialog_index].character == "mc2":
		mc_animation_timer.stop()
		character_portrait.texture = mc1_texture  # Retorna à textura padrão (boca fechada)
		mc_mouth_open = false
	
	# Para a animação do William
	if dialogs[current_dialog_index].character == "william":
		william_animation_timer.stop()
		character_portrait.texture = william_texture  # Retorna à textura padrão (boca fechada)
		william_mouth_open = false
	
	# Mostra o texto completo
	if dialog_text and is_instance_valid(dialog_text):
		dialog_text.text = dialogs[current_dialog_index].text
	else:
		print("[DialogSystem] ERRO: dialog_text é null!")
	
	# Os botões já estão visíveis, apenas garante que continuem animados
	if continue_prompt and is_instance_valid(continue_prompt):
		continue_prompt.visible = false  # Mantém o prompt de texto escondido

func next_dialog():
	current_dialog_index += 1
	show_dialog(current_dialog_index)

func _on_continue_button_pressed():
	if is_typing:
		# Se estiver digitando, completa o texto imediatamente
		complete_text()
	else:
		# Se o texto está completo, avança para o próximo diálogo
		next_dialog()

func _on_skip_button_pressed():
	# Pula toda a sequência de diálogos
	finish_dialog_sequence()

func animate_buttons():
	if button_tween:
		button_tween.kill()
	
	button_tween = create_tween()
	button_tween.set_loops()
	button_tween.set_parallel(true)
	
	# Anima o botão de continuar
	if continue_button and is_instance_valid(continue_button):
		button_tween.tween_property(continue_button, "modulate:a", 0.7, 0.8)
		button_tween.tween_property(continue_button, "modulate:a", 1.0, 0.8)
	
	# Anima o botão de pular
	if skip_button and is_instance_valid(skip_button):
		button_tween.tween_property(skip_button, "modulate:a", 0.7, 0.8)
		button_tween.tween_property(skip_button, "modulate:a", 1.0, 0.8)

func initialize_buttons():
	# Garante que os botões estão visíveis e animados desde o início
	if continue_button and is_instance_valid(continue_button):
		continue_button.visible = true
	if skip_button and is_instance_valid(skip_button):
		skip_button.visible = true
	animate_buttons()

# Função para iniciar os diálogos padrão (Gregor)
func start_default_dialog():
	current_dialog_index = 0
	initialize_buttons()
	show_dialog(0)
	print("[DialogSystem] Iniciando diálogos padrão")

# Função para iniciar os diálogos da TV (William)
func start_tv_dialog():
	print("[DialogSystem] start_tv_dialog() chamada")
	print("[DialogSystem] tv_dialogs.size(): ", tv_dialogs.size())
	
	# Substitui os diálogos pelos diálogos da TV
	dialogs = tv_dialogs
	current_dialog_index = 0
	
	initialize_buttons()
	print("[DialogSystem] Dialogs substituídos, chamando show_dialog(0)")
	show_dialog(0)
	print("[DialogSystem] Iniciando diálogos da TV com William")

func _on_blink_timer_timeout():
	# Faz o prompt piscar
	if continue_prompt.visible and not is_typing:
		continue_prompt.modulate.a = 1.0 if continue_prompt.modulate.a < 0.5 else 0.3

func _on_ghost_animation_timer_timeout():
	# Alterna entre as texturas do ghost para simular fala
	var dialog_data = dialogs[current_dialog_index]
	if dialog_data.character == "ghost":
		if ghost_mouth_open:
			character_portrait.texture = ghost_texture
			ghost_mouth_open = false
		else:
			character_portrait.texture = ghost2_texture
			ghost_mouth_open = true

func _on_mc_animation_timer_timeout():
	# Alterna entre as texturas da protagonista para simular fala
	var dialog_data = dialogs[current_dialog_index]
	if dialog_data.character == "mc1" or dialog_data.character == "mc2":
		if mc_mouth_open:
			character_portrait.texture = mc1_texture
			mc_mouth_open = false
		else:
			character_portrait.texture = mc2_texture
			mc_mouth_open = true

func _on_william_animation_timer_timeout():
	# Alterna entre as texturas do William para simular fala
	if current_dialog_index < dialogs.size():
		var dialog_data = dialogs[current_dialog_index]
		if dialog_data.character == "william":
			if william_mouth_open:
				character_portrait.texture = william_texture
				william_mouth_open = false
			else:
				character_portrait.texture = william2_texture
				william_mouth_open = true

func finish_dialog_sequence():
	print("[DialogSystem] Sequência de diálogos finalizada")
	
	# Para todos os timers
	ghost_animation_timer.stop()
	mc_animation_timer.stop()
	william_animation_timer.stop()
	typewriter_timer.stop()
	blink_timer.stop()
	
	# Para a animação dos botões
	if button_tween:
		button_tween.kill()
	
	# Fade out
	var fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.z_index = 100
	add_child(fade_overlay)
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 1.0)
	
	await tween.finished
	
	# Emite o sinal de fim do diálogo
	dialog_sequence_finished.emit()
	
	# Remove o sistema de diálogos e permite que o jogo continue normalmente
	queue_free() 
