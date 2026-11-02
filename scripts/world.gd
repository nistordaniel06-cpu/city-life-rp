extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var movement := Vector2.ZERO
var left_id := -1
var right_id := -1
var origin := Vector2.ZERO
var yaw := 0.0
var pitch := -0.2

func _ready() -> void:
	_build_city()
	_build_player()
	_build_hud()

func _cube(pos: Vector3, size: Vector3, tint: Color, solid := true) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	mesh.material_override = material
	mesh.position = pos
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		mesh.add_child(body)
		var shape := CollisionShape3D.new()
		var collision := BoxShape3D.new()
		collision.size = size
		shape.shape = collision
		body.add_child(shape)

func _build_city() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.73, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 0.9)
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -25, 0)
	add_child(sun)
	_cube(Vector3(0, -0.6, 0), Vector3(150, 1, 150), Color(0.25, 0.33, 0.26))
	_cube(Vector3(0, -0.04, 0), Vector3(13, 0.07, 140), Color(0.13, 0.14, 0.16), false)
	_cube(Vector3(0, -0.03, 0), Vector3(140, 0.07, 13), Color(0.13, 0.14, 0.16), false)
	for i in range(-7, 8):
		if abs(i) > 1:
			_cube(Vector3(0, 0.01, i * 9), Vector3(0.2, 0.02, 3.5), Color(0.95, 0.84, 0.45), false)
			_cube(Vector3(i * 9, 0.01, 0), Vector3(3.5, 0.02, 0.2), Color(0.95, 0.84, 0.45), false)
	for x in [-32, -19, 19, 32]:
		for z in [-38, -24, 24, 38]:
			var height := float(10 + ((abs(x) + abs(z)) % 14))
			_cube(Vector3(x, height / 2.0, z), Vector3(9, height, 10), Color(0.38, 0.41, 0.45))
			for floor_no in range(2, int(height) - 1, 3):
				_cube(Vector3(x, floor_no + 0.5, z - 5.02), Vector3(6, 1, 0.04), Color(0.24, 0.49, 0.64), false)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 2, 12)
	add_child(player)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.4
	shape.shape = capsule
	player.add_child(shape)
	var mesh := MeshInstance3D.new()
	var model := CapsuleMesh.new()
	model.height = 1.8
	model.radius = 0.4
	mesh.mesh = model
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.25, 0.48)
	mesh.material_override = mat
	player.add_child(mesh)
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "CITY LIFE RP | V1 OFFLINE | LEFT MOVE / RIGHT LOOK"
	label.position = Vector2(24, 24)
	label.add_theme_font_size_override("font_size", 22)
	layer.add_child(label)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x / 2.0 and left_id == -1:
				left_id = event.index
				origin = event.position
			elif right_id == -1:
				right_id = event.index
		else:
			if event.index == left_id:
				left_id = -1
				movement = Vector2.ZERO
			if event.index == right_id:
				right_id = -1
	if event is InputEventScreenDrag:
		if event.index == left_id:
			movement = ((event.position - origin) / 85.0).limit_length(1.0)
		elif event.index == right_id:
			yaw -= event.relative.x * 0.005
			pitch = clamp(pitch - event.relative.y * 0.004, -0.8, 0.4)

func _physics_process(delta: float) -> void:
	var keys := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_dir := movement if movement.length() > 0.05 else keys
	var dir := Basis(Vector3.UP, yaw) * Vector3(input_dir.x, 0, input_dir.y)
	player.velocity.x = dir.x * 6.0
	player.velocity.z = dir.z * 6.0
	if not player.is_on_floor():
		player.velocity.y -= 20.0 * delta
	else:
		player.velocity.y = -0.1
	player.move_and_slide()
	if dir.length() > 0.1:
		player.rotation.y = atan2(-dir.x, -dir.z)
	var offset := Basis(Vector3.UP, yaw) * Vector3(0, 2.6 + sin(-pitch) * 3.0, 5.5 * cos(pitch))
	camera.global_position = camera.global_position.lerp(player.global_position + offset, min(1.0, delta * 10.0))
	camera.look_at(player.global_position + Vector3.UP * 1.1)
