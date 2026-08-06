extends CharacterBody3D


#vida niquitin
signal vida_alterada(
	vida_atual: float,
	vida_maxima: float
)
signal morreu

@export_category("Vida")

@export var vida_maxima: float = 100.0


var vida_atual: float = 100.0
var esta_morto: bool = false
#vida niquitin


@export var alvo: Node3D


@export_category("Movimento")

# Velocidade do Niquitin.
@export var velocidade: float = 1.5


# Distância em que ele para de andar
# e começa a atacar.
@export var distancia_de_parada: float = 1.2


@export_category("Ataque")

# Dano causado em cada ataque.
@export var dano: float = 5.0


# Tempo, em segundos, entre os ataques.
@export var intervalo_entre_ataques: float = 1.0

# Força aplicada ao Hesse em cada ataque.
@export var forca_empurrao: float = 1.2

# AnimationPlayer do modelo.
@onready var animacao: AnimationPlayer = (
	$saltitando/AnimationPlayer
)


# Começa falso porque o gatilho da ponte
# é quem libera a perseguição.
var perseguicao_ativa: bool = false


# Contagem regressiva para permitir outro ataque.
var tempo_para_proximo_ataque: float = 0.0


func _ready() -> void:
	
	#vida niquitin
	vida_atual = vida_maxima

	vida_alterada.emit(
		vida_atual,
		vida_maxima
	)
	#vida niquitin
	
	var animacao_de_caminhada := (
		animacao.get_animation("rigAction")
	)

	if animacao_de_caminhada != null:
		animacao_de_caminhada.loop_mode = (
			Animation.LOOP_LINEAR
		)
	else:
		push_error(
			"A animação 'rigAction' não foi encontrada."
		)


func _physics_process(delta: float) -> void:
	
	#vida niquitin
	if esta_morto:
		_parar_movimento()
		_aplicar_gravidade(delta)
		move_and_slide()
		return
	#vida niquitin
	
	
	_aplicar_gravidade(delta)

	# Reduz o tempo restante entre ataques.
	tempo_para_proximo_ataque = max(
		tempo_para_proximo_ataque - delta,
		0.0
	)

	# Antes de o Hesse atravessar a ponte,
	# o Niquitin permanece parado.
	if not perseguicao_ativa:
		_parar_movimento()
		move_and_slide()
		return

	if alvo == null:
		_parar_movimento()
		move_and_slide()
		return

	# Calcula a direção horizontal até o Hesse.
	var direcao_ate_o_alvo := (
		alvo.global_position - global_position
	)

	direcao_ate_o_alvo.y = 0.0

	var distancia_ate_o_alvo := (
		direcao_ate_o_alvo.length()
	)

	# O Niquitin sempre continua tentando avançar
	# na direção do Hesse.
	_seguir_alvo(direcao_ate_o_alvo)

	# Quando entra na distância de ataque,
	# ele causa dano sem parar de andar.
	if distancia_ate_o_alvo <= distancia_de_parada:
		_tentar_atacar(direcao_ate_o_alvo)

	move_and_slide()


func _aplicar_gravidade(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0


func _seguir_alvo(
	direcao_ate_o_alvo: Vector3
) -> void:
	if direcao_ate_o_alvo.length_squared() == 0.0:
		return

	var direcao_normalizada := (
		direcao_ate_o_alvo.normalized()
	)

	velocity.x = (
		direcao_normalizada.x * velocidade
	)

	velocity.z = (
		direcao_normalizada.z * velocidade
	)

	_olhar_para_alvo()

	if (
		animacao.current_animation != "rigAction"
		or not animacao.is_playing()
	):
		animacao.play("rigAction")


func _olhar_para_alvo() -> void:
	if alvo == null:
		return

	var posicao_para_olhar := Vector3(
		alvo.global_position.x,
		global_position.y,
		alvo.global_position.z
	)

	look_at(
		posicao_para_olhar,
		Vector3.UP
	)

func _tentar_atacar(
	direcao_ate_o_alvo: Vector3
) -> void:
	if tempo_para_proximo_ataque > 0.0:
		return

	if alvo == null:
		return

	if alvo.has_method("receber_dano"):
		# A direção vai do Niquitin para o Hesse.
		var direcao_do_empurrao := (
			direcao_ate_o_alvo.normalized()
		)

		alvo.call(
			"receber_dano",
			dano,
			direcao_do_empurrao,
			forca_empurrao
		)

		tempo_para_proximo_ataque = (
			intervalo_entre_ataques
		)

		print(
			"Niquitin atacou o Hesse causando ",
			dano,
			" de dano!"
		)


func _parar_movimento() -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	# Ainda não temos animação de ataque.
	# Portanto, a caminhada para quando ele ataca.
	if animacao.is_playing():
		animacao.stop()


# Esta função é chamada pelo GatilhoPonte
func comecar_perseguicao() -> void:
	perseguicao_ativa = true




#vida niquitin


func receber_dano(quantidade: float) -> void:
	if esta_morto:
		return

	vida_atual = clamp(
		vida_atual - quantidade,
		0.0,
		vida_maxima
	)

	print(
		"Niquitin recebeu ",
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
	perseguicao_ativa = false
	velocity = Vector3.ZERO

	if animacao.is_playing():
		animacao.stop()

	morreu.emit()



func get_vida_atual() -> float:
	return vida_atual


func get_vida_maxima() -> float:
	return vida_maxima
	
	
#fim vida niquitin
