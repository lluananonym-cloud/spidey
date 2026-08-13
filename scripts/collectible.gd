extends Area3D
class_name DataShard

signal collected

var elapsed := 0.0


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	_build_visual()


func _build_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.4, 0.7, 0.4)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.65, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.0, 0.28, 1.0)
	material.emission_energy_multiplier = 4.0
	material.metallic = 0.35
	mesh.material = material
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0
	collision.shape = shape
	add_child(collision)

	var light := OmniLight3D.new()
	light.light_color = Color(0.0, 0.55, 1.0)
	light.light_energy = 1.3
	light.omni_range = 4.0
	add_child(light)


func _process(delta: float) -> void:
	elapsed += delta
	rotation.y += delta * 1.8
	position.y += sin(elapsed * 2.2) * delta * 0.18


func _on_body_entered(body: Node3D) -> void:
	if body is SpiderHero:
		collected.emit()
		queue_free()