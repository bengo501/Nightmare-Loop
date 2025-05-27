extends Control

# Referências comuns
@onready var background = $Background
@onready var menu_container = $MenuContainer

# Variáveis de animação
var tween: Tween
var button_hover_tweens = {}

# Configurações de animação
const ANIMATION_DURATION = 0.3
const BUTTON_ANIMATION_DELAY = 0.1
const HOVER_SCALE = Vector2(1.1, 1.1)
const PRESS_SCALE = Vector2(0.95, 0.95)

func _ready():
    setup_animations()
    connect_signals()
    initialize_menu()

func setup_animations():
    # Configuração inicial do menu
    if background:
        background.modulate.a = 0
    if menu_container:
        menu_container.modulate.a = 0
        menu_container.scale = Vector2(0.8, 0.8)

func connect_signals():
    # Conecta sinais comuns dos botões
    for button in get_menu_buttons():
        if button is Button:
            button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
            button.mouse_exited.connect(_on_button_mouse_exited.bind(button))

func initialize_menu():
    # Inicializa o menu com opacidade 0
    if background:
        background.modulate.a = 0
    if menu_container:
        menu_container.modulate.a = 0
        menu_container.scale = Vector2(0.8, 0.8)
    
    # Prepara os botões para a animação
    for button in get_menu_buttons():
        if button is Button:
            button.modulate.a = 0
            button.position.x = -200  # Posição inicial fora da tela
    
    # Anima a entrada do menu
    animate_menu_in()

func get_menu_buttons() -> Array:
    # Retorna uma lista de todos os botões no menu
    var buttons = []
    if menu_container:
        for child in menu_container.get_children():
            if child is Button:
                buttons.append(child)
    return buttons

func _on_button_mouse_entered(button: Button):
    if button_hover_tweens.has(button):
        button_hover_tweens[button].kill()
    
    button_hover_tweens[button] = create_tween()
    button_hover_tweens[button].tween_property(button, "scale", HOVER_SCALE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    button_hover_tweens[button].parallel().tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.2)

func _on_button_mouse_exited(button: Button):
    if button_hover_tweens.has(button):
        button_hover_tweens[button].kill()
    
    button_hover_tweens[button] = create_tween()
    button_hover_tweens[button].tween_property(button, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    button_hover_tweens[button].parallel().tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func animate_menu_in():
    # Anima o background
    tween = create_tween()
    if background:
        tween.tween_property(background, "modulate:a", 0.7, ANIMATION_DURATION)
    
    # Anima o container do menu
    if menu_container:
        tween.parallel().tween_property(menu_container, "modulate:a", 1.0, ANIMATION_DURATION)
        tween.parallel().tween_property(menu_container, "scale", Vector2(1, 1), ANIMATION_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    
    # Anima os botões sequencialmente
    var menu_buttons = get_menu_buttons()
    for i in range(menu_buttons.size()):
        var button = menu_buttons[i]
        var target_x = button.position.x + 200  # Posição final
        
        tween = create_tween()
        tween.tween_property(button, "modulate:a", 1.0, 0.2).set_delay(BUTTON_ANIMATION_DELAY * i)
        tween.parallel().tween_property(button, "position:x", target_x, ANIMATION_DURATION).set_delay(BUTTON_ANIMATION_DELAY * i).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func animate_menu_out():
    tween = create_tween()
    if background:
        tween.tween_property(background, "modulate:a", 0.0, ANIMATION_DURATION)
    if menu_container:
        tween.parallel().tween_property(menu_container, "modulate:a", 0.0, ANIMATION_DURATION)
        tween.parallel().tween_property(menu_container, "scale", Vector2(0.8, 0.8), ANIMATION_DURATION)
    
    # Anima os botões saindo para a esquerda
    var menu_buttons = get_menu_buttons()
    for i in range(menu_buttons.size()):
        var button = menu_buttons[i]
        tween.parallel().tween_property(button, "position:x", button.position.x - 200, ANIMATION_DURATION).set_delay(BUTTON_ANIMATION_DELAY * i)
    
    await tween.finished
    queue_free()

func animate_button_press(button: Button):
    var tween = create_tween()
    tween.tween_property(button, "scale", PRESS_SCALE, 0.1)
    tween.tween_property(button, "scale", Vector2(1, 1), 0.1) 