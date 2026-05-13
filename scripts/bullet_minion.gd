extends Area3D

@export var speed: float = 25
@export var damage: int = 1200

var velocity: Vector3 = Vector3.ZERO

# Called from enemy
func set_direction(dir: Vector3):
	velocity = dir.normalized() * speed

func _physics_process(delta):
	global_position += velocity * delta

func _on_timer_timeout():
	queue_free()

func _on_body_entered(body):
	# Ignore player at spawn (optional, you may remove this later)
	if body.name == "Player":
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	queue_free()
