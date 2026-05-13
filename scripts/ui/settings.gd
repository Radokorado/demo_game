extends Control

@onready var Graphics = $ColorRect/Graphics
@onready var Sound = $ColorRect/Sound
@onready var Controls = $ColorRect/Controls
@onready var settings_graphics = $ColorRect
#@onready var settings_sound = $sound
@onready var window_mode_select = $ColorRect/Graphics/ScrollContainer/VBoxContainer/window_mode/OptionButton as OptionButton
@onready var resolution = $ColorRect/Graphics/ScrollContainer/VBoxContainer/resolution/OptionButton as OptionButton
#@onready var scalingMode = $"ColorRect/VBoxContainer/ScrollContainer/VBoxContainer/scaling mode/scaling mode"
#@onready var fsr_options = $"ColorRect/VBoxContainer/ScrollContainer/VBoxContainer/scaling mode/fsr options"
@onready var control_node = $ColorRect
@onready var settings = $"."
var inde = 0
var res = null


var music = [[preload("res://materials/audio/song.ogg"), 1]] 
var sfx = [[preload("res://materials/audio/AMBInd_Electrical Power Plant, Hum, Ext_344 Audio_Electromagnetic Design Vol 2.wav"), 1]]


const RESOLUTION_DICTIONARY: Dictionary = {
"1920 x 1080": Vector2i(1920, 1080),
"1280 x 720": Vector2i(1280, 720),
"640 x 360": Vector2i(640, 360),
"800 x 600": Vector2i(800, 600)

}

const WINDOW_MODE_ARRAY : Array[String] = [
	"Full-Screen",
	"Window Mode",
	"Borderless Window",
	"Borderless Full-Screen"
]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esk"):
		self.hide()

func _ready():
	_on_Music([1,1])
	Signals.connect("Music", Callable(self, "_on_Music"))
	#settings_sound.hide()
	window_mode_select.item_selected.connect(on_window_mode_selected)
	resolution.item_selected.connect(on_resolution_selected)
	#scalingMode.item_selected.connect(scaling_mode)
	#fsr_options.item_selected.connect(fsrOptions)
	add_resolution_items()
	add_window_mode_items()
	res = get_window().size	

func _on_Music(temp):
	if temp[0] == 1:
		for m in music:
			if m[1] == temp[1]:
				get_node("music").set_stream(m[0])
				get_node("music").play()
	else:
		for m in sfx:
			if m[1] == temp[1]:
				get_node("sound_effect").set_stream(m[0])
				get_node("sound_effect").play()


func add_window_mode_items():
	for window_mode in WINDOW_MODE_ARRAY:
		window_mode_select.add_item(window_mode)

func add_resolution_items() -> void:
	for resolution_size_text in RESOLUTION_DICTIONARY:
		resolution.add_item(resolution_size_text)

func on_window_mode_selected(index : int) -> void:
	if index < 0 or index >= WINDOW_MODE_ARRAY.size():
		return print("on_window_mode_selected error")
	match index:
		0: # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(res)
			resolution_change()
			centre_window()
		1: # Window Mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(res)
			resolution_change()
			centre_window()
		2:#Borderless Window
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(res)
			resolution_change()
			centre_window()
		3:#Borderless FullScreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(res)
			resolution_change()
			centre_window()

