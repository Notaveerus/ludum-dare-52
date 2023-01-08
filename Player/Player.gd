extends KinematicBody2D


export var MAX_SPEED = 200
export var ROLL_SPEED = 400
export var ACCELERATION = 5000
export var FRICTION = 700

export var MAX_HEALTH = 10

enum {
	MOVE,
	ROLL,
	ATTACK
}

var velocity = Vector2.ZERO
var state = MOVE
var roll_vector = Vector2.DOWN
var knockback = Vector2.ZERO
onready var roll_timer = $RollTimer
onready var weapon = $Weapon
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer
onready var hitbox = $HitBox



# Called when the node enters the scene tree for the first time.
func _ready():
	PlayerStats.max_health = MAX_HEALTH
	PlayerStats.health = MAX_HEALTH
	PlayerStats.connect("no_health",self,"queue_free")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	look_at(get_global_mouse_position())
	rotation_degrees += 90	
	knockback = knockback.move_toward(Vector2.ZERO,FRICTION *delta)
	knockback = move_and_slide(knockback)
	match state:
		MOVE:
			move_state(delta)
		ATTACK:
			attack_state(delta)
		ROLL:
			roll_state(delta)

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		roll_vector = (get_global_mouse_position()-position).normalized()
		#swordHitbox.knockback_vector = input_vector		
		velocity = velocity.move_toward(input_vector * MAX_SPEED,ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION*delta)	
	move()
	
	if(Input.is_action_just_pressed("attack")):
		state = ATTACK
	elif(Input.is_action_just_pressed("dodge")):	
		print("Roll")
		roll_vector = (get_global_mouse_position()-position).normalized()	
		state = ROLL
	
func attack_state(_delta):
	#velocity = Vector2.ZERO	
	#weapon.rotation_degrees = -70
	weapon.rotate(deg2rad(800*_delta))
	hitbox.set_deferred("monitorable",true)
	hitbox.set_deferred("monitoring",true)
	hitbox.timer.start(0.5)	
	if(weapon.rotation_degrees >=70):
		weapon.rotation_degrees = -70
		
		state=MOVE
	
	
	
func roll_state(_delta):
	velocity = roll_vector * ROLL_SPEED		
	#hurtbox.start_invincibility(0.5)
	if(roll_timer.time_left<=0):
		roll_vector = (get_global_mouse_position()-position).normalized()
		roll_timer.start(0.5)	
	move()
	
	
func move():
	velocity = move_and_slide(velocity)
	

#Roll Timer
func _on_Timer_timeout():
	roll_vector = (get_global_mouse_position()-position).normalized()
	state = MOVE # Replace with function body.


func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")		


func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")


func _on_Hurtbox_area_entered(area):
	if !hurtbox.invincible:
		knockback = -area.knockback_vector * 300
		PlayerStats.health -= area.damage
		
		hurtbox.start_invincibility(0.6) # Replace with function body.
