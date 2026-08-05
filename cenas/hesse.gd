extends CharacterBody3D

signal vida_alterada(vida_atual: float, vida_maxima: float)
signal morreu


@export_category("Vida")
@export var vida_maxima: float = 100.0


var vida_atual: float = 100.0
var esta_morto: bool = false



@export_category("Reação ao dano")

# Velocidade com que o empurrão desaparece.
@export var desaceleracao_empurrao: float = 8.0

# Impulso que está sendo aplicado ao Hesse.
var empurrao_atual: Vector3 = Vector3.ZERO

# Velocidade produzida somente pelos controles do jogador.
# Ela fica separada do empurrão causado pelo Niquitin.
var velocidade_do_jogador: Vector3 = Vector3.ZERO

# Todas as partes visuais do modelo do Hesse.
var malhas_hesse: Array[GeometryInstance3D] = []

# Material vermelho colocado temporariamente sobre o modelo.
var material_dano: StandardMaterial3D = StandardMaterial3D.new()


#------inicio
@export_category("Ataque")

# Niquitin que receberá o dano.
@export var alvo_ataque: Node3D

# Dano fixo causado pelo Hesse.
@export var dano_ataque: float = 5

# Distância necessária para causar dano.
@export var distancia_ataque: float = 1.5

# Tempo entre os ataques.
@export var intervalo_entre_ataques: float = 1.0


# Contagem regressiva para permitir o próximo ataque.
var tempo_para_proximo_ataque: float = 0.0

#------fim


const SPEED = 7.0
const JUMP_VELOCITY = 4
const ACCELERATION = 30

@onready var camera_pivot: Node3D = $camera_pivot
@onready var camera: Camera3D = $camera_pivot/camera
@onready var hesse_skin: Node3D = $Hesse_all
@onready var anim_player : AnimationPlayer = hesse_skin.get_node("AnimationPlayer")
var mouse_sensitivity : float = 0.15
var camera_rotation : Vector2 = Vector2.ZERO
var last_movement_dir := Vector3.BACK
var is_jumping

func _ready() -> void:
	vida_atual = vida_maxima
	vida_alterada.emit(vida_atual, vida_maxima)
	
	_preparar_efeito_dano()

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
		
#------inicio
func _physics_process(delta: float) -> void:
	if esta_morto:
		velocity = Vector3.ZERO
		velocidade_do_jogador = Vector3.ZERO
		empurrao_atual = Vector3.ZERO
		move_and_slide()
		return

	tempo_para_proximo_ataque = max(
		tempo_para_proximo_ataque - delta,
		0.0
	)

	camera_pivot.rotation.x += camera_rotation.y * delta
#------fim
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
	
	# Guarda a velocidade vertical da gravidade e do salto.
	var y_velocity = velocity.y

	# Calcula somente a velocidade controlada pelo jogador.
	if direction.length_squared() > 0.0:
		velocidade_do_jogador = velocidade_do_jogador.move_toward(
			direction * SPEED,
			ACCELERATION * delta
		)
	else:
		velocidade_do_jogador = velocidade_do_jogador.move_toward(
			Vector3.ZERO,
			ACCELERATION * delta
		)

	# Faz o empurrão desaparecer gradualmente.
	empurrao_atual = empurrao_atual.move_toward(
		Vector3.ZERO,
		desaceleracao_empurrao * delta
	)

	# Combina a movimentação com o empurrão.
	# Usamos "=" em vez de "+=", evitando acumulação.
	velocity.x = velocidade_do_jogador.x + empurrao_atual.x
	velocity.z = velocidade_do_jogador.z + empurrao_atual.z
	velocity.y = y_velocity

	move_and_slide()
	#------inicio
	_tentar_atacar_niquitin()
	#------fim
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
		if velocidade_do_jogador.length() > 0.1:
			if anim_player.current_animation != "correr":
				anim_player.play("correr", 0.2)
		else:
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle", 0.2)



#funções de dano e morte:


