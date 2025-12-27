extends Node

# Configuración de calidad
@export var quality_presets: Dictionary = {
    "low": {
        "shadow_size": 1024,
        "shadow_filter": false,
        "msaa": 0,
        "ssao": false,
        "particles_quality": 0.5,
        "view_distance": 50.0
    },
    "medium": {
        "shadow_size": 2048,
        "shadow_filter": true,
        "msaa": 2,
        "ssao": true,
        "particles_quality": 0.8,
        "view_distance": 75.0
    },
    "high": {
        "shadow_size": 4096,
        "shadow_filter": true,
        "msaa": 4,
        "ssao": true,
        "particles_quality": 1.0,
        "view_distance": 100.0
    }
}

var current_preset: String = "medium"
var target_fps: int = 60
var last_fps_check: float = 0.0
var fps_check_interval: float = 2.0

func _ready():
    # Detectar hardware
    _detect_hardware_capabilities()
    
    # Aplicar configuración inicial
    apply_quality_preset(current_preset)
    
    # Configurar para móvil
    Engine.max_fps = target_fps
    DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
    
    # Habilitar modo ahorro de batería
    OS.low_processor_usage_mode = true

func _process(delta):
    # Monitorear FPS y ajustar calidad dinámicamente
    last_fps_check += delta
    if last_fps_check >= fps_check_interval:
        last_fps_check = 0.0
        _dynamic_quality_adjustment()

func _detect_hardware_capabilities():
    var gpu_name = RenderingServer.get_video_adapter_name()
    var gpu_vendor = RenderingServer.get_video_adapter_vendor()
    
    print("GPU: ", gpu_name)
    print("Vendor: ", gpu_vendor)
    
    # Detectar gama baja/alta
    if "adreno" in gpu_name.to_lower() or "mali" in gpu_name.to_lower():
        # GPUs móviles comunes
        current_preset = "medium"
    elif "power" in gpu_name.to_lower():
        # GPUs de gama baja
        current_preset = "low"
    else:
        # Asumir capacidad decente
        current_preset = "medium"

func apply_quality_preset(preset_name: String):
    if not quality_presets.has(preset_name):
        print("Preset no encontrado: ", preset_name)
        return
    
    var preset = quality_presets[preset_name]
    current_preset = preset_name
    
    # Aplicar configuración gráfica
    ProjectSettings.set_setting("rendering/quality/shadows/size", preset.shadow_size)
    ProjectSettings.set_setting("rendering/quality/shadows/filter_mode", 
                               "pcss" if preset.shadow_filter else "disabled")
    
    # MSAA
    var msaa_value = preset.msaa
    match msaa_value:
        0:
            ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa", "disabled")
        2:
            ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa", "2x")
        4:
            ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa", "4x")
    
    # SSAO
    ProjectSettings.set_setting("rendering/quality/ssao/quality", 
                               "medium" if preset.ssao else "disabled")
    
    print("Calidad aplicada: ", preset_name)

func _dynamic_quality_adjustment():
    var current_fps = Engine.get_frames_per_second()
    
    if current_fps < 30:
        # Bajar calidad
        if current_preset == "high":
            apply_quality_preset("medium")
        elif current_preset == "medium":
            apply_quality_preset("low")
    
    elif current_fps > 50 and current_preset != "high":
        # Subir calidad si hay margen
        if current_preset == "low":
            apply_quality_preset("medium")
        elif current_preset == "medium":
            apply_quality_preset("high")

func enable_object_pooling():
    # Sistema simple de pooling para instancias frecuentes
    var preloaded_scenes = {
        "ball": preload("res://scenes/core/ball.tscn"),
        "player": preload("res://scenes/core/player_3d.tscn"),
        "effect": preload("res://assets/effects/basic_effect.tscn")
    }
    
    # Crear pools iniciales
    for key in preloaded_scenes.keys():
        var pool = []
        for i in range(5): # Pool de 5 instancias
            var instance = preloaded_scenes[key].instantiate()
            instance.hide()
            get_tree().root.add_child(instance)
            pool.append(instance)
        
        Global.object_pools[key] = pool

func set_view_distance(distance: float):
    # Ajustar distancia de vista para optimización
    var camera = get_viewport().get_camera_3d()
    if camera:
        camera.far = distance
        
        # También ajustar frustum culling
        RenderingServer.viewport_set_scenario(
            get_viewport().get_viewport_rid(),
            get_world_3d().scenario
        )
