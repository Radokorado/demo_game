extends Node
@onready var start_ui: Control = $"start ui/start_ui"
@onready var pause: CanvasLayer = $pause

var in_game =false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.connect("start_game", Callable(self, "_on_start_game"))
	Signals.connect("Opening_menu", Callable(self, "_on_Opening_menu"))
	Signals.connect("to_main_menu", Callable(self, "_on_to_main_menu"))

func _on_Opening_menu():
	pause.hide()
	get_tree().paused = false

func _on_to_main_menu():
	get_node("training_ground").queue_free()
	start_ui.show()
	pause.hide()
	in_game = false
	get_tree().paused = false

func _on_start_game():
#	when the levels become bigger we can make a more compleks loading system
	start_ui.hide()
	var scene = load("res://scence/levels/training_ground.tscn")
	add_child(scene.instantiate())
	in_game = true
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esk") and in_game == true:
		pause.show()
		print("asd")
		get_tree().paused = true
