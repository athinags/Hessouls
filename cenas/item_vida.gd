extends Area3D


# Quantidade recuperada por este item.
@export var quantidade_cura: float = 20.0


@export_category("Movimento visual")

# Velocidade com que o item gira.
@export var velocidade_rotacao: float = 2.0

# Quanto o item sobe e desce.
@export var altura_flutuacao: float = 0.20

# Velocidade da flutuação.
@export var velocidade_flutuacao: float = 2.5


var tempo: float = 0.0
var altura_inicial: float = 0.0
var coletado: bool = false


func _ready() -> void:
	altura_inicial = position.y

	# Detecta quando um corpo entra na área.
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# Faz o item girar.
	rotate_y(
		velocidade_rotacao * delta
	)

	# Faz o item flutuar para cima e para baixo.
	tempo += delta * velocidade_flutuacao

	var nova_posicao := position

	nova_posicao.y = (
		altura_inicial
		+ sin(tempo) * altura_flutuacao
	)

	position = nova_posicao


func _on_body_entered(body: Node3D) -> void:
	if coletado:
		return

	# Somente o Hesse possui esta função.
	if not body.has_method("recuperar_vida"):
		return

	var recuperou_vida := bool(
		body.call(
			"recuperar_vida",
			quantidade_cura
		)
	)

	# Se a vida estiver cheia, o item permanece no mapa.
	if not recuperou_vida:
		return

	coletado = true

	# Evita que seja detectado novamente.
	monitoring = false

	print(
		"Item coletado: +",
		quantidade_cura,
		" de vida."
	)

	# Remove o item do mapa.
	queue_free()
