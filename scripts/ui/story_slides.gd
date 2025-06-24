extends CanvasLayer

# Estrutura dos slides com imagem e narrativa
var slides = [
	{
		"image": "res://assets/slides/slideJogo1.png",
		"text": "Aquele dia parecia como qualquer outro... até que tudo mudou.",
		"title": "🕯️ Acidente iminente"
	},
	{
		"image": "res://assets/slides/slideJogo2.png", 
		"text": "Um instante... uma curva... e então...\n\n(pausa)\n\nTudo ficou branco.",
		"title": "🕯️ O impacto"
	},
	{
		"image": "res://assets/slides/slideJogo4.png",
		"text": "Quando acordei... estava no hospital.\n\nMas ele... não teve a mesma sorte.",
		"title": "🕯️ Hospital"
	},
	{
		"image": "res://assets/slides/slideJogo5.png",
		"text": "O funeral foi... surreal.\n\nParecia que parte de mim... tinha sido enterrada junto com ele.",
		"title": "🕯️ Funeral"
	},
	{
		"image": "res://assets/slides/sideJogo6.png",
		"text": "Depois disso... eu simplesmente... existi.\n\nHoras e horas... navegando na internet...\n\nTentando preencher o vazio.",
		"title": "🕯️ Quarto escuro"
	},
	{
		"image": "res://assets/slides/slideJogo7.png",
		"text": "Foi quando eu encontrei algo...\n\nUm tópico perdido, cheio de comentários apagados...\n\nFalava sobre... um site.\n\nUm site onde... você pode conversar com alguém que já se foi.",
		"title": "🕯️ Fórum misterioso"
	},
	{
		"image": "res://assets/slides/slideJogo8.png",
		"text": "Eu não pensei muito... apenas... cliquei.\n\nPreenchi o nome dele... e...\n\nNada aconteceu.",
		"title": "🕯️ Tela do site"
	},
	{
		"image": "res://assets/slides/slideJogo9.png",
		"text": "Mas... o que eu não esperava...\n\nEra o que viria depois.",
		"title": "🕯️ Distorções"
	},
	{
		"image": "res://assets/slides/slideJogo10.png",
		"text": "Naquela noite... meu pesadelo começou.\n\nE nunca mais... acabou.",
		"title": "🕯️ Pesadelo"
	},
	{
		"image": "res://assets/slides/slideJogo1.png", # Usando a primeira como final com efeito
		"text": "Nightmare Loop\n\nQuebre o ciclo.",
		"title": "🕯️ Final",
		"is_final": true
	}
]

var current_slide = 0
var is_transitioning = false

@onready var slide_text = $SlideText
@onready var slide_image = $SlideImage
@onready var next_button = $NextButton
@onready var skip_button = $SkipButton
@onready var overlay = $Overlay
@onready var ambient_audio = $AmbientAudio

func _ready():
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	set_process_input(true)
	
	# Inicia com fade in usando um overlay
	var fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.z_index = 100
	add_child(fade_overlay)
	
	show_slide(0)
	
	# Fade in inicial
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 1.0)
	tween.tween_callback(func(): fade_overlay.queue_free())

func show_slide(index: int):
	if index >= slides.size():
		finish_slides()
		return
	
	var slide_data = slides[index]
	
	# Carrega a imagem
	var texture = load(slide_data.image)
	if texture:
		slide_image.texture = texture
	
	# Define o texto
	slide_text.text = slide_data.text
	
	# Efeito especial para o slide final
	if slide_data.has("is_final") and slide_data.is_final:
		overlay.color = Color(0, 0, 0, 0.8)
		slide_text.add_theme_font_size_override("font_size", 48)
		slide_text.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0, 1.0))
		next_button.text = "Começar Jogo"
	else:
		overlay.color = Color(0, 0, 0, 0.4)
		slide_text.add_theme_font_size_override("font_size", 32)
		slide_text.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		next_button.text = "Continuar"

func _on_next_pressed():
	if is_transitioning:
		return
	advance_slide()

func _on_skip_pressed():
	finish_slides()

func _input(event):
	if is_transitioning:
		return
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select") or \
	   event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down") or \
	   event.is_action_pressed("ui_page_down") or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE) or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		advance_slide()
	elif event.is_action_pressed("ui_cancel") or \
		 (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		finish_slides()

func advance_slide():
	is_transitioning = true
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(slide_text, "modulate:a", 0.0, 0.3)
	tween.tween_property(slide_image, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	
	current_slide += 1
	
	if current_slide < slides.size():
		# Mostra o próximo slide
		show_slide(current_slide)
		
		# Fade in
		var fade_in_tween = create_tween()
		fade_in_tween.parallel().tween_property(slide_text, "modulate:a", 1.0, 0.5)
		fade_in_tween.parallel().tween_property(slide_image, "modulate:a", 1.0, 0.5)
		
		await fade_in_tween.finished
	else:
		finish_slides()
	
	is_transitioning = false

func finish_slides():
	print("[StorySlides] Finalizando slides, mudando para tela de loading...")
	
	# Cria overlay para fade out final
	var final_overlay = ColorRect.new()
	final_overlay.name = "FinalFadeOverlay"
	final_overlay.anchors_preset = Control.PRESET_FULL_RECT
	final_overlay.color = Color(0, 0, 0, 0)
	final_overlay.z_index = 100
	add_child(final_overlay)
	
	# Fade out final
	var final_tween = create_tween()
	final_tween.tween_property(final_overlay, "color:a", 1.0, 1.0)
	
	await final_tween.finished
	
	# Muda para a tela de loading
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn") 
