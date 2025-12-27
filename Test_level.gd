hereextends Node3D

func _ready():
    print("=== THE WORLD OF FOOTBALL ===")
    print("Controles:")
    print("WASD - Movimiento")
    print("Shift - Correr")
    print("F - Disparar")
    print("G - Pasar")
    print("========================")
    
    # Crear ambiente básico
    var world_env = WorldEnvironment.new()
    var env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.1, 0.3, 0.5)
    world_env.environment = env
    add_child(world_env)
    
    # Crear luz básica
    var directional_light = DirectionalLight3D.new()
    directional_light.light_color = Color(1, 1, 0.9)
    directional_light.light_energy = 1.0
    directional_light.rotation_degrees = Vector3(-45, 45, 0)
    add_child(directional_light)

func _process(delta):
    # Debug - mostrar posición del jugador
    if Input.is_action_just_pressed("ui_accept"):
        var player = $Player
        print("Posición del jugador: ", player.global_position)
