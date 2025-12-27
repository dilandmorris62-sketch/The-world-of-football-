hereextends CharacterBody3D

# Variables exportadas para ajuste en editor
@export var walk_speed: float = 3.0
@export var sprint_speed: float = 5.0
@export var rotation_speed: float = 8.0
@export var acceleration: float = 10.0
@export var deceleration: float = 15.0

# Referencias a nodos
@onready var animation_player = $AnimationPlayer
@onready var model = $Model
@onready var ball_detector = $BallDetector

# Estado del jugador
var current_speed: float = 0.0
var is_sprinting: bool = false
var has_ball: bool = false
var current_stamina: float = 100.0
var max_stamina: float = 100.0

# Input móvil
var movement_input: Vector2 = Vector2.ZERO
var target_rotation: float = 0.0

func _ready():
    # Conectar señales de input móvil
    var mobile_input = get_node("/root/MobileInput")
    if mobile_input:
        mobile_input.joystick_moved.connect(_on_joystick_moved)
        mobile_input.shoot_pressed.connect(_on_shoot_pressed)
        mobile_input.pass_pressed.connect(_on_pass_pressed)
        mobile_input.sprint_pressed.connect(_on_sprint_pressed)

func _physics_process(delta):
    # Manejar movimiento
    _handle_movement(delta)
    
    # Manejar rotación
    _handle_rotation(delta)
    
    # Actualizar animaciones
    _update_animations()
    
    # Manejar stamina
    _update_stamina(delta)
    
    # Movimiento final
    move_and_slide()

func _handle_movement(delta):
    var target_velocity = Vector3.ZERO
    
    if movement_input.length() > 0.1:
        # Calcular velocidad objetivo
        var speed = sprint_speed if is_sprinting and current_stamina > 0 else walk_speed
        target_velocity = Vector3(movement_input.x, 0, movement_input.y) * speed
        
        # Consumir stamina si está sprinting
        if is_sprinting:
            current_stamina = max(0, current_stamina - 15 * delta)
    else:
        # Frenar gradualmente
        target_velocity = Vector3.ZERO
    
    # Aplicar aceleración/desaceleración
    velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
    velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)

func _handle_rotation(delta):
    if movement_input.length() > 0.1:
        # Calcular ángulo de rotación basado en input
        target_rotation = atan2(movement_input.x, movement_input.y)
        
        # Rotar suavemente
        rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

func _update_animations():
    var speed_ratio = velocity.length() / sprint_speed
    
    # Animación de correr/caminar
    if speed_ratio > 0.1:
        animation_player.play("run")
        animation_player.speed_scale = speed_ratio * 1.5
    else:
        animation_player.play("idle")
    
    # Animación de tener balón
    animation_player.set_blend_time("idle", "idle_ball", 0.2)
    animation_player.set_blend_time("run", "run_ball", 0.2)

func _update_stamina(delta):
    # Regenerar stamina si no se está sprinting
    if not is_sprinting:
        current_stamina = min(max_stamina, current_stamina + 8 * delta)

func _on_joystick_moved(direction: Vector2):
    movement_input = direction

func _on_shoot_pressed():
    if has_ball:
        _shoot_ball()

func _on_pass_pressed():
    if has_ball:
        _pass_ball()

func _on_sprint_pressed(active: bool):
    is_sprinting = active

func _shoot_ball():
    # Lógica de disparo
    var ball = get_ball_in_range()
    if ball:
        var shoot_direction = -global_transform.basis.z
        var shoot_power = 20.0 + (current_stamina / max_stamina * 10.0)
        
        ball.apply_central_impulse(shoot_direction * shoot_power)
        has_ball = false
        
        # Animación de disparo
        animation_player.play("shoot")
        
        # Consumir stamina
        current_stamina = max(0, current_stamina - 25.0)

func _pass_ball():
    # Encontrar compañero más cercano
    var teammates = get_tree().get_nodes_in_group("teammates")
    var nearest_teammate = null
    var min_distance = INF
    
    for teammate in teammates:
        if teammate == self:
            continue
        
        var distance = global_position.distance_to(teammate.global_position)
        if distance < min_distance and distance < 15.0:
            min_distance = distance
            nearest_teammate = teammate
    
    if nearest_teammate and has_ball:
        var ball = get_ball_in_range()
        if ball:
            var pass_direction = (nearest_teammate.global_position - global_position).normalized()
            ball.apply_central_impulse(pass_direction * 15.0)
            has_ball = false
            
            animation_player.play("pass")

func get_ball_in_range():
    # Detectar balón cercano
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        global_position,
        global_position + Vector3(0, 0, -2),
        2
    )
    query.collision_mask = 2 # Capa del balón
    
    var result = space_state.intersect_ray(query)
    if result and result.collider.is_in_group("ball"):
        return result.collider
    
    return null

func _on_ball_detector_body_entered(body):
    if body.is_in_group("ball") and not has_ball:
        # Tomar el balón
        has_ball = true
        
        # Feedback visual
        var material = model.get_surface_override_material(0)
        if material:
            material.albedo_color = Color(1, 1, 0.5) # Amarillo claro
