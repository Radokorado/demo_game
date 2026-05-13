extends Area3D

# --- ПРОМЕНЛИВИ ---
@export var damage: int = 1200
var distance_traveled: float = 0.0
var max_range: float = 15
var speed: float = 20
var direction: Vector3 = Vector3.ZERO

func setup(dir: Vector3, rng: float):
	direction = dir.normalized() 
	max_range = rng
	
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP)

func _physics_process(delta):
	if direction == Vector3.ZERO:
		return
		
	var step = direction * speed * delta
	global_position += step
	
	distance_traveled += step.length()
	
	if distance_traveled >= max_range:
		explode()

func _on_body_entered(body):
	if body.is_in_group("player"):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	explode()

func explode():
	queue_free()

func _on_timer_timeout():
	queue_free()
