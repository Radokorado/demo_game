extends Node3D

@onready var placeholder: MeshInstance3D = $placeholder
@onready var sprite_3d: Sprite3D = $Sprite3D

@export var healing = 1000

func _on_area_3d_body_entered(body: Node3D) -> void:
	if placeholder.visible == true:
		Signals.emit_signal("healing", healing)
		placeholder.hide()
		sprite_3d.hide()
		await get_tree().create_timer(2.0).timeout
		placeholder.show()
		sprite_3d.show()	
	else:
		pass
