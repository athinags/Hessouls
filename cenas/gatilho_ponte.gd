extends Area3D


# Evita que o gatilho seja ativado mais de uma vez.
var ativado: bool = false


# O Niquitin está no mesmo nível do GatilhoPonte
# dentro da cena Principal.
@onready var niquitin: CharacterBody3D = $"../niquitin"


func _ready() -> void:
	# Conecta o sinal da Area3D à função abaixo.
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	# Se o gatilho já foi usado, não faz nada.
	if ativado:
		return

	# Confere se quem entrou foi realmente o Hesse.
	if body.name == "Hesse":
		ativado = true

		# Libera a perseguição no código do Niquitin.
		niquitin.comecar_perseguicao()

		# Desativa o gatilho depois de usá-lo.
		set_deferred("monitoring", false)
