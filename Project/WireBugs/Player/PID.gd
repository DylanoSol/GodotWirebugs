extends RefCounted

# From https://www.youtube.com/watch?v=zTp7bWnlicY
class_name Pid3D 

var _p: float 
var _i: float 
var _d: float 

var _prev_error: Vector3 
var _error_integral: Vector3 

func update(error: Vector3, delta: float) -> Vector3: 
	_error_integral += error * delta
	var error_derivative = (error - _prev_error) / delta
	_prev_error = error 
	return _p * error + _i * _error_integral + _d * error_derivative
