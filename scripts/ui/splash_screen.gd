extends CanvasLayer

@onready var logo = $Logo
@onready var loading_label = $Loading
@onready var scene_manager = get_node_or_null("/root/SceneManager")

var loading_dots = 0
var loading_timer = null

func _ready():
    # Fade-in do logo
    logo.modulate.a = 0
    var tween = create_tween()
    tween.tween_property(logo, "modulate:a", 1.0, 1.0)
    tween.tween_callback(Callable(self, "_on_fade_in_finished"))
    # Iniciar animação de loading
    loading_timer = Timer.new()
    loading_timer.wait_time = 0.4
    loading_timer.autostart = true
    loading_timer.one_shot = false
    loading_timer.timeout.connect(_on_loading_timer_timeout)
    add_child(loading_timer)

func _on_fade_in_finished():
    await get_tree().create_timer(1.0).timeout
    
    # Cria overlay para fade out
    var fade_overlay = ColorRect.new()
    fade_overlay.name = "FadeOverlay"
    fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
    fade_overlay.color = Color(0, 0, 0, 0)
    fade_overlay.z_index = 100
    add_child(fade_overlay)
    
    # Fade out
    var tween = create_tween()
    tween.tween_property(fade_overlay, "color:a", 1.0, 1.0)
    
    await tween.finished
    
    # Remove a SplashScreen antes de mudar de cena
    queue_free()
    
    # Muda para o menu principal usando o SceneManager
    if scene_manager:
        scene_manager.change_scene("main_menu")
    else:
        push_error("[SplashScreen] SceneManager não encontrado!")

func _on_loading_timer_timeout():
    loading_dots = (loading_dots + 1) % 4
    loading_label.text = "Carregando" + ".".repeat(loading_dots) 