func resolution_change():
	#Signals.emit_signal("Resolution_resize", inde)
	res = RESOLUTION_DICTIONARY.values()[inde]
	var window_mode = DisplayServer.window_get_mode()
	var is_borderless = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)
	if window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN and is_borderless == false:
			#print("FULLSCREEN")
			get_viewport().content_scale_size = RESOLUTION_DICTIONARY.values()[inde]
			match inde:
				0:
					control_node.scale = Vector2(1, 1)
				1:
					control_node.scale = Vector2(0.7, 0.7)
				2:
					control_node.scale = Vector2(0.6, 0.6)
				3:
					control_node.scale = Vector2(0.5, 0.5)
	if window_mode == DisplayServer.WINDOW_MODE_WINDOWED and is_borderless == false:
		#print("WINDOWED")
		DisplayServer.window_set_size(res)
	if window_mode == DisplayServer.WINDOW_MODE_WINDOWED and is_borderless == true:
		#print("borderless WINDOWED")
		DisplayServer.window_set_size(res)
	if window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN and is_borderless == true:
		#print("borderless FULLSCREEN")
		get_viewport().content_scale_size = RESOLUTION_DICTIONARY.values()[inde]
		match inde:
			0:
				control_node.scale = Vector2(1, 1)
			1:
				control_node.scale = Vector2(0.7, 0.7)
			2:
				control_node.scale = Vector2(0.6, 0.6)
			3:
				control_node.scale = Vector2(0.5, 0.5)
		#DisplayServer.window_set_size(RESOLUTION_DICTIONARY.values()[index])
		#var selected_resolution = RESOLUTION_DICTIONARY.values()[index]
		#print("Selected Resolution: ", selected_resolution)  # Print the selected resolution for debugging
	centre_window()

func on_resolution_selected(index : int) -> void:
	inde = index
	#Signals.emit_signal("Resolution_resize", inde)
	res = RESOLUTION_DICTIONARY.values()[index]
	var window_mode = DisplayServer.window_get_mode()
	var is_borderless = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)
	if window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN and is_borderless == false:
		#print("FULLSCREEN")
		get_viewport().content_scale_size = RESOLUTION_DICTIONARY.values()[index]
		match index:
			0:
				control_node.scale = Vector2(1, 1)
			1:
				control_node.scale = Vector2(0.7, 0.7)
			2:
				control_node.scale = Vector2(0.6, 0.6)
			3:
				control_node.scale = Vector2(0.5, 0.5)
	if window_mode == DisplayServer.WINDOW_MODE_WINDOWED and is_borderless == false:
		#print("WINDOWED")
		DisplayServer.window_set_size(res)
	if window_mode == DisplayServer.WINDOW_MODE_WINDOWED and is_borderless == true:
		#print("borderless WINDOWED")
		DisplayServer.window_set_size(res)
	if window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN and is_borderless == true:
		#print("borderless FULLSCREEN")
		get_viewport().content_scale_size = RESOLUTION_DICTIONARY.values()[index]
		match index:
			0:
				control_node.scale = Vector2(1, 1)
			1:
				control_node.scale = Vector2(0.7, 0.7)
			2:
				control_node.scale = Vector2(0.6, 0.6)
			3:
				control_node.scale = Vector2(0.5, 0.5)
	#DisplayServer.window_set_size(RESOLUTION_DICTIONARY.values()[index])
	#var selected_resolution = RESOLUTION_DICTIONARY.values()[index]
	#print("Selected Resolution: ", selected_resolution)  # Print the selected resolution for debugging
	centre_window()

func centre_window():
	var centre_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size()/2
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(centre_screen - window_size/2)
#func scaling_mode(index):
	#var _vieport = get_viewport()
	#match index:
		#1:
			#_vieport.set_scaling_3d_mode(Viewport.SCALING_3D_MODE_BILINEAR)
			#fsr_options.hide()
		#2:
			#_vieport.set_scaling_3d_mode(Viewport.SCALING_3D_MODE_FSR2)
			#fsr_options.show()

func fsrOptions(index):
	match index:
		1:
			get_viewport().set_scaling_3d_scale(0.50)
		2:
			get_viewport().set_scaling_3d_scale(0.59)
		3:
			get_viewport().set_scaling_3d_scale(0.67)
		4:
			get_viewport().set_scaling_3d_scale(0.77)

func _on_vsync_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_graphics_pressed():
	Graphics.show()
	Sound.hide()
	Controls.hide()


func _on_sound_pressed():
	Graphics.hide()
	Sound.show()
	Controls.hide()


func _on_controls_pressed():
	Graphics.hide()
	Sound.hide()
	Controls.show()


func _on_music_finished():
	get_node("music").play()
