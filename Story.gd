extends Node
var _set_progress = JavaScript.create_callback(self, "set_progress")

var progress = 0.0
var palette = [
	Color8(154, 211, 188, 255),
	Color8(243, 234, 194,255),
	Color8(245, 180, 97,255),
	Color8(236, 82, 75,255),
	Color8(109, 164, 170, 255),
	Color8(208, 191, 255, 255),
	Color8(237, 158, 214, 255),
	Color8(246, 215, 118, 255),
	Color8(208, 242, 136, 255),
	Color8(239, 98, 98, 255),
]
var clean_color = Color8(40, 41, 42, 255)
var global_energy = 0.3
var global_timer = 2
var global_glow_intensity = 0
var global_glow_strength = 0
var global_glow_bloom = 0

enum State {
	intro,
	narrator_first
	user_reading,
	read,
	on_white,
	on_sky,
	narrator_second,
}

var current_state = State.intro

func _ready():
	var window = JavaScript.get_interface("window")
	if (window != null):
		window._set_progress = _set_progress
	connect("ready", self, "_on_ready")
	

func _on_ready():
	$Music.play()

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			progress_logic()
			
			
func progress_logic():
	if progress < 50:
		# call once
		print("<50")
		effect()
	elif (progress >= 50 && progress < 75):
		# call once every 300ms
		print(">= 50 && <75")
		if $Timer.is_stopped():
			$Timer.connect("timeout", self, "effect")
			$Timer.start()
		#effect()
	elif (progress >= 75 && progress < 90):
		# call once every 100
		print(">= 75 && <90")
		$Timer.wait_time = 0.5
	else:
		print(progress)
		$Timer.wait_time = 0.2
		
	if progress <= 100:
		progress += 10
		global_energy += 0.01
		global_timer -= 0.1
		global_glow_strength += 0.08
			
func effect():
	var world = get_node("world2")
	var material = world.get_surface_material(0)
	var col = pick_random_color()
	material.albedo_color = col

	var environment = get_node("world/WorldEnvironment").environment
	#environment.background_color = col.darkened(1 - global_energy)
	environment.ambient_light_energy = global_energy
	#environment.glow_bloom = global_glow_bloom
	#environment.glow_intensity = global_glow_intensity
	environment.glow_strength = global_glow_strength
	
	var tween = get_node("Tween")
	tween.stop_all()
	tween.interpolate_property(
		environment,
		"ambient_light_energy",
		environment.ambient_light_energy,
		0.0,
		global_timer,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(
		material,
		"albedo_color",
		material.albedo_color,
		clean_color,
		global_timer,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(
		environment,
		"glow_strength",
		environment.glow_strength,
		0.21,
		global_timer,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	
func to_withe():
	var time_effect = 1.212
	var world = get_node("world2")
	var material = world.get_surface_material(0)
	var col = pick_random_color()
	material.albedo_color = col

	var environment = get_node("world/WorldEnvironment").environment
	#environment.background_mode = Environment.BG_SKY
	
	var tween = get_node("Tween")
	tween.interpolate_property(
		environment,
		"ambient_light_energy",
		environment.ambient_light_energy,
		5.0,
		time_effect,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(
		environment,
		"background_color",
		environment.background_color,
		Color8(255, 255, 255, 255),
		time_effect,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(
		material,
		"albedo_color",
		material.albedo_color,
		Color8(255, 255, 255, 0),
		time_effect,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	tween.start()

func to_world():
	if current_state == State.on_white:
		current_state = State.on_sky
		var time_effect = 1.193
		var world = get_node("world2")
		world.queue_free()
		var environment = get_node("world/WorldEnvironment").environment
		
		
		environment.background_mode =Environment.BG_SKY
		environment.background_sky = ProceduralSky.new()
		environment.background_energy = 5
		var tween = get_node("Tween")
		tween.interpolate_property(
			environment,
			"background_energy",
			environment.background_energy,
			1.0,
			time_effect,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()

func set_progress(args):
	progress = args[0] as int
	print("now progress is: ", progress)
	progress_logic()
	
	
func pick_random_color() -> Color:
	var random_index = randi() % palette.size()
	var random_color = palette[random_index]
	return random_color

func _process(delta):
	# Get the current playback position
	var current_time = $Music.get_playback_position()
	
	if (current_time >= (16 - 12.930) && current_state == State.intro):
		current_state = State.narrator_first
		print("narrator play")
		$First.play()
	
	if ($First.playing == false && current_state == State.narrator_first):
		print("user_reading")
		var window = JavaScript.get_interface("window")
		if (window != null):
			window.user_read(0)
		current_state = State.user_reading
	
	if(progress >= 80 && current_state == State.user_reading):
		print("read!")
		current_state = State.read

	if current_time >= (29.988 - 12.930) && progress < 80 && current_state == State.user_reading:
		$Music.seek(25.058 - 12.930)
		print("user is reading")
		
	if (current_state == State.read && current_time >= (41.715 - 12.930) && current_time <= (42.926 - 12.930)):
		$Timer.stop()
		print("to white")
		to_withe()
		current_state = State.on_white
	if (current_state == State.on_white && (current_time >= (42.927 - 12.930))):
		$Timer.stop()
		to_world()
		print("to world", current_state)
		current_state == State.on_sky
	if (current_state == State.on_sky && current_time >= 44.120 - 12.930):
		current_state = State.narrator_second
		$Music.volume_db = -15
		$Second.play()
	
	#elif current_state == State.read:
		

# intro 0 - 25.058 init 12.930
# 
# unread loop 25.058 - 29.988
# to_white 41.715 - 42.927 Out 42.927 - 44.120 In
# narrator continue
