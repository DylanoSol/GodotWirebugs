extends Node3D

var lifetime : float = 1.
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lifetime -= delta
	if (lifetime < 0): 
		self.queue_free()
	pass
