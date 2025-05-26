extends Control

signal gift_selected(gift_id)

func _ready():
    $Panel/VBoxContainer/Gift1.pressed.connect(_on_gift_pressed.bind(0))
    $Panel/VBoxContainer/Gift2.pressed.connect(_on_gift_pressed.bind(1))
    $Panel/VBoxContainer/Gift3.pressed.connect(_on_gift_pressed.bind(2))
    $Panel/VBoxContainer/Gift4.pressed.connect(_on_gift_pressed.bind(3))
    $Panel/VBoxContainer/Gift5.pressed.connect(_on_gift_pressed.bind(4))
    $Panel/CloseButton.pressed.connect(_on_close_pressed)
    hide()

func show_menu():
    show()
    move_to_front()

func _on_gift_pressed(gift_id):
    emit_signal("gift_selected", gift_id)
    hide()

func _on_close_pressed():
    hide() 