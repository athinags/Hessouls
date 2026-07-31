extends CharacterBody3D

const SPEED = 7.0
const JUMP_VELOCITY = 4
const ACCELERATION = 30

@onready var camera_pivot: Node3D = $camera_pivot
@onready var camera: Camera3D = $camera_pivot/camera
@onready var hesse_skin: Node3D = $Hesse_atq1
@onready var anim_player : AnimationPlayer = hesse_skin.get_node("AnimationPlayer2")
var mouse_sensitivity : float = 0.15
var camera_rotation : Vector2 = Vector2.ZERO
var last_movement_dir := Vector3.BACK
var is_jumping

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_pressed("left_click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		camera_rotation = event.screen_relative * mouse_sensitivity
	
func _physics_process(delta: float) -> void:
	camera_pivot.rotation.x += camera_rotation.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-45), deg_to_rad(0))
	camera_pivot.rotation.y -= camera_rotation.x * delta

	camera_rotation = Vector2.ZERO
	
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	is_jumping = Input.is_action_just_pressed("ui_accept") and is_on_floor()
	
	# Handle jump.
	if is_jumping:
		velocity.y = JUMP_VELOCITY

	# Get the input direction using WASD
	var input_dir := Vector2.ZERO
	
	# W - Frente
	if Input.is_action_pressed("frente"):
		input_dir.y -= 1
	
	# S - Trás
	if Input.is_action_pressed("trás"):
		input_dir.y += 1
	
	# A - Esquerda
	if Input.is_action_pressed("esquerda"):
		input_dir.x -= 1
	
	# D - Direita
	if Input.is_action_pressed("direita"):
		input_dir.x += 1
	
	# Normaliza o vetor para evitar que diagonal seja mais rápida
	input_dir = input_dir.normalized()
	
	var forward := camera.global_basis.z
	var right := camera.global_basis.x
	var direction := (forward * input_dir.y + right * input_dir.x).normalized()
	direction.y = 0.0
	
	var y_velocity = velocity.y
	velocity.y = 0.0
	
	if direction:
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO * SPEED, ACCELERATION * delta)

	velocity.y = y_velocity

	move_and_slide()
	_handle_animation()
	if direction.length() >0.1:
		last_movement_dir = direction

	var target_angle := Vector3.BACK.signed_angle_to(last_movement_dir, Vector3.UP)
	hesse_skin.global_rotation.y = lerp_angle(hesse_skin.global_rotation.y, target_angle, ACCELERATION * delta)

func _handle_animation():
	if is_jumping:
		print()
	elif not is_on_floor():
		if velocity.y < -0.1:
			if anim_player.current_animation != "Fall":
				anim_player.play("Fall", 0.2)
	else:
		if velocity.length() > 0.1:
			if anim_player.current_animation != "rigAction":
				anim_player.play("rigAction", 0.2)
		else:
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle", 0.2)
				
