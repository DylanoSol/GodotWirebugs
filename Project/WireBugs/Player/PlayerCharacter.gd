extends CharacterBody3D
@onready var camerafocus = $camerafocus
@onready var visuals = $visuals

@export var playernode : CharacterBody3D

@export var IsAiming = false; 

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var camera_speed_x = 0.5
@export var camera_speed_y = 0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready(): 
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event): 
	if event is InputEventMouseMotion:
		# x axis mouse movement
		rotate_y(-deg_to_rad(event.relative.x) * camera_speed_x)
		# y axis mouse movement. Do this on the camera focus
		camerafocus.rotate_x(-deg_to_rad(event.relative.y) * camera_speed_y)

func _process(delta): 
	if Input.is_action_pressed("AimMode"):
		IsAiming = true; 
	else:
		IsAiming = false; 
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
