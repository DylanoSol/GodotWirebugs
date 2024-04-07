extends CharacterBody3D

@onready var camerafocus = $camerafocus
@onready var visuals = $visuals
@onready var raycast = $camerafocus/Camera3D/playerraycast
@onready var hudreference : Control = get_node("/root/MHLevel/Hud")
@onready var chargeManagerreference : Node3D = get_node("/root/MHLevel/Hud/ChargeManager")
@onready var crosshairreference : Sprite2D = get_node("/root/MHLevel/Hud/CanvasLayer/Crosshair")
@onready var checker = load("res://WireBugs/TestObjects/SpawnChecker.tscn") 
@onready var jointhelperspawner = load("res://WireBugs/TestObjects/JointBodyHelper.tscn")

const wirebugDistance = Vector3(0, 3, 0)

@export var playernode : CharacterBody3D
@export var IsAiming : bool = false; 
@export var InWirebugAnimation : bool = false; 

var WirebugJoint : JoltGeneric6DOFJoint3D = null;

const SPEED : float = 5.0
const JUMP_VELOCITY : float = 4.5

@export var camera_speed_x : float = 0.5
@export var camera_speed_y : float = 0.5

var debugCounter : int = 0

var currentHangingObject = null; 

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
	# Add debug object to scene
	var objectSpawnOffset = self.global_position + wirebugDistance
	var tempObject = _spawn_debug_object_at_target(objectSpawnOffset)
	
	var helper = jointhelperspawner.instantiate()
	
	add_child(helper)
	
	helper.global_position	= self.global_position
	helper.top_level = true
	
	add_child(tempObject)
	
	tempObject.global_position = self.global_position + wirebugDistance
	tempObject.top_level = true
	
	# Configure joint
	WirebugJoint = JoltGeneric6DOFJoint3D.new()
	
	add_child(WirebugJoint)
	
	WirebugJoint.global_position = tempObject.global_position - Vector3(0, 0.5, 0)
	WirebugJoint.top_level = true; 
	
	var ObjectPath : NodePath = tempObject.get_path()
	var HelperPath : NodePath = helper.get_path()
	
	WirebugJoint.set_node_a(ObjectPath)
	WirebugJoint.set_node_b(HelperPath)

		# Enable constraints on all axes
	WirebugJoint.set_flag_x(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	WirebugJoint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	WirebugJoint.set_flag_z(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)

	# Set linear limits for all axes
	WirebugJoint.set_param_x(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_LOWER, -2)
	WirebugJoint.set_param_x(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_UPPER, 2)
	WirebugJoint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_LOWER, -2)
	WirebugJoint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_UPPER, 2)
	WirebugJoint.set_param_z(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_LOWER, -2)
	WirebugJoint.set_param_z(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_UPPER, 2)

	# Enable damping for all axes
	WirebugJoint.set_param_x(JoltGeneric6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 0.000001)
	WirebugJoint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 0.000001)
	WirebugJoint.set_param_z(JoltGeneric6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 0.000001)
	
	WirebugJoint.enabled = true; 
	WirebugJoint.solver_position_iterations = 10; 
	WirebugJoint.solver_velocity_iterations = 10;
	
	# helper.apply_central_impulse(Vector3(5, 0, 5))
		
func wirebug_launch():
	if (chargeManagerreference.requestCharge()) : 
		if (!raycast.is_colliding()):
			print("Shoot at usual location")
			worldTarget	= raycast.get_global_transform() * raycast.get_target_position()
		else: 
			print("Shoot target at other location")
			worldTarget = raycast.get_collision_point()
			
		# var object = _spawn_debug_object_at_target(worldTarget)
		
		# get_parent().add_child(object)
		
		# Apply some velocity
		launchVector = worldTarget - raycast.get_global_position()
		velocity = launchVector 
		
		print(launchVector)
	
func _spawn_debug_object_at_target(target) -> Node3D :
	
		# Create a debug cube at the location you want.
		var object = checker.instantiate();
		
		object.set_name("Debug" + var_to_str(debugCounter))
		object.set_position(target)
		
		debugCounter = debugCounter + 1
		
		return object
	
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
