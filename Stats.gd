extends Node

export var max_health = 1 setget set_max_health
var health = max_health setget set_health 
var parts_harvested = 0 setget set_parts

signal no_health
signal health_changed(value)
signal max_health_changed(value)
signal parts_harvested_changed(value)

func set_health(value):
	health = value
	emit_signal("health_changed",health)
	if(health <= 0):
		emit_signal("no_health")

func set_max_health(value):
	max_health = value
	self.health = min(health, max_health)
	emit_signal("max_health_changed",max_health)

func set_parts(value):
	parts_harvested = value
	emit_signal("parts_harvested_changed",value)

func _ready():
	self.health = max_health


func _on_Stats_no_health():
	pass # Replace with function body.
