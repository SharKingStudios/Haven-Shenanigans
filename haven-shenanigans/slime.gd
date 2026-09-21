extends Node2D

signal caught_player

@export var start_x := -650.0
@export var base_speed := 115.0
var running := false
var elapsed := 0.0

func _ready() -> void:
	position.x = start_x
	$CatchArea.body_entered.connect(_on_body_entered)
	queue_redraw()

func begin() -> void:
	position.x = start_x
	elapsed = 0.0
	running = true

func reset_after_catch() -> void:
	position.x = -400.0
	elapsed = 0.0

func stop() -> void:
	running = false

func _process(delta: float) -> void:
	if running:
		elapsed += delta
		position.x += (base_speed + minf(elapsed * 3.0, 105.0)) * delta
		queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if running and body.is_in_group("runner"): caught_player.emit()

func _draw() -> void:
	for x in range(-180, 100, 17):
		var y := 390.0 + sin(float(x) * 0.11) * 86.0
		draw_circle(Vector2(x, y), 35.0 + abs(sin(float(x))) * 15.0, Color("5dde91", 0.88))
		draw_circle(Vector2(x + 4, y - 7), 11, Color("a7ffbf", 0.5))
