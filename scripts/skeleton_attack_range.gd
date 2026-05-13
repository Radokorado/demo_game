extends Area3D

@export var speed: float = 20.0
@export var damage: int = 500
@export var max_range: float = 10

var distance_traveled: float = 0.0
var direction: Vector3 = Vector3.ZERO
var has_hit: bool = false

func _ready():
	top_level = true 

func set_direction(dir: Vector3):
	direction = dir.normalized()
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP)

func _physics_process(delta):
	if direction == Vector3.ZERO:
		return
		
	var movement = direction * speed * delta
	global_position += movement
	
	distance_traveled += movement.length()
	if distance_traveled >= max_range:
		explode()

func _on_body_entered(body):
	if has_hit or not is_multiplayer_authority(): return
	
	if body.is_in_group("player"):
		hit_logic(body)
	elif body is StaticBody3D:
		explode()
		
func _on_area_entered(area):
	if has_hit or not is_multiplayer_authority(): return
	
	if area.name == "Hitbox" or area.is_in_group("player_hitbox"):
		hit_logic(area.get_parent())
		
func hit_logic(victim):
	if victim.has_method("take_damage"):
		has_hit = true 
		victim.take_damage(damage)
		explode()
		
func explode():
	# Тук можеш да добавиш частици (CPUParticles3D) преди queue_free()
	queue_free()
