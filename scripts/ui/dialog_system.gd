extends CanvasLayer

# Referências aos elementos da UI
@onready var character_portrait = $CharacterContainer/CharacterPortrait
@onready var speaker_name = $DialogContainer/DialogBox/DialogContent/SpeakerName
@onready var dialog_text = $DialogContainer/DialogBox/DialogContent/DialogText
@onready var continue_prompt = $DialogContainer/DialogBox/ContinuePrompt
@onready var typewriter_timer = $TypewriterTimer
@onready var blink_timer = $BlinkTimer

# Texturas dos personagens
var mc1_texture = preload("res://assets/textures/Mc1.png")
var mc2_texture = preload("res://assets/textures/Mc2.png")
var ghost_texture = preload("res://assets/textures/ghostFriend.png")

# Estados do diálogo
var current_dialog_index = 0
var current_char_index = 0
var is_typing = false
var dialog_finished = false

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

func _ready():
	# Conecta os timers
	typewriter_timer.timeout.connect(_on_typewriter_timer_timeout)
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	
	# Inicia o primeiro diálogo
	show_dialog(0)
	
	print("[DialogSystem] Sistema de diálogos iniciado")

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
	if index >= dialogs.size():
		finish_dialog_sequence()
		return
	
	current_dialog_index = index
	var dialog_data = dialogs[index]
	
	# Define o nome do falante
	speaker_name.text = dialog_data.speaker
	
	# Define o retrato do personagem
	set_character_portrait(dialog_data.character)
	
	# Inicia o efeito typewriter
	start_typewriter(dialog_data.text)

func set_character_portrait(character: String):
	match character:
		"mc1":
			character_portrait.texture = mc1_texture
		"mc2": 
			character_portrait.texture = mc2_texture
		"ghost":
			character_portrait.texture = ghost_texture

func start_typewriter(text: String):
	is_typing = true
	current_char_index = 0
	dialog_text.text = ""
	if continue_prompt and is_instance_valid(continue_prompt):
		continue_prompt.visible = false
	
	# Inicia o timer do typewriter
	typewriter_timer.start()

func _on_typewriter_timer_timeout():
	var dialog_data = dialogs[current_dialog_index]
	var full_text = dialog_data.text
	
	if current_char_index < full_text.length():
		# Adiciona o próximo caractere
		current_char_index += 1
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
	
	# Mostra o texto completo
	dialog_text.text = dialogs[current_dialog_index].text
	
	# Restaura o retrato correto
	set_character_portrait(dialogs[current_dialog_index].character)
	
	# Mostra o prompt para continuar
	if continue_prompt and is_instance_valid(continue_prompt):
		continue_prompt.visible = true

func next_dialog():
	current_dialog_index += 1
	show_dialog(current_dialog_index)

func _on_blink_timer_timeout():
	# Faz o prompt piscar
	if continue_prompt.visible and not is_typing:
		continue_prompt.modulate.a = 1.0 if continue_prompt.modulate.a < 0.5 else 0.3

func finish_dialog_sequence():
	print("[DialogSystem] Sequência de diálogos finalizada")
	
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
	
	# Remove o sistema de diálogos e permite que o jogo continue normalmente
	queue_free() 