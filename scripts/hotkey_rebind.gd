extends Control

@onready var label = $HBoxContainer/Label
@onready var button = $HBoxContainer/Button

@export var action_name: String = "left"

var listening: bool = false  # Tracks if we are waiting for key/mouse input

func _ready() -> void:
	set_process_unhandled_key_input(false)
	set_action_name()
	set_text_for_key()
	Signals.connect("Refresh", Callable(self, "refresh"))

func refresh():
	set_text_for_key()
# Set the descriptive label for the action
func set_action_name() -> void:
	match action_name:
		"move_up": label.text = "Foward"
		"move_down": label.text = "Backwards"
		"move_left": label.text = "left"
		"move_right": label.text = "Right"
		"shoot": label.text = "Shoot"
		"esk": label.text = "Back (menus)"
		_: label.text = "Unassigned"

# Display the currently bound key/mouse
func set_text_for_key() -> void:
	var events = InputMap.action_get_events(action_name)

	if events.is_empty():
		button.text = "Not Bound"
		return

	var e = events[0]
	if e is InputEventKey:
		button.text = OS.get_keycode_string(e.physical_keycode)
	elif e is InputEventMouseButton:
		var mouse_names = {
			MOUSE_BUTTON_LEFT: "Left Mouse Button",
			MOUSE_BUTTON_RIGHT: "Right Mouse Button",
			MOUSE_BUTTON_MIDDLE: "Middle Mouse Button",
			MOUSE_BUTTON_WHEEL_UP: "Mouse Wheel Up",
			MOUSE_BUTTON_WHEEL_DOWN: "Mouse Wheel Down"
		}
		button.text = mouse_names.get(e.button_index, "Mouse Button " + str(e.button_index))
	else:
		button.text = "Unsupported Input"

# Called when the button is toggled
func _on_button_toggled(toggled_on: bool) -> void:
	listening = toggled_on
	set_process_unhandled_key_input(listening)

	if listening:
		button.text = "Press any key..."
		# Make sure all other hotkey buttons stop listening
		for i in get_tree().get_nodes_in_group("hotkey_rebinde"):
			if i != self:
				i.listening = false
				i.set_process_unhandled_key_input(false)
				i.set_text_for_key()
	else:
		set_text_for_key()

# Catch input events when in listening mode
func _input(event: InputEvent) -> void:
	if not listening:
		return

	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		rebind_action_key(event)
		listening = false
		set_process_unhandled_key_input(false)
		set_text_for_key()
		set_action_name()

# Rebind the actual action
func rebind_action_key(event: InputEvent) -> void:
	# Remove all old events for this action
	for old_event in InputMap.action_get_events(action_name):
		InputMap.action_erase_event(action_name, old_event)

	# Add the new event
	InputMap.action_add_event(action_name, event)
