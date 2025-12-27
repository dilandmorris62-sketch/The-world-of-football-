extends Node

enum SkillType {
    SHOOT,
    DRIBBLE,
    TACKLE,
    PASS,
    AURA
}

class Skill:
    var name: String
    var type: SkillType
    var power: float
    var stamina_cost: float
    var cooldown: float
    var icon: Texture2D
    
    func _init(_name: String, _type: SkillType, _power: float, _cost: float, _cd: float):
        name = _name
        type = _type
        power = _power
        stamina_cost = _cost
        cooldown = _cd

# Habilidades disponibles
var skills: Dictionary = {}
var cooldowns: Dictionary = {}
var special_meter: float = 0.0
var max_special_meter: float = 100.0

@onready var player = get_parent()

func _ready():
    # Inicializar habilidades
    _initialize_skills()
    
    # Inicializar cooldowns
    for skill_name in skills.keys():
        cooldowns[skill_name] = 0.0

func _initialize_skills():
    skills = {
        "fire_shot": Skill.new("Fire Shot", SkillType.SHOOT, 80.0, 40.0, 10.0),
        "dragon_dribble": Skill.new("Dragon Dribble", SkillType.DRIBBLE, 60.0, 30.0, 8.0),
        "power_tackle": Skill.new("Power Tackle", SkillType.TACKLE, 70.0, 35.0, 12.0),
        "precision_pass": Skill.new("Precision Pass", SkillType.PASS, 50.0, 25.0, 5.0),
        "blue_lock_aura": Skill.new("Blue Lock Aura", SkillType.AURA, 90.0, 50.0, 15.0)
    }

func _process(delta):
    # Actualizar cooldowns
    for skill_name in cooldowns.keys():
        if cooldowns[skill_name] > 0:
            cooldowns[skill_name] = max(0, cooldowns[skill_name] - delta)
    
    # Regenerar medidor especial
    if player.has_ball:
        special_meter = min(max_special_meter, special_meter + delta * 5)

func activate_skill(skill_name: String, target: Vector3 = Vector3.ZERO) -> bool:
    if not skills.has(skill_name):
        print("Habilidad no encontrada: ", skill_name)
        return false
    
    var skill = skills[skill_name]
    
    # Verificar cooldown
    if cooldowns[skill_name] > 0:
        print("Habilidad en cooldown: ", skill_name)
        return false
    
    # Verificar stamina
    if player.current_stamina < skill.stamina_cost:
        print("Stamina insuficiente")
        return false
    
    # Verificar medidor especial para habilidades fuertes
    if skill.power > 70 and special_meter < 50:
        print("Medidor especial insuficiente")
        return false
    
    # Ejecutar habilidad
    match skill.type:
        SkillType.SHOOT:
            _execute_shoot_skill(skill, target)
        SkillType.DRIBBLE:
            _execute_dribble_skill(skill)
        SkillType.AURA:
            _execute_aura_skill(skill)
    
    # Aplicar costos
    player.current_stamina -= skill.stamina_cost
    cooldowns[skill_name] = skill.cooldown
    
    if skill.power > 70:
        special_meter = max(0, special_meter - 50)
    
    return true

func _execute_shoot_skill(skill: Skill, target: Vector3):
    var ball = player.get_ball_in_range()
    if ball:
        var direction = target if target != Vector3.ZERO else -player.global_transform.basis.z
        var power_multiplier = skill.power / 100.0
        
        # Aplicar fuerza al balón
        ball.apply_central_impulse(direction.normalized() * 25.0 * power_multiplier)
        
        # Efecto visual
        _create_skill_effect("fire_particles", player.global_position)
        
        # Cámara lenta
        Engine.time_scale = 0.5
        await get_tree().create_timer(1.0).timeout
        Engine.time_scale = 1.0

func _execute_aura_skill(skill: Skill):
    # Aura estilo Blue Lock
    var aura_area = SphereShape3D.new()
    aura_area.radius = 10.0
    
    var query = PhysicsShapeQueryParameters3D.new()
    query.shape = aura_area
    query.transform = Transform3D(Basis(), player.global_position)
    query.collision_mask = 1 # Capa de jugadores
    
    var space_state = player.get_world_3d().direct_space_state
    var results = space_state.intersect_shape(query)
    
    for result in results:
        var other_player = result.collider
        if other_player.is_in_group("player"):
            if other_player.is_in_group(player.get_groups()[0]): # Mismo equipo
                # Buff a compañeros
                other_player.apply_speed_boost(1.5, 5.0)
            else:
                # Debuff a oponentes
                other_player.apply_speed_debuff(0.7, 3.0)
    
    # Efecto visual de aura
    _create_skill_effect("aura_particles", player.global_position)

func _create_skill_effect(effect_name: String, position: Vector3):
    # Cargar y crear partículas
    var effect_scene = load("res://assets/effects/%s.tscn" % effect_name)
    if effect_scene:
        var effect_instance = effect_scene.instantiate()
        get_tree().root.add_child(effect_instance)
        effect_instance.global_position = position
        
        # Auto-destruir después de 3 segundos
        await get_tree().create_timer(3.0).timeout
        effect_instance.queue_free()

func get_skill_cooldown(skill_name: String) -> float:
    return cooldowns.get(skill_name, 0.0)

func get_skill_progress(skill_name: String) -> float:
    var skill = skills.get(skill_name)
    if not skill:
        return 0.0
    
    var cooldown = cooldowns.get(skill_name, 0.0)
    return 1.0 - (cooldown / skill.cooldown)￼Enter
