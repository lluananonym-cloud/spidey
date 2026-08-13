extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const DRONE_SCRIPT = preload("res://scripts/drone.gd")
const SHARD_SCRIPT = preload("res://scripts/collectible.gd")
const HUD_SCRIPT = preload("res://scripts/hud.gd")

var player: SpiderHero
var hud: SpiderHUD
var rope_mesh: MeshInstance3D
var rope_draw: ImmediateMesh
var mission_beacon := Vector3(58.0, 16.0, -46.0)
var mission_stage := 0
var collected_shards := 0
var total_shards := 8
var spawn_position := Vector3(0.0, 2.0, 24.0)
var city_materials: Array[StandardMaterial3D] = []
var beacon_pulse := 0.0
var world_time := 0.0


func _ready() -> void:
	_build_environment()
	_build_city()
	_build_beacon()
	_spawn_shards()

	player = PLAYER_SCRIPT.new()
	player.name = "SpiderMan"
	player.game_world = self
	player.global_position = spawn_position
	add_child(player)
	player.stats_changed.connect(_on_player_stats_changed)

	_spawn_drones(6)
	_build_rope_renderer()

	hud = HUD_SCRIPT.new()
	add_child(hud)
	hud.flash_message("MISSION START  //  FIND THE MIDTOWN BEACON")


func get_spawn_position() -> Vector3:
	return spawn_position


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.008, 0.02, 0.09)
	sky_material.sky_horizon_color = Color(0.18, 0.035, 0.14)
	sky_material.ground_bottom_color = Color(0.008, 0.008, 0.02)
	sky_material.ground_horizon_color = Color(0.12, 0.025, 0.08)
	sky_material.sun_angle_max = 8.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.04, 0.06, 0.16)
	environment.fog_light_energy = 0.35
	environment.fog_density = 0.006
	world_environment.environment = environment
	add_child(world_environment)

	var moon := DirectionalLight3D.new()
	moon.name = "Moonlight"
	moon.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	moon.light_color = Color(0.34, 0.48, 1.0)
	moon.light_energy = 1.2
	moon.shadow_enabled = true
	add_child(moon)


func _build_city() -> void:
	var ground := StaticBody3D.new()
	ground.name = "MidtownGround"
	ground.add_to_group("web_anchor")
	add_child(ground)
	var ground_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(260.0, 1.0, 260.0)
	plane.material = _material(Color(0.018, 0.025, 0.055), Color(0.005, 0.01, 0.04), 0.15)
	ground_mesh.mesh = plane
	ground_mesh.position.y = -0.5
	ground.add_child(ground_mesh)
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(260.0, 1.0, 260.0)
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.5
	ground.add_child(ground_collision)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1947
	var building_index := 0
	for grid_x in range(-6, 7):
		for grid_z in range(-6, 7):
			if abs(grid_x) <= 1 and abs(grid_z) <= 1:
				continue
			if (grid_x + grid_z) % 3 == 0:
				continue
			var width := rng.randf_range(7.0, 11.0)
			var depth := rng.randf_range(7.0, 11.0)
			var height := rng.randf_range(7.0, 24.0)
			var center := Vector3(grid_x * 17.0, height * 0.5, grid_z * 17.0)
			_spawn_building(building_index, center, Vector3(width, height, depth), rng)
			building_index += 1

	_build_road(Vector3(0.0, 0.02, 0.0), Vector3(232.0, 0.08, 12.0))
	_build_road(Vector3(0.0, 0.03, 0.0), Vector3(12.0, 0.09, 232.0))


func _spawn_building(index: int, center: Vector3, size: Vector3, rng: RandomNumberGenerator) -> void:
	var building := StaticBody3D.new()
	building.name = "WebAnchorBuilding_%02d" % index
	building.position = center
	building.add_to_group("web_anchor")
	add_child(building)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var base_color := Color.from_hsv(rng.randf_range(0.57, 0.68), rng.randf_range(0.28, 0.52), rng.randf_range(0.18, 0.38))
	box.material = _material(base_color, base_color * 0.22, 0.18)
	mesh_instance.mesh = box
	building.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	building.add_child(collision)

	var strips := 2 + int(rng.randi_range(0, 2))
	for strip_index in range(strips):
		var window_strip := MeshInstance3D.new()
		var strip := BoxMesh.new()
		strip.size = Vector3(size.x * 0.62, 0.13, 0.06)
		var neon_color := Color(0.02, 0.36, 0.95) if strip_index % 2 == 0 else Color(0.95, 0.04, 0.28)
		strip.material = _material(neon_color, neon_color, 3.0)
		window_strip.mesh = strip
		window_strip.position = Vector3(0.0, -size.y * 0.34 + strip_index * size.y * 0.28, size.z * 0.5 + 0.04)
		building.add_child(window_strip)

	var roof_light := OmniLight3D.new()
	roof_light.light_color = Color(0.1, 0.35, 1.0) if index % 2 == 0 else Color(1.0, 0.06, 0.18)
	roof_light.light_energy = 1.3
	roof_light.omni_range = 9.0
	roof_light.position.y = size.y * 0.5 + 0.6
	building.add_child(roof_light)


func _build_road(position: Vector3, size: Vector3) -> void:
	var road := MeshInstance3D.new()
	var road_mesh := BoxMesh.new()
	road_mesh.size = size
	road_mesh.material = _material(Color(0.012, 0.015, 0.028), Color(0.0, 0.0, 0.0), 0.0)
	road.mesh = road_mesh
	road.position = position
	add_child(road)
	for line_index in range(-8, 9):
		var line := MeshInstance3D.new()
		var mark := BoxMesh.new()
		mark.size = Vector3(4.0, 0.02, 0.09) if size.x > size.z else Vector3(0.09, 0.02, 4.0)
		mark.material = _material(Color(0.55, 0.7, 0.86), Color(0.1, 0.25, 0.65), 1.2)
		line.mesh = mark
		line.position = position + (Vector3(line_index * 12.0, 0.06, 0.0) if size.x > size.z else Vector3(0.0, 0.06, line_index * 12.0))
		add_child(line)


