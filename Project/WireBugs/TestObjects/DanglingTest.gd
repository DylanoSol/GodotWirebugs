extends Node3D
@onready var dangling_body = $DanglingBody


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	dangling_body.apply_central_force(Vector3(0, -10, 0))
	pass
