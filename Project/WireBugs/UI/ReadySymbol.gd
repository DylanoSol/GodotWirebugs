extends Node

@export var isOnCooldown = false; 
var baseCooldown = 10; 
var cooldown = baseCooldown; 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (isOnCooldown) : 
		self.visible = false; 
		cooldown -= delta; 
		if (cooldown < 0) : 
			isOnCooldown = false; 
			cooldown = baseCooldown; 	
	else : 
		self.visible = true; 
