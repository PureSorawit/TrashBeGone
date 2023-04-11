extends KinematicBody2D

const MAX_SPEED = 80

enum {
	IDLE,
	WANDERING,
	CHASING
}

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO
var state = IDLE
onready var stats = $Stats
onready var DetectionZone = $DectectionZone
onready var _pika_drop = preload("res://Item/Key2Drop.tscn")
onready var softCollision = $SoftCollision
onready var wanderController = $WanderingController
onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var animationTimer = $Timer

func _ready():
	animationTree.active = true
	state_change([IDLE, WANDERING])

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, 600 * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = Vector2.ZERO
			chase_player()
			if wanderController.get_time_left() == 0:
				state = state_change([IDLE, WANDERING])
				wanderController.start_wandering_timer(rand_range(1, 4))
		WANDERING:
			chase_player()
			if wanderController.get_time_left() == 0:
				state = state_change([IDLE, WANDERING])
				wanderController.start_wandering_timer(rand_range(1, 4))
			var direction = global_position.direction_to(wanderController.wander_position)
			velocity = direction * MAX_SPEED
			
			if global_position.distance_to(wanderController.wander_position) <= 4:
				velocity = Vector2.ZERO
			
		CHASING:
			var player = DetectionZone.player
			if player != null:
				var direction = global_position.direction_to(player.global_position)
				velocity = direction * MAX_SPEED
			else:
				state = IDLE
				
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
	velocity = move_and_slide(velocity)

func chase_player():
	if DetectionZone.PlayerDetected():
		state = CHASING

func state_change(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_Hurtbox_area_entered(area):
	stats.hp -= area.damage
	knockback = area.knockback_vector * 250

func _on_Stats_dead():
	var pika_drop = _pika_drop.instance()
	get_parent().add_child(pika_drop)
	pika_drop.global_position = self.global_position
	queue_free()

func _on_Hitbox_area_entered(area):
	animationPlayer.play("PikaAttack")
	animationTimer.start()


func _on_Timer_timeout():
	animationPlayer.play("PikaIdle")