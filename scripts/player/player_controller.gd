extends Node3D

# Variáveis da Câmera
@onready var camera = $ThirdPersonCamera

# Variáveis de Ataque
@export var attack_damage: float = 10.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0

var can_attack: bool = true
var attack_timer: Timer

func _ready():
	# Configuração da Câmera
	setup_camera()
	
	# Configuração do Sistema de Ataque
	setup_attack_system()

func setup_camera():
	if camera:
		# Definir a câmera como atual
		camera.make_current()
		
		# Configurar parâmetros da câmera
		camera.position = Vector3(0, 2, 4)
		camera.rotation_degrees = Vector3(-15, 0, 0)
		
		# Configurar o target (alvo) da câmera como o jogador
		if get_parent() and get_parent().has_node("Player"):
			var player = get_parent().get_node("Player")
			camera.target = player
			
		# Configurar outros parâmetros da câmera
		camera.mouse_sensitivity = 0.1
		camera.zoom_speed = 0.1
		camera.min_distance = 2.0
		camera.max_distance = 5.0

func setup_attack_system():
	# Configurar o timer de cooldown do ataque
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.connect("timeout", _on_attack_timer_timeout)
	add_child(attack_timer)

func _input(event):
	if event.is_action_pressed("attack") and can_attack:
		perform_attack()

func perform_attack():
	can_attack = false
	attack_timer.start()
	
	# Criar uma área de detecção para o ataque
	var attack_area = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = attack_range
	collision_shape.shape = shape
	attack_area.add_child(collision_shape)
	add_child(attack_area)
	
	# Conectar o sinal de área entrando
	attack_area.connect("body_entered", _on_attack_area_body_entered)
	
	# Remover a área de ataque após um curto período
	await get_tree().create_timer(0.1).timeout
	attack_area.queue_free()

func _on_attack_area_body_entered(body: Node3D):
	if body.is_in_group("enemy"):
		# Verificar se o inimigo tem um método take_damage
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)

func _on_attack_timer_timeout():
	can_attack = true 
