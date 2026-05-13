extends Control


func _on_start_pressed() -> void:
	Signals.emit_signal("start_game")


func _on_settings_pressed() -> void:
	get_node("buttons").hide()


func _on_quit_pressed() -> void:
	get_node("buttons").hide()