func _build_beacon() -> void:
	var beacon := Node3D.new()
	beacon.name = "MidtownBeacon"
	beacon.position = mission_beacon
	add_child(beacon)

	var pillar := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.18
	cylinder.bottom_radius = 0.42
	cylinder.height = 5.0
	cylinder.material = _material(Color(0.08, 0.42, 0.9), Color(0.0, 0.2, 1.0), 3.0)
	pillar.mesh = cylinder
	pillar.position.y = -2.5
	beacon.add_child(pillar)

	var beacon_ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.9
	sphere.height = 1.8
	sphere.material = _material(Color(0.95, 0.08, 0.24), Color(0.9, 0.02, 0.08), 6.0)
	beacon_ball.mesh = sphere
	beacon_ball.position.y = 0.15
	beacon.add_child(beacon_ball)

	var light := OmniLight3D.new()
	light.name = "BeaconLight"
	light.light_color = Color(0.95, 0.08, 0.22)
	light.light_energy = 5.0
	light.omni_range = 24.0
	light.position.y = 0.2
	beacon.add_child(light)


func _spawn_shards() -> void:
	var shard_positions := [
		Vector3(-42.0, 10.0, -35.0),
		Vector3(28.0, 17.0, -10.0),
		Vector3(-18.0, 13.0, 52.0),
		Vector3(63.0, 22.0, 16.0),
		Vector3(-65.0, 18.0, 38.0),
		Vector3(44.0, 12.0, 55.0),
		Vector3(-50.0, 25.0, -62.0),
		Vector3(75.0, 19.0, -70.0)
	]
	for shard_position in shard_positions:
		var shard: DataShard = SHARD_SCRIPT.new()
		shard.position = shard_position
		shard.collected.connect(_on_shard_collected)
		add_child(shard)


func _spawn_drones(amount: int) -> void:
	for index in range(amount):
		var drone: HunterDrone = DRONE_SCRIPT.new()
		drone.name = "HunterDrone_%02d" % index
		drone.target = player
		drone.orbit_center = Vector3(0.0, 0.0, 0.0)
		drone.phase = float(index) * 1.7
		drone.global_position = player.global_position + Vector3(index * 3.0 - 8.0, 8.0, -12.0)
		drone.destroyed.connect(_on_drone_destroyed)
		add_child(drone)


func _build_rope_renderer() -> void:
	rope_mesh = MeshInstance3D.new()
	rope_mesh.name = "WebLine"
	rope_draw = ImmediateMesh.new()
	rope_mesh.mesh = rope_draw
	add_child(rope_mesh)


func _process(delta: float) -> void:
	world_time += delta
	beacon_pulse += delta
	_update_rope()
	_update_mission()
	if hud != null and player != null:
		hud.update_state(
			player.health,
			player.combo,
			player.xp,
			_current_objective(),
			_mission_progress(),
			get_tree().get_nodes_in_group("enemies").size(),
			collected_shards,
			player.is_web_swinging(),
			player.model_loaded
		)


func _update_rope() -> void:
	if rope_draw == null or player == null or not player.is_web_swinging():
		if rope_draw != null:
			rope_draw.clear_surfaces()
		return
	var material := _material(Color(0.92, 0.96, 1.0), Color(0.5, 0.72, 1.0), 2.0)
	rope_draw.clear_surfaces()
	rope_draw.surface_begin(Mesh.PRIMITIVE_LINES, material)
	rope_draw.surface_add_vertex(player.global_position + Vector3(0.0, 1.48, 0.0))
	rope_draw.surface_add_vertex(player.get_web_anchor())
	rope_draw.surface_end()


func _update_mission() -> void:
	if player == null:
		return
	if mission_stage == 0 and player.global_position.distance_to(mission_beacon) < 7.0:
		mission_stage = 1
		_spawn_drones(4)
		player.add_xp(250)
		hud.flash_message("BEACON SYNCHRONIZED  //  HUNTER WAVE INBOUND")
	elif mission_stage == 1 and get_tree().get_nodes_in_group("enemies").size() == 0:
		mission_stage = 2
		player.add_xp(500)
		hud.flash_message("MIDTOWN SECURED  //  FREE ROAM UNLOCKED")


func _current_objective() -> String:
	if mission_stage == 0:
		return "Reach the Midtown beacon"
	if mission_stage == 1:
		return "Clear the incoming hunter wave"
	return "Free roam  //  collect every data shard"


func _mission_progress() -> float:
	if mission_stage == 0:
		return clampf(1.0 - player.global_position.distance_to(mission_beacon) / 90.0, 0.0, 1.0)
	if mission_stage == 1:
		return 1.0 - float(get_tree().get_nodes_in_group("enemies").size()) / 10.0
	return float(collected_shards) / float(total_shards)


func _on_shard_collected() -> void:
	collected_shards += 1
	player.add_xp(100)
	hud.flash_message("DATA SHARD RECOVERED  //  +100 XP")


func _on_drone_destroyed() -> void:
	if player != null:
		player.add_xp(75)


func _on_player_stats_changed(_health: int, _combo: int, _xp: int) -> void:
	pass


func _material(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.68
	material.metallic = 0.22
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material