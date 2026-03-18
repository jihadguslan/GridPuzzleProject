extends CharacterBody3D

signal tween_finish

enum floor_type{SAFE, BLOCK, DIE, FALL}
enum floor_variant{GRASS, STONE, DIRT, WOOD, METAL}

@onready var dir_node = [$RayPoint/F, $RayPoint/B, $RayPoint/L, $RayPoint/R]
@onready var pivot: Node3D = $Pivot
@onready var rot_guide: Node3D = $RotGuide
@onready var animation_tree: AnimationTree = $AnimationTree

var currently_step = {"type" : 0, "variant" : 0, "pos" : Vector3(0.0,0.0,0.0)}
var state_machine
var ray_length = 0.5
var on_moving = false
var on_fall = false
var speed = 1

func _ready() -> void:
	state_machine = animation_tree["parameters/playback"]

func _physics_process(delta: float) -> void:
	if on_fall:
		velocity.y += get_gravity().y * delta
		move_and_slide()
	
func _input(event: InputEvent) -> void:
	if on_moving: return
	var dir_input = Input.get_vector("Kiri", "Kanan", "Maju", "Mundur")
	if dir_input != Vector2.ZERO :
		currently_step = _hit_ray_to(dir_input)
		_handle_rotation(dir_input)
		_handle_movement()

func _hit_ray_to(dir: Vector2) -> Dictionary:
	var output = {"type" : 0, "variant" : 0, "pos" : Vector3(0.0,0.0,0.0)}
	var space_state = get_world_3d().direct_space_state
	var start = Vector3.ZERO
	match dir :
		Vector2.UP : start = dir_node[0].global_transform.origin
		Vector2.DOWN : start = dir_node[1].global_transform.origin
		Vector2.LEFT : start = dir_node[2].global_transform.origin
		Vector2.RIGHT : start = dir_node[3].global_transform.origin
	
	var end = start + Vector3.DOWN * 0.5
	var query = PhysicsRayQueryParameters3D.create(start, end, 4, [get_rid()])
	
	var result = space_state.intersect_ray(query)
	if result:
		var obj = result.collider
		output.type = obj.type_floor
		output.variant = obj.variant_floor
		output.pos = obj.mid_point.global_position
	else :
		output.type = 3
		output.variant = -1
		output.pos = Vector3(start.x, position.y, start.z)
	return output

func _handle_movement():
	if currently_step.type == floor_type.BLOCK : return
	_make_tween(self, "global_position", currently_step.pos, 0.5 / speed, true)
	on_moving = true
	state_machine.travel("sprint")
	

func _handle_rotation(dir) :
	rot_guide.look_at(transform.origin + Vector3(dir.x, 0.0, dir.y), Vector3.UP)
	var from = pivot.global_rotation.y
	var to = rot_guide.global_rotation.y
	var diff = wrapf(to - from, -PI, PI)
	var final = from + diff
	_make_tween(pivot, "global_rotation:y", final, 0.3 / speed, false)
	
func _make_tween(obj, property, value, duration, send_finsihed: bool):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	if send_finsihed:
		tween.finished.connect(_tween_finished)
	tween.tween_property(obj, property, value, duration)

func _tween_finished():
	emit_signal("tween_finish")
	match currently_step.type:
		floor_type.SAFE : state_machine.travel("idle")
		floor_type.DIE : state_machine.travel("die")
		floor_type.FALL : 
			state_machine.travel("fall")
			on_fall = true
	on_moving = false
