extends KinematicBody2D

onready var right_check = $RightCheck
onready var left_check = $LeftCheck

onready var right_legs = $FrontLegs.get_children()#[$FrontLegs/Leg,$FrontLegs/Leg2,$FrontLegs/Leg3,$FrontLegs/Leg4]
onready var left_legs = $BackLegs.get_children()#[$BackLegs/Leg8,$BackLegs/Leg7,$BackLegs/Leg6,$BackLegs/Leg5]

onready var detectionZone = $DetectionZone
onready var wanderController = $WanderController
onready var stats = $Stats
onready var hurtbox = $Hurtbox

var points = []
 
export var ACCELERATION = 300
export var MAX_SPEED = 100.0
export var FRICTION = 200
export var ROTATION_SPEED = 0.5
export var MAX_LEGS = 8.0

export var MAX_HEALTH = 10
signal death()



enum {
	IDLE,
	WANDER,
	CHASE
}

var state = IDLE
var move_vec = Vector2()
var velocity = Vector2.ZERO

var leg_count = MAX_LEGS
var currSpeed = MAX_SPEED
var step_rate = 1.0/(currSpeed/10.0)
var time_since_last_step = 0
var cur_f_leg = 0
var cur_b_leg = 0
var use_front = false

var attacking = false
var attacking_leg = null
var attack_cooldown = 3
 
func _ready():
	set_leg_pos()
	stats.max_health = MAX_HEALTH
	stats.health = MAX_HEALTH
	for i in range(8):
		step()
 
func _physics_process(delta):
	if(left_legs[0].position.distance_to(position)<=5):
		set_leg_pos()
#	move_vec = global_position.direction_to(get_global_mouse_position()).normalized()
#	move_and_collide(move_vec * delta * speed)
#	update()
	if(attack_cooldown>0):
		attack_cooldown -= delta
	currSpeed = MAX_SPEED * (leg_count/MAX_LEGS)	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
			if wanderController.get_time_left() == 0:
					update_state()
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0:
				update_state()
			accelerate_towards(wanderController.target_position,delta)
			turn(wanderController.target_position,delta)
			#global_rotation_degrees +=90
			if(global_position.distance_to(wanderController.target_position)<=30):
				update_state()
		CHASE:
			var player = detectionZone.player
			if(player != null):
				turn(player.global_position,delta)	
				var player_dist = global_position.distance_to(player.global_position)			
				if(player_dist<=200 && player_dist > 110):					
					velocity  = velocity.move_toward(Vector2.ZERO,FRICTION*delta)		
					if(attack_cooldown <= 0):		
						attack(player.global_position)
						attacking = true
				elif(player_dist <110):
					var direction = global_position.direction_to(player.global_position)
					velocity = velocity.move_toward(direction * -currSpeed, ACCELERATION*delta) 	
				else:
					accelerate_towards(player.global_position,delta)
			else:
				state = IDLE
	velocity = move_and_slide(velocity)
	move_vec = velocity.normalized()
			
 
func _process(delta):	
	#global_rotation += deg2rad(90)
	time_since_last_step += delta
	if time_since_last_step >= step_rate:
		time_since_last_step = 0
		step()

func accelerate_towards(pos,delta):
	var direction = global_position.direction_to(pos)
	velocity = velocity.move_toward(direction * currSpeed, ACCELERATION*delta) 
	
func update_state():
	state = pick_random_state([IDLE,WANDER])
	wanderController.set_wander_timer(rand_range(1,3))
	
func seek_player():
	if(detectionZone.can_see_player()):
		state = CHASE

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func turn(pos,delta):
	var direction = (pos - global_position)
	var angleTo = transform.x.angle_to(direction)
	rotate(sign(angleTo+deg2rad(-90)) * min(delta * ROTATION_SPEED, abs(angleTo+deg2rad(-90))))

func attack(pos):
	attacking_leg = find_closest_leg(pos)
	if(!attacking && attacking_leg):
		attacking_leg.goal_pos = Vector2()
		attacking_leg.attack(pos)
	
func find_closest_leg(pos):
	var closest_leg = null
	var dist = 0
	for leg in left_legs:
		if(!leg.joint1):
			continue
		var new_dist = leg.global_position.distance_to(pos)
		if(dist>0):
			if(dist< new_dist):
				continue
			else:
				dist = new_dist
				closest_leg = leg
		else:
			dist = new_dist
			closest_leg = leg
	for leg in right_legs:
		if(!leg.joint1):
			continue
		var new_dist = leg.global_position.distance_to(pos)
		if(dist>0):
			if(dist< new_dist):
				continue
			else:
				dist = new_dist
				closest_leg = leg
		else:
			dist = new_dist
			closest_leg = leg
	return closest_leg	

func step():
	var leg = null
	var sensor = null	
	if use_front:
		if(right_legs.size() > 0):
			leg = right_legs[cur_f_leg]
			cur_f_leg += 1
			cur_f_leg %= right_legs.size()		
			if(leg.joint1 == null):
				leg_count-=1
				right_legs.erase(leg)				
				cur_f_leg = 0	
	else:
		if(left_legs.size() > 0):
			leg = left_legs[cur_b_leg]		
			cur_b_leg += 1
			cur_b_leg %= left_legs.size()
			if(leg.joint1 == null):
				leg_count-=1
				left_legs.erase(leg)
				cur_b_leg = 0		
	
	
	use_front = !use_front 	
	if(!leg):
		return
	elif(attacking && attacking_leg && leg.position == attacking_leg.position):		
		if(leg.global_position.distance_to(leg.goal_pos)<10 || leg.global_position.distance_to(leg.goal_pos)>100):
			attacking=false
			attacking_leg = null
			leg.hitbox_timer = 2.0
			attack_cooldown = 3
		else:
			return
	else:
		sensor = find_sensor(leg.global_position, 175)
		var target = sensor	
		leg.step(target)

func find_sensor(pos,dist):
	
	var dir = Vector2()
	var angle = global_position.direction_to(pos)
	var offset = dist - (global_position.distance_to(pos))
	dir = global_position + angle*offset + move_vec *(offset/2)
	
	points.append(dir)
	
	return dir

func set_leg_pos():
	var left_angle = deg2rad(120/left_legs.size())
	var curr_angle = left_angle-deg2rad(235)
	for leg in left_legs:
		var angle = position.rotated(curr_angle).normalized()
		leg.flipped = true		
		leg.position = angle*25
		curr_angle += left_angle
	var right_angle = deg2rad((120/left_legs.size()))
	curr_angle = right_angle-deg2rad(30)
	for leg in right_legs:
		var angle = position.rotated(curr_angle).normalized()
		leg.position = angle*25		
		curr_angle += right_angle
		
	pass
	
func _draw():
	
	for i in points:
		var radius = 20
		var color = Color(1.0,0.0,0.0)		
		var center = i
		
		#draw_circle(to_local(center),radius,color)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage	
	hurtbox.start_invincibility(0.6)


func _on_Hurtbox_area_exited(area):
	pass # Replace with function body.


func _on_Stats_no_health():
	emit_signal("death")
	queue_free() # Replace with function body.
