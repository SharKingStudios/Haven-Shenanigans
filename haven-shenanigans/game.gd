extends Node2D

const COMIC_FONT = preload("res://comic-sans.ttf")
var player: CharacterBody2D
var camera: Camera2D
var state := "menu"
var elapsed := 0.0
var slime
var shake := 0.0
var platforms: Array[Rect2] = []
var title: Label
var prompt: Label
var hud: Label
var finish_label: Label
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 1337
	# The base floor deliberately extends far below the camera as well as far past either side.
	platforms = [Rect2(-10000, 525, 30000, 5000), Rect2(700, 430, 180, 26), Rect2(1200, 350, 210, 26), Rect2(1730, 450, 160, 26), Rect2(2250, 390, 200, 26), Rect2(2870, 330, 210, 26), Rect2(3470, 440, 180, 26), Rect2(4050, 365, 220, 26), Rect2(4670, 420, 220, 26)]
	for rect in platforms: _make_platform(rect)
	player = $Player
	camera = $Player/Camera2D
	slime = $Slime
	player.jumped.connect(func(): shake = maxf(shake, 3.0))
	player.double_jumped.connect(func(): shake = maxf(shake, 5.0))
	player.landed.connect(func(): shake = maxf(shake, 4.0))
	slime.connect("caught_player", Callable(self, "_on_slime_caught"))
	_make_ui(); queue_redraw()

func _make_platform(rect: Rect2) -> void:
	# Match collision to the full visible purple column, not merely the yellow-topped ledge.
	var solid_rect := rect if rect.position.y >= 525 else Rect2(rect.position.x, rect.position.y, rect.size.x, 525 - rect.position.y)
	var body := StaticBody2D.new(); body.position = solid_rect.get_center()
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = solid_rect.size
	collision.shape = shape; body.add_child(collision); add_child(body)

func _make_ui() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var overlay := ColorRect.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.color = Color(0.05, 0.08, 0.16, 0.16)
	var shader := Shader.new(); shader.code = "shader_type canvas_item; uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap; void fragment(){ vec4 c=texture(screen_texture,SCREEN_UV); float lines=sin(SCREEN_UV.y*900.0)*0.035; float vign=1.0-length(SCREEN_UV-vec2(0.5))*0.38; COLOR=vec4(c.rgb*(vign-lines),0.22); }"
	var material := ShaderMaterial.new(); material.shader = shader; overlay.material = material; layer.add_child(overlay)
	title = _label("SLIME RUN", 54, Color("fff4bb")); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.position = Vector2(0, 140); title.size = Vector2(1150, 70); layer.add_child(title)
	prompt = _label("Outrun the goo - Press f to start", 21, Color("9cf5d1")); prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; prompt.position = Vector2(0, 215); prompt.size = Vector2(1150, 40); layer.add_child(prompt)
	hud = _label("", 25, Color.WHITE); hud.position = Vector2(28, 22); hud.size = Vector2(350, 45); hud.visible = false; layer.add_child(hud)
	finish_label = _label("", 32, Color("fff4bb")); finish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; finish_label.position = Vector2(0, 300); finish_label.size = Vector2(1150, 160); finish_label.visible = false; layer.add_child(finish_label)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_override("font", COMIC_FONT); label.add_theme_font_size_override("font_size", font_size); label.add_theme_color_override("font_color", color); label.add_theme_color_override("font_shadow_color", Color("22253e")); label.add_theme_constant_override("shadow_offset_x", 3); label.add_theme_constant_override("shadow_offset_y", 4); return label

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		if state == "menu" or state == "finished": start_run()

func start_run() -> void:
	state = "playing"; elapsed = 0.0; shake = 0.0; slime.begin()
	player.position = Vector2(70, 450); player.velocity = Vector2.ZERO
	title.visible = false; prompt.visible = false; finish_label.visible = false; hud.visible = true
	$SoundController.play_ui(); queue_redraw()

func _process(delta: float) -> void:
	if state == "playing":
		elapsed += delta
		if player.position.y > 760: player.position = Vector2(maxf(70.0, player.position.x - 110), 400); player.velocity = Vector2.ZERO; shake = 8.0
		if player.position.x > 5450: finish()
		hud.text = "TIME  %05.2f\nSLIME +%dm" % [elapsed, int(slime.position.x / 10.0)]
		shake = maxf(0.0, shake - delta * 28.0); camera.offset = Vector2(rng.randf_range(-shake, shake), rng.randf_range(-shake, shake)); queue_redraw()

func finish() -> void:
	slime.stop()
	state = "finished"; hud.visible = false; finish_label.visible = true; title.visible = true; prompt.visible = true
	title.text = "YOU OUTRAN THE GOO!"; prompt.text = "Press f to go again"; finish_label.text = "Final time\n%05.2f seconds" % elapsed
	$SoundController.play_win(); shake = 11.0; queue_redraw()

func _draw() -> void:
	for rect in platforms:
		var visual_rect := rect if rect.position.y >= 525 else Rect2(rect.position.x, rect.position.y, rect.size.x, 525 - rect.position.y)
		draw_rect(visual_rect, Color("7a4c86")); draw_rect(Rect2(rect.position, Vector2(rect.size.x, 7)), Color("ffd477"))
	draw_rect(Rect2(5510, 383, 24, 142), Color("ffd477")); draw_string(COMIC_FONT, Vector2(5425, 350), "EXIT!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)

func _on_slime_caught() -> void:
	$SoundController.play_hurt(); shake = 15.0
	player.position = Vector2(70, 450); player.velocity = Vector2.ZERO
	slime.reset_after_catch(); elapsed = maxf(0.0, elapsed - 2.0)
