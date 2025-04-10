# water.gd
extends Area2D

func _ready():
	add_to_group("water_collision")
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	print("Entered Water:", body.name)
	if body.is_in_group("player"):
		body.set_in_water(true)

func _on_body_exited(body: Node) -> void:
	print("Exited Water:", body.name)
	if body.is_in_group("player"):
		body.set_in_water(false)
