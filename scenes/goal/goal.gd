extends CharacterBody2D

@export var gravity: float = 980.0

@onready var goal_area: Area2D = $GoalArea

func _ready():
	# Connect the Area2D signal for detecting player
	goal_area.body_entered.connect(_on_goal_area_body_entered)

func _physics_process(delta):
	# Gravity: Let the goal fall to the ground until it hits the floor
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	move_and_slide()

func _on_goal_area_body_entered(body: Node):
	if body.is_in_group("player"):
		print("🎉 Level Completed!")
