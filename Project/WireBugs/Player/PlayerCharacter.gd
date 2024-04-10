extends CharacterBody3D

@onready var camerafocus = $camerafocus
@onready var visuals = $visuals
@onready var raycast = $camerafocus/Camera3D/playerraycast
@onready var hudreference : Control = get_node("/root/MHLevel/Hud")
@onready var chargeManagerreference : Node3D = get_node("/root/MHLevel/Hud/ChargeManager")
@onready var crosshairreference : Sprite2D = get_node("/root/MHLevel/Hud/CanvasLayer/Crosshair")
@onready var checker = load("res://WireBugs/TestObjects/SpawnChecker.tscn") 
@onready var dangletestspawner = load("res://WireBugs/TestObjects/DanglingTest.tscn")
var dangleHelper : Node3D = null; 

var baseWireHangTimer : float = 4.
var wireHangTimer : float = baseWireHangTimer
var wireHangOnCooldown : bool = false; 

var direction : Vector3 = Vector3(0, 0, 0)

var isWireHanging : bool = false;
var danglingBody : RigidBody3D = null; 

const wirebugDistance = Vector3(0, 3, 0)

@export var playernode : CharacterBody3D
@export var IsAiming : bool = false; 
@export var InWirebugAnimation : bool = false; 

var WirebugJoint : JoltConeTwistJoint3D = null;

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

func dangleHelper_delete(): 
	# Clean up any remaining actors
	if (dangleHelper != null): 
		remove_child(dangleHelper)
		dangleHelper.queue_free()
		
		wireHangTimer = baseWireHangTimer
		
		
func wirehang_start(): 
	if (is_on_floor()): 
		wireHangOnCooldown = false; 
	
	if (Input.is_action_just_pressed("WireHang") && !is_on_floor() && !wireHangOnCooldown): 
		dangleHelper_delete()
	
		# Spawn test actor that dangles around
		dangleHelper = dangletestspawner.instantiate()
		add_child(dangleHelper)
		dangleHelper.top_level = true
		dangleHelper.global_position = self.global_position
		
		# Hardcode the path because why not
		danglingBody = dangleHelper.get_child(3)
	
		# Apply impulse that matches player movement
		var appliedVelocity = velocity
		if (velocity.length() > 1): 
			appliedVelocity = velocity.normalized()
			
		danglingBody.apply_central_impulse(velocity.normalized())
		isWireHanging = true
		wireHangTimer = baseWireHangTimer
		wireHangOnCooldown = true; 
		
func wirehang_update(delta): 
	# Make sure the player follows the wirehang
	if (isWireHanging && danglingBody != null): 
		velocity = Vector3(0, 0, 0)
		global_position = danglingBody.global_position - Vector3(0, 1.0, 0)
		
		# Jump off
		if (Input.is_action_just_pressed("ui_accept")): 
			velocity = direction * 4 + Vector3(0, JUMP_VELOCITY * 0.2, 0)
			dangleHelper_delete()
			isWireHanging = false
		
		# Wirehang natural timer 
		wireHangTimer -= delta
		if (wireHangTimer <= 0): 
			dangleHelper_delete()
			isWireHanging = false
			
		if (is_on_floor()):
			dangleHelper_delete()
			isWireHanging = false
			
		
		
func wirebug_launch():
	if (Input.is_action_just_pressed("LaunchWirebug") && IsAiming):
		if (chargeManagerreference.requestCharge()) : 
			if (!raycast.is_colliding()):
				print("Shoot at usual location")
				worldTarget	= raycast.get_global_transform() * raycast.get_target_position()
			else: 
				print("Shoot target at other location")
				worldTarget = raycast.get_collision_point()
		
			# Apply some velocity
			launchVector = worldTarget - raycast.get_global_position()
			velocity = launchVector 
		
			wireHangOnCooldown = false
	
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
	wirebug_launch()
		
	# Wirehang
	wirehang_start() 
	wirehang_update(delta)
		
	move_and_slide()

func player_movement(delta): 
		# Handle jump.
	if (Input.is_action_just_pressed("ui_accept") and is_on_floor()):
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if (direction && is_on_floor()):
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	
	# Only slow down when you are not in an animation and want to stand still. 
	if (!direction && !InWirebugAnimation && is_on_floor()) :
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)	
