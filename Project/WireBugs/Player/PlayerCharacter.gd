extends RigidBody3D

var _pid : Pid3D = Pid3D.new(1.0, 0.1, 1.0)

@onready var camerafocus = $camerafocus
@onready var visuals = $visuals
@onready var raycast = $camerafocus/Camera3D/playerraycast
@onready var groundraycast = $GroundRayCast

@onready var hudreference : Control = get_node("/root/MHLevel/Hud")
@onready var chargeManagerreference : Node3D = get_node("/root/MHLevel/Hud/ChargeManager")
@onready var crosshairreference : Sprite2D = get_node("/root/MHLevel/Hud/CanvasLayer/Crosshair")
@onready var checker = load("res://WireBugs/TestObjects/SpawnChecker.tscn") 

const wirebugDistance = Vector3(0, 3, 0)

@export var playernode : CharacterBody3D
@export var IsAiming : bool = false; 
@export var InWirebugAnimation : bool = false; 

var WirebugJoint : JoltGeneric6DOFJoint3D = null;

const SPEED : float = 5
const JUMP_VELOCITY : float = 4.5

var velocity : Vector3 = Vector3(0, 0, 0)

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
		
func is_on_floor() -> bool: 
	return (groundraycast.is_colliding())

	
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
	
	add_child(tempObject)
	
	tempObject.global_position = self.global_position + wirebugDistance
	tempObject.top_level = true
	
	# Configure joint
	WirebugJoint = JoltGeneric6DOFJoint3D.new()
	
	add_child(WirebugJoint)
	
	WirebugJoint.global_position = tempObject.global_position - Vector3(0, 0.5, 0)
	WirebugJoint.top_level = true; 
	
	var JointPath : NodePath = WirebugJoint.get_path()
	var PlayerPath : NodePath = get_path()
	
	WirebugJoint.set_node_a(JointPath)
	WirebugJoint.set_node_b(PlayerPath)
	
	print(WirebugJoint.node_a)
	print(WirebugJoint.node_b)
		
func wirebug_launch():
	if (chargeManagerreference.requestCharge()) : 
		if (!raycast.is_colliding()):
			print("Shoot at usual location")
			worldTarget	= raycast.get_global_transform() * raycast.get_target_position()
		else: 
			print("Shoot target at other location")
			worldTarget = raycast.get_collision_point()
			
		var object = _spawn_debug_object_at_target(worldTarget)
		
		get_parent().add_child(object)
		
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
	print(groundraycast.is_colliding())
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else: 
		if (linear_velocity.y < 0): 
			velocity.y = 0
		
	# General Player Movement 
	player_movement(delta)
	
	# Launch Wirebug
	if Input.is_action_just_pressed("LaunchWirebug") && IsAiming:
		wirebug_launch()
		
	# Wirehang
	if Input.is_action_just_pressed("WireHang") && !is_on_floor(): 
		wirehang_start() 
		
	linear_velocity = velocity; 
	print (linear_velocity)
		

func player_movement(delta): 
		# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = (transform.basis * Vector3(Input.get_action_strength("right") - Input.get_action_strength("left"),0, Input.get_action_strength("backward") - Input.get_action_strength("forward"))).normalized().rotated(Vector3.UP, camerafocus.rotation.y)
	
	if direction && is_on_floor():
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	
	# Only slow down when you are not in an animation and want to stand still. 
	if (!direction && !InWirebugAnimation && is_on_floor()) :
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)	
