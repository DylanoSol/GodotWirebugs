extends Node3D


@onready var readySymbols = get_tree().get_nodes_in_group("ReadySymbols"); 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func requestCharge() -> bool : 
	for symbol in readySymbols : 
		if (symbol.isOnCooldown) : 
			continue; 
		else :
			symbol.isOnCoolDown = true; 
			return true; 
	return false; 
