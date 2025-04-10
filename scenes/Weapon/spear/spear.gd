extends Area2D

@export var speed: float = 400.0
@export var lifetime: float = 3.0

var direction := 1  # 1 = right, -1 = left
var time_alive := 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	# Flip sprite based on direction
	sprite.flip_h = (direction == -1)

	# Connect collision signal
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position.x += direction * speed * delta
	time_alive += delta

	if time_alive > lifetime:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("die"):
			body.die()
		queue_free()
