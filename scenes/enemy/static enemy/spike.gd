extends CharacterBody2D

@export var gravity: float = 980.0  # Standard gravity
@export var snap_on_start: bool = true  # So you can turn off snapping if needed

@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D

func _ready():
	hurtbox.body_entered.connect(_on_Hurtbox_body_entered)

func _physics_process(delta):
	if not snap_on_start:
		return

	# Apply gravity until we're on the floor
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		snap_on_start = false  # ✅ Stop falling once landed

	move_and_slide()

func _on_Hurtbox_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("die"):
			body.die(true)  # Instant death
