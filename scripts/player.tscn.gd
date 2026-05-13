extends CharacterBody3D

# --- ПРОМЕНЛИВИ ---
@export var bullet_scene: PackedScene 
@export var attack_range: float = 15
const SPEED = 9

@onready var visuals = $Visuals 
@onready var weapon_arm = $WeaponArm 
@onready var muzzle = $WeaponArm/Muzzle
@onready var camera = $Camera3D
@onready var health_bar: TextureProgressBar = $Sprite3D/SubViewport/TextureProgressBar
@onready var shield_effect = $ShieldEffect
@onready var anim_player = $Visuals/UAL1/AnimationPlayer
@onready var anim_tree = $Visuals/UAL1/AnimationTree
@onready var start_position: Vector3 = global_position
@onready var aim_line = $AimLine

var is_aiming: bool = false 
var is_invincible: bool = false
var max_health: int = 7400
var current_health: int = 7400
var time_since_last_hit: float = 0.0
var is_dead: bool = false

var max_bullets: int = 3
var current_bullets: int = 3
var can_reload: bool = true
var reload_time: float = 1.8
var is_turning_to_mouse: bool = false
var is_attacking: bool = false

# --- СТАРТИРАНЕ ---
func _ready():
	Signals.connect("healing", Callable(self, "_on_healing"))
	spawn_hero()
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
# --- ОСНОВЕН ЦИКЪЛ ---
func _physics_process(_delta):
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	if not is_turning_to_mouse:
		if direction:
			visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-direction.x, -direction.z), 0.15)
			anim_tree.set("parameters/Move State/transition_request", "Running_A")
		else:
			anim_tree.set("parameters/Move State/transition_request", "Idle_A")
	else:
		rotate_visuals_to_mouse()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	aim_weapon_at_mouse()
	
	if Input.is_action_just_pressed("shoot") and not is_dead:
		if aim_line:
			await get_tree().process_frame
			aim_line.show()
		
	if Input.is_action_pressed("shoot") and aim_line.visible:
		update_aim_line()
		
	if Input.is_action_just_released("shoot"):
		if aim_line:
			aim_line.hide()
		shoot()

# --- ФУНКЦИИ ---

func _on_healing(healing_value):
	current_health += healing_value
	health_bar.value = current_health

func aim_weapon_at_mouse():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	var plane = Plane(Vector3.UP, global_position.y)
	var intersection = plane.intersects_ray(ray_origin, ray_direction)
	
	if intersection != null:
		var look_target = Vector3(intersection.x, weapon_arm.global_position.y, intersection.z)
		if weapon_arm.global_position.distance_to(look_target) > 0.5:
			weapon_arm.look_at(look_target, Vector3.UP)

func update_aim_line():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	var plane = Plane(Vector3.UP, global_position.y)
	var intersection = plane.intersects_ray(ray_origin, ray_direction)
	
	if intersection != null:
		var target_pos = Vector3(intersection.x, global_position.y, intersection.z)
		var direction_to_mouse = (target_pos - global_position).normalized()
		var muzzle_pos_horizontal = Vector3(muzzle.global_position.x, global_position.y, muzzle.global_position.z)
		var offset_dist = global_position.distance_to(muzzle_pos_horizontal)
		var angle = atan2(direction_to_mouse.x, direction_to_mouse.z)
		aim_line.rotation.y = angle
		aim_line.scale.z = attack_range
		var final_offset = direction_to_mouse * (offset_dist + attack_range / 2.0)
		aim_line.global_position = global_position + final_offset + Vector3(0, 0.1, 0)

func shoot():
	if current_bullets > 0 and not is_dead:
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_direction = camera.project_ray_normal(mouse_pos)
		var plane = Plane(Vector3.UP, global_position.y)
		var intersection = plane.intersects_ray(ray_origin, ray_direction)
		
		if intersection:
			var target_pos = Vector3(intersection.x, global_position.y, intersection.z)
			var look_dir = (target_pos - global_position).normalized()
			var target_angle = atan2(look_dir.x, look_dir.z)
			
			visuals.rotation.y = target_angle + PI 
			visuals.rotation.x = 0
			visuals.rotation.z = 0

		anim_tree.set("parameters/ShootShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
		await get_tree().create_timer(0.1).timeout
		spawn_bullet()
		
		current_bullets -= 1
		print(str(current_bullets) + " ammo left")
		start_reload()
	else:
		print("No Ammo")
		
func spawn_bullet():
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	
	b.global_transform = muzzle.global_transform
	
	# ПРЕСМЯТАНЕ НА ПОСОКАТА КЪМ МИШКАТА
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	var plane = Plane(Vector3.UP, global_position.y)
	var intersection = plane.intersects_ray(ray_origin, ray_direction)
	
	if intersection:
		var target_pos = Vector3(intersection.x, muzzle.global_transform.origin.y, intersection.z)
		var bullet_dir = (target_pos - muzzle.global_transform.origin).normalized()
		
		if b.has_method("setup"):
			b.setup(bullet_dir, attack_range)
		elif b.has_method("set_direction"):
			b.set_direction(bullet_dir)
	
func start_reload():
	if not can_reload or current_bullets >= max_bullets:
		return
	can_reload = false
	await get_tree().create_timer(reload_time).timeout
	current_bullets += 1
	# Добавено съобщение за презаредени амуниции
	print(str(current_bullets) + " ammo reloaded")
	can_reload = true
	if current_bullets < max_bullets:
		start_reload()
		
func rotate_visuals_to_mouse():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	var plane = Plane(Vector3.UP, global_position.y)
	var intersection = plane.intersects_ray(ray_origin, ray_direction)
	
	if intersection != null:
		var target_pos = Vector3(intersection.x, global_position.y, intersection.z)
		var target_dir = (target_pos - global_position).normalized()
		var target_angle = atan2(-target_dir.x, -target_dir.z)
		
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 0.7)
		
func take_damage(amount: int):
	if is_dead or is_invincible: 
		return
	
	print("Take a hit:", amount)
	time_since_last_hit = 0.0
	current_health -= amount
	if health_bar:
		health_bar.value = current_health
	if current_health <= 0:
		die()
		
func spawn_hero():
	is_dead = false
	is_invincible = true 
	current_health = max_health
	
	if shield_effect:
		shield_effect.show()
	
	global_position = start_position
	set_physics_process(true)
	$CollisionShape3D.disabled = false
	
	if has_node("Hitbox/CollisionShape3D"):
		$Hitbox/CollisionShape3D.set_deferred("disabled", false)
	
	anim_tree.set("parameters/LifeState/transition_request", "Alive")
	anim_tree.set("parameters/SpawnShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	health_bar.value = health_bar.max_value
	await get_tree().create_timer(2.0).timeout
	is_invincible = false
	if shield_effect:
		shield_effect.hide()

func die():
	if is_dead: return
	is_dead = true
	
	anim_tree.set("parameters/LifeState/transition_request", "Dead")
	set_physics_process(false)
	$CollisionShape3D.disabled = true
	
	if has_node("Hitbox/CollisionShape3D"):
		$Hitbox/CollisionShape3D.set_deferred("disabled", true)
	
	print("Revive in 7 sec")
	await get_tree().create_timer(7.0).timeout
	spawn_hero()
