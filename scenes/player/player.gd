extends CharacterBody2D

@export var speed = 400.0
@export var jump_velocity = -450.0
@export var swim_speed_horizontal = 100.0
@export var swim_speed_vertical = 80.0
@export var water_gravity_scale = 0.3
@export var attack_duration = 0.6
@export var deceleration_factor = 5.0
@export var spear_scene: PackedScene  # Assign Spear.tscn in Inspector

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D
@onready var water_detector = $WaterDetector

enum State { IDLE, RUN, JUMP, FALL, IDLE_SWIM, SWIM, ATTACK, DIE }
var current_state = State.IDLE
var facing_direction = 1
var is_in_water = false
var is_attacking = false
var attack_timer = 0.0

# NEW: Fruit score tracker
var fruit_score: int = 0

func _ready():
	add_to_group("player")
	update_animation()

func _physics_process(delta):
	if current_state == State.DIE:
		return

	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false

	if not is_on_floor() and not is_in_water:
		velocity.y += gravity * delta
	elif is_in_water:
		velocity.y += gravity * water_gravity_scale * delta

	if not is_attacking:
		handle_input(delta)

	move_and_slide()
	update_state()
	update_animation()

func handle_input(delta):
	var direction = Input.get_axis("move_left", "move_right")
	var vertical_direction = Input.get_axis("move_up", "move_down")

	if is_in_water:
		if direction:
			velocity.x = direction * swim_speed_horizontal
			facing_direction = sign(direction)
		else:
			velocity.x = move_toward(velocity.x, 0, swim_speed_horizontal * deceleration_factor * delta)

		if vertical_direction:
			velocity.y = vertical_direction * swim_speed_vertical
		else:
			velocity.y = move_toward(velocity.y, 0, swim_speed_vertical * deceleration_factor * delta)

		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity * 0.7
			is_in_water = false
			update_state()
	else:
		if direction:
			velocity.x = direction * speed
			facing_direction = sign(direction)
		else:
			velocity.x = move_toward(velocity.x, 0, speed * deceleration_factor * delta)

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity

	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		attack_timer = attack_duration
		velocity.x = 0

		if spear_scene:
			var spear = spear_scene.instantiate()
			spear.position = global_position
			spear.direction = facing_direction
			get_tree().current_scene.add_child(spear)

	animated_sprite.flip_h = (facing_direction == -1)

func update_state():
	if current_state == State.DIE:
		return
	if is_attacking:
		current_state = State.ATTACK
		return

	if is_in_water:
		current_state = State.SWIM if abs(velocity.x) > 5 or abs(velocity.y) > 5 else State.IDLE_SWIM
	else:
		if is_on_floor():
			current_state = State.RUN if abs(velocity.x) > 5 else State.IDLE
		else:
			current_state = State.JUMP if velocity.y < 0 else State.FALL

func update_animation():
	var anim_name = "idle"
	match current_state:
		State.IDLE: anim_name = "idle"
		State.RUN: anim_name = "run"
		State.JUMP: anim_name = "jump"
		State.FALL: anim_name = "jump"
		State.IDLE_SWIM: anim_name = "idle_swim"
		State.SWIM: anim_name = "swim"
		State.ATTACK: anim_name = "attack"
		State.DIE: anim_name = "die"

	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func set_in_water(status: bool):
	is_in_water = status
	if is_in_water:
		velocity.y = 0

func die(instant := false):
	if current_state == State.DIE:
		return

	is_attacking = false
	velocity = Vector2.ZERO

	if instant:
		current_state = State.DIE
		update_animation()
	else:
		await get_tree().create_timer(0.5).timeout
		current_state = State.DIE
		update_animation()

	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func _on_GoalDetector_area_entered(area):
	if area.is_in_group("goal"):
		print("🎯 Goal reached from player side!")

# ✅ NEW: Called by fruits when collected
func collect_fruit():
	fruit_score += 1
	print("🍇 Fruit score: ", fruit_score)