func receber_dano(
	quantidade: float,
	direcao_empurrao: Vector3 = Vector3.ZERO,
	forca_empurrao: float = 0.0
) -> void:
	if esta_morto:
		return

	vida_atual = clamp(
		vida_atual - quantidade,
		0.0,
		vida_maxima
	)

	# Recebe a direção que vem do Niquitin.
	direcao_empurrao.y = 0.0

	if (
		direcao_empurrao.length_squared() > 0.0
		and forca_empurrao > 0.0
	):
		empurrao_atual = (
			direcao_empurrao.normalized()
			* forca_empurrao
		)

	# Ativa o efeito visual.
	_piscar_vermelho()

	print(
		"Hesse recebeu ",
		quantidade,
		" de dano. Vida: ",
		vida_atual,
		"/",
		vida_maxima
	)

	vida_alterada.emit(
		vida_atual,
		vida_maxima
	)

	if vida_atual <= 0.0:
		_morrer()
		

func _morrer() -> void:
	if esta_morto:
		return

	esta_morto = true

	velocity = Vector3.ZERO
	velocidade_do_jogador = Vector3.ZERO
	empurrao_atual = Vector3.ZERO

	if anim_player.is_playing():
		anim_player.stop()

	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE
	)

	morreu.emit()





func get_vida_atual() -> float:
	return vida_atual


func get_vida_maxima() -> float:
	return vida_maxima
	
func recuperar_vida(quantidade: float) -> bool:
	# Não recupera vida depois que o Hesse morreu.
	if esta_morto:
		return false

	# Não consome o item quando a vida já está cheia.
	if vida_atual >= vida_maxima:
		return false

	var vida_anterior := vida_atual

	vida_atual = clamp(
		vida_atual + quantidade,
		0.0,
		vida_maxima
	)

	var quantidade_recuperada := (
		vida_atual - vida_anterior
	)

	# Atualiza automaticamente a barra de vida.
	vida_alterada.emit(
		vida_atual,
		vida_maxima
	)

	print(
		"Hesse recuperou ",
		quantidade_recuperada,
		" de vida. Vida: ",
		vida_atual,
		"/",
		vida_maxima
	)

	return quantidade_recuperada > 0.0
	
	
	
func _preparar_efeito_dano() -> void:
	# Procura todas as partes visuais 3D do Hesse,
	# mesmo que estejam dentro de vários nós importados.
	for no_encontrado in find_children(
		"*",
		"GeometryInstance3D",
		true,
		false
	):
		if no_encontrado is GeometryInstance3D:
			malhas_hesse.append(no_encontrado)

	# Configura o vermelho semitransparente.
	material_dano.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)
	
	# Faz a cor aparecer forte, independentemente da iluminação.
	material_dano.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	material_dano.albedo_color = Color(
		1.0,
		0.0,
		0.0,
		0.80
	)


func _piscar_vermelho() -> void:
	# Coloca o material vermelho sobre todas
	# as partes visuais do personagem.
	for malha in malhas_hesse:
		if is_instance_valid(malha):
			malha.material_overlay = material_dano

	# Mantém o efeito por 0,15 segundo.
	await get_tree().create_timer(0.25).timeout

	# Remove o vermelho e revela novamente
	# os materiais normais do personagem.
	for malha in malhas_hesse:
		if is_instance_valid(malha):
			malha.material_overlay = null

#------inicio

func _tentar_atacar_niquitin() -> void:
	if tempo_para_proximo_ataque > 0.0:
		return

	if alvo_ataque == null:
		return

	# Impede que o Hesse continue atacando
	# depois de o Niquitin ficar sem vida.
	if alvo_ataque.has_method("get_vida_atual"):
		var vida_do_alvo := float(
			alvo_ataque.call("get_vida_atual")
		)

		if vida_do_alvo <= 0.0:
			return

	var diferenca_ate_o_alvo := (
		alvo_ataque.global_position
		- global_position
	)

	# Consideramos apenas a distância horizontal.
	diferenca_ate_o_alvo.y = 0.0

	var distancia_ate_o_alvo := (
		diferenca_ate_o_alvo.length()
	)

	if distancia_ate_o_alvo > distancia_ataque:
		return

	if alvo_ataque.has_method("receber_dano"):
		alvo_ataque.call(
			"receber_dano",
			dano_ataque
		)

		tempo_para_proximo_ataque = (
			intervalo_entre_ataques
		)

		print(
			"Hesse atacou o Niquitin causando ",
			dano_ataque,
			" de dano!"
		)


#------fim
