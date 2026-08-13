extends Node3D
class_name HunterDrone

signal destroyed

var target: Node3D
var orbit_center := Vector3.ZERO
var phase := 0.0
var health := 3
var elapsed := 0.0
var hit_flash := 0.0


func _ready() -> void:
	add_to_group("enemies")
	_build_drone_mesh()


func _build_drone_mesh() -> void:
	var shell := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.52
	sphere.height = 0.72
	sphere.material = _material(Color(0.05, 0.07, 0.13), Color(0.01, 0.03, 0.08))
	shell.mesh = sphere
	add_child(shell)

	var eye := MeshInstance3D.new()
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.16
	eye_mesh.height = 0.24
	eye_mesh.material = _material(Color(0.95, 0.04, 0.08), Color(0.8, 0.0, 0.01), 4.0)
	eye.mesh = eye_mesh
	eye.position = Vector3(0.0, -0.04, -0.48)
	add_child(eye)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.58
	ring_mesh.outer_radius = 0.63
	ring_mesh.material = _material(Color(0.05, 0.35, 0.75), Color(0.0, 0.16, 0.8), 3.0)
	ring.mesh = ring_mesh
	ring.rotation.x = PI * 0.5
	add_child(ring)

	var light := OmniLight3D.new()
	light.light_color = Color(0.95, 0.03, 0.08)
	light.light_energy = 1.6
	light.omni_range = 5.0
	add_child(light)


func _material(albedo: Color, emission: Color, energy := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.3
	material.metallic = 0.7
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material


func _process(delta: float) -> void:
	elapsed += delta
	if target == null:
		return
	var target_position := target.global_position + Vector3.UP * 1.8
	var desired := target_position + orbit_center + Vector3(
		sin(elapsed * 0.75 + phase) * 11.0,
		5.0 + sin(elapsed * 1.7 + phase) * 1.7,
		cos(elapsed * 0.65 + phase) * 11.0
	)
	global_position = global_position.lerp(desired, minf(delta * 2.0, 1.0))
	if global_position.distance_to(target_position) > 0.1:
		look_at(target_position, Vector3.UP)
		hit_flash = maxf(hit_flash - delta, 0.0)
		if global_position.distance_to(target.global_position) < 3.0 and hit_flash <= 0.0:
			if target.has_method("take_damage"):
				target.take_damage(4)
			hit_flash = 1.6


func take_hit(damage: int) -> void:
	health -= damage
	scale = Vector3.ONE * 1.22
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.16)
	if health <= 0:
		destroyed.emit()
		queue_free()