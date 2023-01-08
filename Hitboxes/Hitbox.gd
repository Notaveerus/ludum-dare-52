extends Area2D

export var damage = 1
var knockback_vector = Vector2.ZERO

onready var timer = $Timer


func _on_Timer_timeout():
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	 # Replace with function body.
