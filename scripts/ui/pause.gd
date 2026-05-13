extends Control
@onready var settings: Control = $settings

func _on_continue_pressed():
	Signals.emit_signal("Opening_menu")


func _on_options_pressed():
	#Signals.emit_signal("Opening_menu", 6)
	settings.show()

func _on_quit_pressed():
	get_tree().quit()


func _on_quit_to_main_menu_pressed() -> void:
	Signals.emit_signal("to_main_menu")
