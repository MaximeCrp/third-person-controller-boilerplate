extends CharacterBody3D

@onready var camera_mount = $camera_mount
@onready var animation_player = $visuals/mixamo_base/AnimationPlayer
@onready var visuals = $visuals

const JUMP_VELOCITY = 4.5
const VISUALS_ROTATION_SMOOTHNESS = 10.0

const CAMERA_CLAMP_MIN = deg_to_rad(-90)
const CAMERA_CLAMP_MAX = deg_to_rad(45)

var horizontal_mouse_sensitivity = 0.001
var vertical_mouse_sensitivity = 0.001

var walking_speed = 3.0
var running_speed = 5.0

var speed = walking_speed
var is_running = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * horizontal_mouse_sensitivity)
		visuals.rotate_y(event.relative.x * horizontal_mouse_sensitivity)
		camera_mount.rotate_x(-event.relative.y * vertical_mouse_sensitivity)
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, CAMERA_CLAMP_MIN, CAMERA_CLAMP_MAX)


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_pressed('run'):
		speed = running_speed
		is_running = true
	else:
		speed = walking_speed
		is_running = false

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var visuals_direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction:
		if is_running:
			if animation_player.current_animation != "running":
				animation_player.play("running")
		else:
			if animation_player.current_animation != "walking":
				animation_player.play("walking")

		visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-visuals_direction.x, -visuals_direction.z), delta * VISUALS_ROTATION_SMOOTHNESS)

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
