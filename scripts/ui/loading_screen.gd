extends CanvasLayer

# Referências aos elementos da UI
@onready var progress_bar = $CenterContainer/VBoxContainer/ProgressBar
@onready var loading_text = $CenterContainer/VBoxContainer/LoadingText
@onready var status_text = $CenterContainer/VBoxContainer/StatusText
@onready var loading_timer = $LoadingTimer

# Referências aos managers
@onready var scene_manager = get_node_or_null("/root/SceneManager")
@onready var state_manager = get_node_or_null("/root/GameStateManager")

# Estados do loading
var loading_progress = 0.0
var loading_speed = 8.0
var current_status_index = 0
var loading_complete = false

# Mensagens de status durante o loading
var status_messages = [
	"Inicializando sistemas...",
	"Carregando texturas...",
	"Preparando ambiente...",
	"Configurando iluminação...",
	"Carregando sons...",
	"Inicializando física...",
	"Preparando mundo...",
	"Quase pronto..."
]

func _ready():
	# Conecta o timer
	loading_timer.timeout.connect(_on_loading_timer_timeout)
	
	# Inicia com fade in
	var fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.z_index = 100
	add_child(fade_overlay)
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 0.8)
	tween.tween_callback(func(): fade_overlay.queue_free())
	
	print("[LoadingScreen] Tela de loading iniciada")

func _on_loading_timer_timeout():
	if loading_complete:
		return
	
	# Incrementa o progresso
	loading_progress += loading_speed
	progress_bar.value = loading_progress
	
	# Atualiza a mensagem de status baseada no progresso
	var status_threshold = 100.0 / status_messages.size()
	var new_status_index = int(loading_progress / status_threshold)
	
	if new_status_index != current_status_index and new_status_index < status_messages.size():
		current_status_index = new_status_index
		status_text.text = status_messages[current_status_index]
	
	# Verifica se o loading está completo
	if loading_progress >= 100.0:
		complete_loading()

func complete_loading():
	if loading_complete:
		return
		
	loading_complete = true
	loading_timer.stop()
	
	# Atualiza para estado final
	progress_bar.value = 100.0
	loading_text.text = "Completo!"
	status_text.text = "Entrando no pesadelo..."
	
	print("[LoadingScreen] Loading completo, mudando para o mundo...")
	
	# Aguarda um pouco antes de fazer a transição
	await get_tree().create_timer(1.0).timeout
	
	# Fade out e transição para o jogo
	var final_overlay = ColorRect.new()
	final_overlay.name = "FinalFadeOverlay"
	final_overlay.anchors_preset = Control.PRESET_FULL_RECT
	final_overlay.color = Color(0, 0, 0, 0)
	final_overlay.z_index = 100
	add_child(final_overlay)
	
	var final_tween = create_tween()
	final_tween.tween_property(final_overlay, "color:a", 1.0, 1.0)
	
	await final_tween.finished
	
	# Remove a cena atual antes de mudar
	queue_free()
	
	# Muda para o mundo usando o SceneManager
	if scene_manager:
		# Muda o estado do jogo para PLAYING
		if state_manager:
			state_manager.change_state(state_manager.GameState.PLAYING)
		# Muda para a cena do mundo
		scene_manager.change_scene("world")
	else:
		push_error("[LoadingScreen] SceneManager não encontrado!")

# Função para acelerar o loading (caso o jogador clique)
func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select") or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE) or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		if not loading_complete and loading_progress < 90.0:
			loading_speed = 25.0  # Acelera o loading
			loading_timer.wait_time = 0.05  # Timer mais rápido 