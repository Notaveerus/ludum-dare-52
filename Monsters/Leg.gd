extends Position2D

const MIN_DIST = 100
const MAX_HEALTH = 3

onready var joint1 = $Joint1
onready var joint2 = $Joint1/Joint2
onready var hand = $Joint1/Joint2/Hand
onready var hitbox = $Joint1/Joint2/HitBox
onready var stats = $Stats
onready var hurtbox = $Joint1/Hurtbox




var len_upper = 0
var len_middle = 0
var len_lower = 0

export var flipped = true

var goal_pos = Vector2()
var int_pos = Vector2()
var start_pos = Vector2()
var step_height = -70
var step_rate = 0.5
var step_time = 0.0

var hitbox_timer = 1


func _ready():
	len_upper = joint1.position.x
	len_middle = joint2.position.x
	len_lower = hand.position.x
	stats.set_max_health(MAX_HEALTH)
	
	
	if !flipped:
		$Sprite.flip_h = true
		joint1.get_node("Sprite").flip_h = true
		joint2.get_node("Sprite").flip_h = true

func step(g_pos):
	if goal_pos == g_pos:
		return
	
	goal_pos = g_pos
	var hand_pos = hand.global_position if hand else global_position
	
	var highest = goal_pos.y
	if hand_pos.y > highest:
		highest = hand_pos.y
	
	var mid = Vector2()
	mid.x = (goal_pos.x + hand_pos.x) / 2.0
	mid.y = (goal_pos.y + hand_pos.y) / 2.0
	
	start_pos = hand_pos
	int_pos = mid
	step_time = 0.0

func attack(pos):	
	goal_pos = pos
	hitbox.knockback_vector = global_position.normalized()
	var hand_pos = hand.global_position if hand else global_position
	hitbox.timer.start(1)
	hitbox.set_deferred("monitorable",true)
	
	var mid = Vector2()
	mid.x = position.x +30
	mid.y = position.y
	
	start_pos = hand_pos
	int_pos = to_global(mid)
	step_time = 0.0
	

func _physics_process(delta):
	if(hitbox_timer>0):
		hitbox_timer -= delta
	
	step_time += delta
	var target_pos = Vector2()
	var t = step_time / step_rate
	if t < 0.5:
		target_pos = start_pos.linear_interpolate(int_pos, t / 0.5)
	elif t < 1.0:
		target_pos = int_pos.linear_interpolate(goal_pos, (t - 0.5) / 0.5)
	else:
		target_pos = goal_pos
	update_ik(target_pos)
	update()

func update_ik(target_pos):
	var offset = target_pos - global_position
	var dis_to_tar = offset.length()
	if dis_to_tar < MIN_DIST:
		offset = (offset / dis_to_tar) * MIN_DIST
		dis_to_tar = MIN_DIST
	
	var base_r = offset.angle()
	var len_total = len_upper + len_middle + len_lower
	var len_dummy_side = (len_upper + len_middle) * clamp(dis_to_tar / len_total, 0.0, 1.0)
	
	var base_angles = SSS_calc(len_dummy_side, len_lower, dis_to_tar)
	var next_angles = SSS_calc(len_upper, len_middle, len_dummy_side)
	
	global_rotation = base_angles.B + next_angles.B + base_r
	if(joint1):
		joint1.rotation = next_angles.C
	if(joint2):
		joint2.rotation = base_angles.C + next_angles.A

func SSS_calc(side_a, side_b, side_c):
	if side_c >= side_a + side_b:
		return {"A": 0, "B": 0, "C": 0}
	var angle_a = law_of_cos(side_b, side_c, side_a)
	var angle_b = law_of_cos(side_c, side_a, side_b) + PI
	var angle_c = PI - angle_a - angle_b
	
	if flipped:
		angle_a = -angle_a
		angle_b = -angle_b
		angle_c = -angle_c
	
	return {"A": angle_a, "B": angle_b, "C": angle_c}

func law_of_cos(a, b, c):
	if 2 * a * b == 0:
		return 0
	return acos( (a * a + b * b - c * c) / ( 2 * a * b) )

#func _draw():	
#	var radius = 20
#	var color = Color(1.0,0.0,0.0)		
#	var center = goal_pos
#	draw_circle(to_local(goal_pos),radius,color)


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(0.6)


func _on_Hurtbox_area_exited(area):
	pass # Replace with function body.


func _on_Stats_no_health():
	joint1.queue_free()
	joint1 = null
	joint2 = null
	hand = null
	PlayerStats.parts_harvested += 1
	
