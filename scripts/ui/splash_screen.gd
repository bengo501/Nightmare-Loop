extends CanvasLayer

@onready var logo = $Logo
@onready var loading_label = $Loading

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
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_loading_timer_timeout():
    loading_dots = (loading_dots + 1) % 4
    loading_label.text = "Carregando" + ".".repeat(loading_dots) 