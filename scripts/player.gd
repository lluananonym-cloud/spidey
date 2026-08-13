extends CharacterBody3D
class_name SpiderHero

signal swing_started(anchor: Vector3)
signal swing_released
signal attack_landed
signal stats_changed(health: int, combo: int, xp: int)

const MODEL_PATH := "res://assets/models/Spiderman Brand New Day Mask.fbx"
const BODY_ALBEDO_PATH := "res://assets/models/T_HerbalFist_Body_D.png"
const BODY_NORMAL_PATH := "res://assets/models/T_HerbalFist_Body_N.png"
const MASK_ALBEDO_PATH := "res://assets/models/T_HerbalFist_Mask_D.png"
const MASK_NORMAL_PATH := "res://assets/models/T_HerbalFist_Mask_N.png"

var game_world: Node3D
var visual_root: Node3D
var camera: Camera3D
var camera_yaw := 0.0
var camera_pitch := -0.14
var camera_distance := 7.5
var camera_shake := 0.0

var health := 100
var combo := 0
var xp := 0
var sprinting := false
var wall_running := false

var swinging := false
var web_anchor := Vector3.ZERO
var rope_length := 0.0
var swing_time := 0.0
var model_loaded := false

var jump_was_down := false
var web_was_down := false
var attack_was_down := false


func _ready() -> void:
	_build_collision()
	_build_visual()
	_build_camera()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _build_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.36
	var collider := CollisionShape3D.new()
	collider.name = "PlayerCapsule"
	collider.shape = shape
	collider.position.y = 0.9
	add_child(collider)
	collision_layer = 2
	collision_mask = 1


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "BrandNewDaySuit"
	add_child(visual_root)

	var packed := load(MODEL_PATH)
	if packed is PackedScene:
		var imported_model := packed.instantiate()
		visual_root.add_child(imported_model)
		model_loaded = true
		_prepare_imported_suit(imported_model)
	else:
		_build_explicit_suit_fallback()


func _prepare_imported_suit(imported_model: Node) -> void:
	var tallest := 0.0
	for node in imported_model.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node == null:
			continue
		var bounds := mesh_node.get_aabb()
		tallest = maxf(tallest, bounds.size.y * maxf(absf(mesh_node.scale.y), 0.01))
		_apply_suit_materials(mesh_node)

	if tallest > 0.01:
		var uniform_scale := 1.82 / tallest
		if tallest > 20.0:
			uniform_scale *= 0.01
		visual_root.scale = Vector3.ONE * uniform_scale
	visual_root.rotation.y = PI


func _apply_suit_materials(mesh_node: MeshInstance3D) -> void:
	if mesh_node.mesh == null:
		return
	for surface_index in range(mesh_node.mesh.get_surface_count()):
		var source_material := mesh_node.mesh.surface_get_material(surface_index)
		var material: StandardMaterial3D
		if source_material is StandardMaterial3D:
			material = (source_material as StandardMaterial3D).duplicate() as StandardMaterial3D
		else:
			material = StandardMaterial3D.new()
		var material_name := material.resource_name.to_lower()
		var is_mask := material_name.contains("mask") or mesh_node.name.to_lower().contains("mask")
		var albedo_path := MASK_ALBEDO_PATH if is_mask else BODY_ALBEDO_PATH
		var normal_path := MASK_NORMAL_PATH if is_mask else BODY_NORMAL_PATH
		if material.albedo_texture == null:
			material.albedo_texture = load(albedo_path)
		if material.normal_texture == null:
			material.normal_texture = load(normal_path)
			material.normal_enabled = true
		mesh_node.set_surface_override_material(surface_index, material)


func _build_explicit_suit_fallback() -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.35
	capsule.radius = 0.31
	capsule.material = _suit_material(Color(0.06, 0.09, 0.16), Color(0.02, 0.04, 0.08))
	body.mesh = capsule
	body.position.y = 0.92
	visual_root.add_child(body)

	var mask := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.34
	sphere.height = 0.68
	sphere.material = _suit_material(Color(0.62, 0.02, 0.035), Color(0.34, 0.0, 0.01))
	mask.mesh = sphere
	mask.position.y = 1.78
	visual_root.add_child(mask)


