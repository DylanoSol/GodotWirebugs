extends CharacterBody3D

@onready var camerafocus = $camerafocus
@onready var visuals = $visuals
@onready var raycast = $camerafocus/Camera3D/playerraycast
@onready var hudreference : Control = get_node("/root/MHLevel/Hud")
@onready var chargeManagerreference : Node3D = get_node("/root/MHLevel/Hud/ChargeManager")
@onready var crosshairreference : Sprite2D = get_node("/root/MHLevel/Hud/CanvasLayer/Crosshair")

const wirebugDistance = Vector3(0, 3, 0)

@export var playernode : CharacterBody3D
@export var IsAiming = false; 
@export var InWirebugAnimation = false; 

var WirebugJoint = 	JoltGeneric6DOFJoint3D.new()

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var camera_speed_x = 0.5
@export var camera_speed_y = 0.5

var debugCounter = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var launchVector = Vector3(0, 0, 0)
var worldTarget = Vector3(0, 0, 0)

func _ready(): 
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event): 
	if event is InputEventMouseMotion:
		# x axis mouse movement
		rotate_y(-deg_to_rad(event.relative.x) * camera_speed_x)
		# y axis mouse movement. Do this on the camera focus
		camerafocus.rotate_x(-deg_to_rad(event.relative.y) * camera_speed_y)

func _process(delta): 
	handle_player_aim()
	
func handle_player_aim(): 
	if Input.is_action_pressed("AimMode"):
		IsAiming = true; 
	else:
		IsAiming = false; 
		
	if (IsAiming) : 
		crosshairreference.visible = true; 
	else: 
		crosshairreference.visible = false; 

func wirehang_start(): 
	var objectSpawnOffset = self.position + wirebugDistance; 
	_spawn_debug_object_at_target(objectSpawnOffset)
	pass
		
func wirebug_launch():
	if (chargeManagerreference.requestCharge()) : 
		if (!raycast.is_colliding()):
			print("Shoot at usual location")
			worldTarget	= raycast.get_global_transform() * raycast.get_target_position()
		else: 
			print("Shoot target at other location")
			worldTarget = raycast.get_collision_point()
			
		_spawn_debug_object_at_target(worldTarget)
		
		# Apply some velocity
		launchVector = worldTarget - raycast.get_global_position()
		velocity = launchVector 
		
		print(launchVector)
	
func _spawn_debug_object_at_target(target): 
			# Create a debug cube at the location you want. 
		var checker = load("res://WireBugs/TestObjects/SpawnChecker.tscn") 
		var object = checker.instantiate();
		object.set_name("Debug" + var_to_str(debugCounter))
		object.set_position(target)
		get_parent().add_child(object)

		debugCounter = debugCounter + 1
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# General Player Movement 
	player_movement(delta)
	
	# Launch Wirebug
	if Input.is_action_just_pressed("LaunchWirebug") && IsAiming:
		wirebug_launch()
		
	# Wirehang
	if Input.is_action_just_pressed("WireHang") && !is_on_floor(): 
		wirehang_start() 
		
	move_and_slide()

func player_movement(delta): 
		# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction && is_on_floor():
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	
	# Only slow down when you are not in an animation and want to stand still. 
	if (!direction && !InWirebugAnimation && is_on_floor()) :
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)	
