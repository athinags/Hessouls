extends ProgressBar


@export var personagem: Node


func _ready() -> void:
	if personagem == null:
		push_error(
			"O Hesse não foi atribuído à BarraVida."
		)
		return

	# Configura a barra com os valores iniciais.
	min_value = 0.0
	max_value = float(
		personagem.call("get_vida_maxima")
	)
	value = float(
		personagem.call("get_vida_atual")
	)

	show_percentage = true

	# Escuta as mudanças de vida do Hesse.
	personagem.connect(
		"vida_alterada",
		Callable(self, "_on_vida_alterada")
	)


func _on_vida_alterada(
	nova_vida: float,
	nova_vida_maxima: float
) -> void:
	max_value = nova_vida_maxima
	value = nova_vida
