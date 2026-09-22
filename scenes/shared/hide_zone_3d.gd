@tool
class_name HideZone3D
extends Area3D

## Radius of the sphere zone. Anything with a collision body/area entering it gets faded.
@export_range(0.1, 50.0, 0.1) var radius := 3.0:
	set(value):
		radius = value
		if sphere_shape:
			sphere_shape.radius = radius

## How transparent affected meshes become while inside the zone (0 = fully invisible,
## 1 = fully opaque / no visible effect).
@export_range(0.0, 1.0) var transparency_alpha := 0.15

## This node, and everything under it, is skipped entirely and stays fully opaque even if
## it's inside the zone — e.g. the racer the zone was placed around to reveal, so the zone
## doesn't fade it out along with whatever's covering it.
@export var excluded_node: Node3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
var sphere_shape: SphereShape3D

# Original surface_override_material per affected MeshInstance3D, keyed by surface index,
# so exiting the zone restores exactly what was there before rather than guessing.
var _original_materials: Dictionary[MeshInstance3D, Array] = {}

func _ready() -> void:
	sphere_shape = collision_shape_3d.shape as SphereShape3D
	if sphere_shape == null:
		sphere_shape = SphereShape3D.new()
		collision_shape_3d.shape = sphere_shape
	sphere_shape.radius = radius

	if Engine.is_editor_hint():
		return

	# Local-only effect: e.g. when this zone is a descendant of a specific racer (revealing
	# them through nearby scenery for their own camera), that racer's whole scene — including
	# this zone — gets structurally replicated to every peer. Without this check, every peer's
	# own local physics would independently detect the same overlap (world geometry and racer
	# positions are effectively synced everywhere) and fade their own copy of the scenery too,
	# which looked like the effect was shared even though nothing was actually networked.
	if !MultiplayerHandler.is_authority_or_offline(self):
		monitoring = false
		return

	monitorable = false
	body_entered.connect(_on_something_entered)
	body_exited.connect(_on_something_exited)
	area_entered.connect(_on_something_entered)
	area_exited.connect(_on_something_exited)

func _on_something_entered(node: Node3D) -> void:
	for mesh_instance: MeshInstance3D in _find_mesh_instances(node):
		_fade_out(mesh_instance)

func _on_something_exited(node: Node3D) -> void:
	for mesh_instance: MeshInstance3D in _find_mesh_instances(node):
		_restore(mesh_instance)

func _find_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	_collect_mesh_instances(root, found)
	return found

func _collect_mesh_instances(node: Node, found: Array[MeshInstance3D]) -> void:
	if node == excluded_node:
		return
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		_collect_mesh_instances(child, found)

func _fade_out(mesh_instance: MeshInstance3D) -> void:
	if _original_materials.has(mesh_instance):
		return # Already tracked (e.g. re-entered before fully exiting)

	var mesh := mesh_instance.mesh
	if mesh == null:
		return

	var originals: Array[Material] = []
	for surface_index in mesh.get_surface_count():
		var original := mesh_instance.get_surface_override_material(surface_index)
		originals.append(original)

		var base_material := original if original else mesh.surface_get_material(surface_index)
		var faded_material := _make_faded_copy(base_material)
		if faded_material:
			mesh_instance.set_surface_override_material(surface_index, faded_material)

	_original_materials[mesh_instance] = originals

func _restore(mesh_instance: MeshInstance3D) -> void:
	var originals: Array = _original_materials.get(mesh_instance, [])
	for surface_index in originals.size():
		mesh_instance.set_surface_override_material(surface_index, originals[surface_index])
	_original_materials.erase(mesh_instance)

func _make_faded_copy(material: Material) -> Material:
	if !(material is BaseMaterial3D):
		return null # Custom shaders aren't generically fadeable this way; leave them alone

	var faded := (material as BaseMaterial3D).duplicate() as BaseMaterial3D
	faded.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	faded.albedo_color.a = transparency_alpha
	return faded
