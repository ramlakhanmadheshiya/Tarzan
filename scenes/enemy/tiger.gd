extends CharacterBody2D

# --- Editable Properties ---
@export var patrol_speed = 80.0
@export var chase_speed = 200.0
@export var patrol_wait_time = 0.5
@export var attack_range = 16.0
@export var gravity = 980.0
@export var patrol_distance_left: float = 100.0
@export var patrol_distance_right: float = 100.0

# --- Node References ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var hurtbox = $Hurtbox
@onready var patrol_area = $PatrolArea
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/CollisionShape2D

# --- Cached Patrol Bounds ---
var patrol_start: Vector2
var patrol_end: Vector2

# --- Internal ---
var direction := -1
var patrol_timer := 0.0
var player: CharacterBody2D = null
var is_dead = false

enum State { PATROLLING, CHASING, ATTACK, IDLE, DEAD }
var current_state = State.PATROLLING

# --- Ready ---
func _ready():
	var origin = patrol_area.global_position
	patrol_start = origin - Vector2(patrol_distance_left, 0)
	patrol_end = origin + Vector2(patrol_distance_right, 0)

	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	hurtbox.body_entered.connect(_on_player_touched)

# --- Physics Step ---
func _physics_process(delta):
	if is_dead:
		return  # ✅ Skip movement & animation if dead

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	match current_state:
		State.PATROLLING:
			patrol(delta)
		State.CHASING:
			chase()
		State.ATTACK, State.IDLE:
			velocity.x = 0

	move_and_slide()
	update_animation()

# --- Patrol ---
func patrol(delta):
	if patrol_timer > 0:
		patrol_timer -= delta
		velocity.x = 0
		return

	velocity.x = direction * patrol_speed

	if direction == -1 and global_position.x <= patrol_start.x:
		direction = 1
		patrol_timer = patrol_wait_time
	elif direction == 1 and global_position.x >= patrol_end.x:
		direction = -1
		patrol_timer = patrol_wait_time

# --- Chase ---
func chase():
	if not is_instance_valid(player):
		current_state = State.PATROLLING
		return

	direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * chase_speed

	if global_position.distance_to(player.global_position) < attack_range:
		current_state = State.ATTACK
		velocity.x = 0
		animated_sprite.play("attack")
		if player.has_method("die"):
			player.die()
		await get_tree().create_timer(1.0).timeout
		current_state = State.IDLE

# --- Animation ---
func update_animation():
	if current_state == State.DEAD:
		return  # ✅ Don't override death animation

	match current_state:
		State.PATROLLING:
			animated_sprite.play("walk")
		State.CHASING:
			animated_sprite.play("run")
		State.ATTACK:
			pass  # attack animation played manually
		State.IDLE:
			animated_sprite.play("idle")

	animated_sprite.flip_h = (direction == -1)

# --- Signal: Player Entered Detection Area ---
func _on_player_detected(body):
	if body.is_in_group("player") and not is_dead:
		player = body
		current_state = State.CHASING

# --- Signal: Player Exited Detection Area ---
func _on_player_lost(body):
	if body == player:
		player = null
		current_state = State.PATROLLING

# --- Signal: Tiger Touched Player (melee) ---
func _on_player_touched(body):
	if body.is_in_group("player") and current_state != State.ATTACK and not is_dead:
		current_state = State.ATTACK
		velocity = Vector2.ZERO
		animated_sprite.play("attack")
		if body.has_method("die"):
			body.die()
		await get_tree().create_timer(1.0).timeout
		current_state = State.IDLE

# --- Called by spear.gd when hit ---
func die():
	if is_dead:
		return
	is_dead = true
	current_state = State.DEAD
	velocity = Vector2.ZERO

	# ✅ Disable collisions so player can't trigger anything
	body_collision.disabled = true
	hurtbox_collision.disabled = true
	detection_area.monitoring = false

	# ✅ Optional: disconnect signal
	hurtbox.body_entered.disconnect(_on_player_touched)

	animated_sprite.play("die")
	await get_tree().create_timer(2.0).timeout
	queue_free()