func _suit_material(albedo: Color, emission: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.metallic = 0.35
	material.roughness = 0.42
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = 0.7
	return material


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "ChaseCamera"
	camera.current = true
	camera.fov = 72.0
	camera.near = 0.05
	camera.far = 600.0
	add_child(camera)
	_update_camera(1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_yaw -= event.relative.x * 0.0022
		camera_pitch = clampf(camera_pitch - event.relative.y * 0.0018, -0.75, 0.28)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	var web_down := Input.is_key_pressed(KEY_F) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var jump_down := Input.is_key_pressed(KEY_SPACE)
	var attack_down := Input.is_key_pressed(KEY_Q) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if web_down and not web_was_down:
		_try_attach_web()
	elif not web_down and web_was_down and swinging:
		release_web()
	web_was_down = web_down

	if attack_down and not attack_was_down:
		_try_attack()
	attack_was_down = attack_down

	var move_axis := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)

	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := camera.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var wish_direction := (camera_right * move_axis.x + camera_forward * move_axis.y).normalized()

	sprinting = Input.is_key_pressed(KEY_SHIFT) and move_axis.length() > 0.1
	var target_speed := 16.0 if sprinting else 9.0
	if swinging:
		target_speed = 4.0
	if wall_running:
		target_speed = 14.0

	if wish_direction.length_squared() > 0.01:
		var acceleration := 28.0 if is_on_floor() else 12.0
		velocity.x = move_toward(velocity.x, wish_direction.x * target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, wish_direction.z * target_speed, acceleration * delta)
		_face_direction(wish_direction, delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)

	if jump_down and not jump_was_down:
		if is_on_floor():
			velocity.y = 11.5
		elif wall_running:
			_wall_jump()
	jump_was_down = jump_down

	wall_running = _detect_wall_run(wish_direction, jump_down)
	if wall_running:
		velocity.y = maxf(velocity.y, -2.0)
	elif not swinging and not is_on_floor():
		velocity.y -= 24.0 * delta
	elif is_on_floor() and velocity.y < 0.0:
		velocity.y = -0.5

	if swinging:
		_update_swing(delta)

	move_and_slide()
	if swinging:
		_constrain_rope()
	_update_camera(delta)
	_update_animation_pose(delta)
	_update_combo(delta)


func _face_direction(direction: Vector3, delta: float) -> void:
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 12.0, 1.0))


func _detect_wall_run(direction: Vector3, jump_down: bool) -> bool:
	if is_on_floor() or not jump_down or swinging or direction.length_squared() < 0.01:
		return false
	var from := global_position + Vector3.UP * 1.0
	for side in [-1.0, 1.0]:
		var side_direction := global_transform.basis.x * side
		var query := PhysicsRayQueryParameters3D.create(from, from + side_direction * 1.25)
		query.exclude = [self]
		query.collision_mask = 1
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			return true
	return false


func _wall_jump() -> void:
	velocity.y = 12.0
	velocity.x *= 0.45
	velocity.z *= 0.45
	camera_shake = 0.2


func _try_attach_web() -> void:
	if swinging:
		return
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z * 120.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider := hit.get("collider") as Node
	if collider == null or not collider.is_in_group("web_anchor"):
		return
	web_anchor = hit["position"]
	rope_length = maxf(global_position.distance_to(web_anchor), 4.0)
	swing_time = 0.0
	swinging = true
	combo = maxi(combo, 1)
	swing_started.emit(web_anchor)
	stats_changed.emit(health, combo, xp)


