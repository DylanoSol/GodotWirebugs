extends CanvasLayer
@onready var crosshair = $Crosshair
@onready var playerref : RigidBody3D = get_node("/root/MHLevel/PlayerCharacter")

var firstFrame = true; 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

