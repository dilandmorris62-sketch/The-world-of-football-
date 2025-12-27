extends Node

# Señales para comunicación
signal joystick_moved(direction)
signal shoot_pressed
signal pass_pressed
signal sprint_pressed(active)
signal skill_pressed(skill_index)

# Variables exportadas para ajuste en editor
@export var joystick_deadzone: float = 0.1
@export var touch_threshold: float = 50.0

# Variables internas
var joystick_active: bool = false
var joystick_origin: Vector2 = Vector2.ZERO
var current_joystick_direction: Vector2 = Vector2.ZERO
var touch_start_positions: Dictionary = {}
var button_states: Dictionary = {}

func _ready():
    # Configurar para pantalla táctil
    DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
    Engine.max_fps = 60
    
    # Inicializar estados de botones
    button_states = {
        "shoot": false,
        "pass": false,
        "sprint": false,
        "skill1": false,
        "skill2": false
    }

func _input(event):
    # Procesar eventos táctiles
    if event is InputEventScreenTouch:
        _handle_touch_event(event)
    elif event is InputEventScreenDrag:
        _handle_drag_event(event)

func _handle_touch_event(event: InputEventScreenTouch):
    var touch_position = event.position
    
    if event.pressed:
        # Almacenar posición inicial del toque
        touch_start_positions[event.index] = touch_position
        
        # Verificar si es toque en botones (se implementa en UI)
        _check_button_press(touch_position)
        
        # Activar joystick si toca en zona izquierda
        if touch_position.x < get_viewport().size.x * 0.3:
            joystick_active = true
            joystick_origin = touch_position
    else:
        # Liberar toque
        if event.index in touch_start_positions:
            touch_start_positions.erase(event.index)
        
        # Desactivar joystick si estaba activo
        if joystick_active:
            joystick_active = false
            current_joystick_direction = Vector2.ZERO
            joystick_moved.emit(Vector2.ZERO)
        
        # Liberar botón sprint
        if button_states["sprint"]:
            button_states["sprint"] = false
            sprint_pressed.emit(false)

func _handle_drag_event(event: InputEventScreenDrag):
    if not joystick_active:
        return
    
    var drag_vector = event.position - joystick_origin
    var distance = drag_vector.length()
    
    # Aplicar deadzone y normalizar
    if distance > touch_threshold * joystick_deadzone:
        var normalized_direction = drag_vector.normalized()
        var magnitude = min(distance / touch_threshold, 1.0)
        
        current_joystick_direction = normalized_direction * magnitude
        joystick_moved.emit(current_joystick_direction)
    else:
        current_joystick_direction = Vector2.ZERO
        joystick_moved.emit(Vector2.ZERO)

func _check_button_press(position: Vector2):
    # Esta función se implementará en conjunto con la UI
    # Por ahora, emite señales basadas en posición simple
    var screen_size = get_viewport().size
    
    # Zona derecha inferior - Disparo
    if position.x > screen_size.x * 0.7 and position.y > screen_size.y * 0.7:
        button_states["shoot"] = true
        shoot_pressed.emit()
    
    # Zona derecha media - Pase
    elif position.x > screen_size.x * 0.7 and position.y > screen_size.y * 0.5:
        button_states["pass"] = true
        pass_pressed.emit()
    
    # Zona derecha superior - Sprint
    elif position.x > screen_size.x * 0.8 and position.y < screen_size.y * 0.3:
        button_states["sprint"] = true
        sprint_pressed.emit(true)

func get_movement_direction() -> Vector2:
    return current_joystick_direction

func is_button_pressed(button_name: String) -> bool:
    return button_states.get(button_name, false)￼Enter
