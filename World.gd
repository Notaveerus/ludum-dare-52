extends Node2D

onready var player = $Player
const spider = preload("res://Monsters/Monster.tscn")

func get_spawn():
	var x = 0
	var y = 0
	while(player.global_position.distance_to(Vector2(x,y))<=400):
		x = rand_range(1,800)
		y = rand_range(1,800)
	return Vector2(x,y)

func _on_Monster_death():
	var ent = spider.instance()
	call_deferred("add_child",ent)
	ent.global_position = get_spawn()
	#ent.call_deferred("set_leg_pos")
	ent.connect("death",self, "_on_Monster_death")# Replace with function body.