func _update_swing(delta: float) -> void:
	swing_time += delta
	var reel_in := Input.is_key_pressed(KEY_Z)
	var reel_out := Input.is_key_pressed(KEY_X)
	if reel_in:
		rope_length = maxf(rope_length - 18.0 * delta, 4.0)
	if reel_out:
		rope_length = minf(rope_length + 18.0 * delta, 70.0)

	var to_anchor := web_anchor - global_position
	var distance := to_anchor.length()
	if distance < 0.1:
		return
	var radial_direction := to_anchor / distance
	var tangent_direction := radial_direction.cross(Vector3.UP).normalized()
	if tangent_direction.length_squared() > 0.01:
		velocity += tangent_direction * (4.0 + sin(swing_time * 2.0) * 1.5) * delta
	velocity.y += 2.0 * delta


func _constrain_rope() -> void:
	var from_anchor := global_position - web_anchor
	var distance := from_anchor.length()
	if distance <= rope_length:
		return
	var rope_direction := from_anchor.normalized()
	global_position = web_anchor + rope_direction * rope_length
	var outward_velocity := velocity.dot(rope_direction)
	if outward_velocity > 0.0:
		velocity -= rope_direction * outward_velocity


func release_web() -> void:
	if not swinging:
		return
	swinging = false
	var launch_direction := (web_anchor - global_position).normalized()
	velocity += launch_direction * 5.0 + Vector3.UP * 6.0
	camera_shake = 0.16
	swing_released.emit()


func _try_attack() -> void:
	var facing := -global_transform.basis.z
	var best_enemy: Node = null
	var best_distance := 11.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var target := enemy as Node3D
		if target == null:
			continue
		var to_enemy := target.global_position - global_position
		var distance := to_enemy.length()
		if distance < best_distance and facing.dot(to_enemy.normalized()) > 0.45:
			best_distance = distance
			best_enemy = enemy
	if best_enemy != null and best_enemy.has_method("take_hit"):
		best_enemy.take_hit(1)
		velocity += facing * 7.0 + Vector3.UP * 2.0
		combo += 1
		xp += 25
		camera_shake = 0.18
		attack_landed.emit()
		stats_changed.emit(health, combo, xp)


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	combo = 0
	camera_shake = 0.35
	stats_changed.emit(health, combo, xp)
	if health <= 0:
		_respawn()


func _respawn() -> void:
	if game_world != null and game_world.has_method("get_spawn_position"):
		global_position = game_world.get_spawn_position()
	health = 100
	velocity = Vector3.ZERO
	swinging = false
	stats_changed.emit(health, combo, xp)


func add_xp(amount: int) -> void:
	xp += amount
	combo += 1
	stats_changed.emit(health, combo, xp)


func _update_camera(delta: float) -> void:
	if camera == null:
		return
	var target := global_position + Vector3.UP * 1.25
	var horizontal := cos(camera_pitch) * camera_distance
	var offset := Vector3(sin(camera_yaw) * horizontal, sin(camera_pitch) * camera_distance + 1.3, cos(camera_yaw) * horizontal)
	var shake := Vector3.ZERO
	if camera_shake > 0.0:
		camera_shake = maxf(camera_shake - delta, 0.0)
		shake = Vector3(sin(Time.get_ticks_msec() * 0.05), cos(Time.get_ticks_msec() * 0.07), 0.0) * camera_shake
	camera.global_position = camera.global_position.lerp(target + offset + shake, minf(delta * 9.0, 1.0))
	camera.look_at(target, Vector3.UP)


func _update_animation_pose(delta: float) -> void:
	if visual_root == null:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	var lean := clampf(speed * 0.018, 0.0, 0.25)
	if swinging:
		lean += 0.16
	visual_root.rotation.x = lerp_angle(visual_root.rotation.x, -lean, minf(delta * 8.0, 1.0))
	visual_root.position.y = sin(Time.get_ticks_msec() * 0.006) * 0.018 if not swinging else sin(swing_time * 8.0) * 0.045


func _update_combo(delta: float) -> void:
	if combo <= 0:
		return
	if velocity.length() < 1.0 and not swinging:
		combo = maxi(combo - (1 if delta > 0.8 else 0), 0)


func get_web_anchor() -> Vector3:
	return web_anchor


func is_web_swinging() -> bool:
	return swinging