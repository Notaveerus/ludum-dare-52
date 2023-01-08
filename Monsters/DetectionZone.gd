extends Area2D

var player = null
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
func can_see_player():
	return player != null

func _on_DetectionZone_body_entered(body):
	player = body # Replace with function body.


func _on_DetectionZone_body_exited(body):
	player = null # Replace with function body.
