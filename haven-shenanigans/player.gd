extends CharacterBody2D

const PLAYER_TEXTURE = preload("res://grac was here.png")
signal jumped
signal double_jumped
signal landed
const RUN_SPEED := 440.0
const ACCEL := 3100.0
const GRAVITY := 1850.0
const JUMP_POWER := -690.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.14
var coyote := 0.0
var jump_buffer := 0.0
var jumps := 0
var facing := 1.0

func _ready() -> void:
	# Art, collision, and camera are scene children, not runtime-created nodes.
	$PlayerSprite.texture = PLAYER_TEXTURE

func _physics_process(delta: float) -> void:
	var grounded := is_on_floor()
	if not grounded: velocity.y += GRAVITY * delta
	else: coyote = COYOTE_TIME; jumps = 0
	coyote = maxf(0.0, coyote - delta); jump_buffer = maxf(0.0, jump_buffer - delta)
	if Input.is_action_just_pressed("Up") or Input.is_action_just_pressed("ui_accept"): jump_buffer = JUMP_BUFFER
	if (Input.is_action_just_released("Up") or Input.is_action_just_released("ui_accept")) and velocity.y < 0.0: velocity.y *= 0.48
	var input_dir := Input.get_axis("Left", "Right")
	velocity.x = move_toward(velocity.x, input_dir * RUN_SPEED, ACCEL * delta)
	if absf(input_dir) > 0.1:
		facing = signf(input_dir)
		$PlayerSprite.flip_h = facing < 0.0
	if jump_buffer > 0.0:
		if grounded or coyote > 0.0:
			velocity.y = JUMP_POWER; jumps = 1; coyote = 0.0; jump_buffer = 0.0; jumped.emit()
		elif jumps == 1:
			velocity.y = JUMP_POWER * 0.9; velocity.x += facing * 100.0; jumps = 2; jump_buffer = 0.0; double_jumped.emit()
	move_and_slide()
	if is_on_floor() and not grounded: landed.emit()
