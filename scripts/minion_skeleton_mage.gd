extends CharacterBody3D

# --- VARIABLES ---
@export var bullet_scene: PackedScene 
@export var attack_range: float = 10.0
@export var detect_range: float = 11.0
const SPEED = 5.0 

@onready var muzzle = $Visuals/Muzzle
@onready var visuals = $Visuals
@onready var anim_tree = $Visuals/Skeleton_Mage/AnimationTree
@onready var health_bar: TextureProgressBar = $Sprite3D/SubViewport/TextureProgressBar
@onready var shield_effect = $ShieldEffect

var max_health: int = 3000 
var current_health: int = 3000
var is_dead: bool = false
var is_invincible: bool = false 
var shoot_cooldown: float = 1.5
var can_shoot: bool = true

# Detection
var targets_in_range: Array = []

func _ready():
	if is_multiplayer_authority():
		spawn_minion()
		
# --- Start ---
func _process(_delta):
	if not is_multiplayer_authority() or is_dead or is_invincible:
		return
	
	var target = get_closest_target()
	
	if target != null:
		var target_pos = target.global_transform.origin
		var look_target = Vector3(target_pos.x, global_position.y, target_pos.z)
		var target_basis = visuals.global_transform.looking_at(look_target, Vector3.UP).basis
		visuals.global_transform.basis = visuals.global_transform.basis.slerp(target_basis, 0.2)
		
		var direction_to_target = (look_target - global_position).normalized()
		var current_forward = -visuals.global_transform.basis.z 
		var dot = current_forward.dot(direction_to_target)

		if dot > 0.9 and global_position.distance_to(target_pos) <= attack_range and can_shoot:
			shoot()
	else:
		if velocity.length() > 0.1:
			var move_direction = velocity.normalized()
			var target_angle = atan2(-move_direction.x, -move_direction.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 0.1)

# --- AREA DETECTION ---
func _on_detect_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("minion"):
		if body != self and not targets_in_range.has(body):
			targets_in_range.append(body)

func _on_detect_area_body_exited(body: Node3D) -> void:
	if targets_in_range.has(body):
		targets_in_range.erase(body)

# --- TARGETING (ТУК Е ТАЙНАТА) ---
func get_closest_target() -> Node3D:
	var closest: Node3D = null
	var min_distance = detect_range
	
	for t in targets_in_range:
		if not is_instance_valid(t) or ("is_dead" in t and t.is_dead):
			continue
			
		var dist = global_position.distance_to(t.global_position)
		
		if dist < min_distance:
			min_distance = dist
			closest = t
	
	return closest

# --- SHOOT ---
func shoot():
	# Проверяваме дали има цел
	var target = get_closest_target()
	if target == null:
		return
	
	can_shoot = false 
	
	if anim_tree:
		anim_tree.set("parameters/ShootShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	await get_tree().create_timer(0.1).timeout 
	
	if not is_dead and is_instance_valid(target) and is_instance_valid(muzzle):
		muzzle.force_update_transform()
		var m_pos = muzzle.global_transform.origin
		var t_pos = target.global_transform.origin
		
		var horizontal_target = Vector3(t_pos.x, m_pos.y, t_pos.z)
		var direction = (horizontal_target - m_pos).normalized()
		
		spawn_bullet(direction, target)
	
	await get_tree().create_timer(shoot_cooldown - 0.1).timeout
	if not is_dead:
		can_shoot = true

# --- BULLET ---
func spawn_bullet(dir: Vector3, _t: Node3D):
	if not is_multiplayer_authority(): return
	if bullet_scene == null: return 
	
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	
	b.global_transform.origin = muzzle.global_transform.origin
	
	if b.has_method("set_direction"):
		b.set_direction(dir)

# --- DAMAGE ---
func take_damage(amount: int):
	if not is_multiplayer_authority() or is_dead or is_invincible:
		return
	
	current_health -= amount
	update_health_bar.rpc(current_health)
	
	if current_health <= 0:
		die()

@rpc("any_peer", "call_local")
func update_health_bar(new_value):
	if health_bar:
		health_bar.value = new_value

# --- DIE ---
func die():
	if is_dead: return
	is_dead = true
	
	anim_tree.set("parameters/LifeState/transition_request", "Dead")
	set_physics_process(false)
	$CollisionShape3D.set_deferred("disabled", true)
	
	if health_bar:
		health_bar.hide()
	
	await get_tree().create_timer(10.0).timeout
	
	respawn_logic()

# --- SPAWN ---
func spawn_minion():
	anim_tree.active = true
	is_dead = false
	is_invincible = true
	can_shoot = false
	
	if shield_effect:
		shield_effect.show()
	
	anim_tree.set("parameters/LifeState/transition_request", "Alive")
	anim_tree.set("parameters/SpawnShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	await get_tree().create_timer(2.5).timeout
	
	is_invincible = false
	can_shoot = true
	
	if shield_effect:
		shield_effect.hide()

# --- RESPAWN LOGIC ---
func respawn_logic():
	current_health = max_health
	update_health_bar.rpc(current_health)
	if health_bar:
		health_bar.show()
	$CollisionShape3D.set_deferred("disabled", false)
	set_physics_process(true)
	targets_in_range.clear()
	
	spawn_minion()
