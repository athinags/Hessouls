extends Node3D


@onready var hesse: CharacterBody3D = $Hesse
@onready var niquitin: CharacterBody3D = $niquitin

@onready var mensagem_vitoria: Label = (
	$HUD/MensagemVitoria
)


# Evita que duas tentativas de reiniciar
# aconteçam ao mesmo tempo.
var reiniciando_jogo: bool = false


func _ready() -> void:	
	# Garante que a mensagem comece escondida.
	mensagem_vitoria.hide()

	# Escuta a morte dos dois personagens.
	hesse.morreu.connect(_on_hesse_morreu)
	niquitin.morreu.connect(_on_niquitin_morreu)


func _on_niquitin_morreu() -> void:
	# Caso o jogo já esteja reiniciando,
	# não exibimos uma vitória.
	if reiniciando_jogo:
		return

	# Faz o Niquitin desaparecer.
	niquitin.hide()

	# Impede que seu código de física continue funcionando.
	niquitin.set_physics_process(false)

	# Remove suas colisões.
	niquitin.collision_layer = 0
	niquitin.collision_mask = 0

	# Exibe a mensagem gigante.
	mensagem_vitoria.show()



func _on_hesse_morreu() -> void:
	if reiniciando_jogo:
		return

	reiniciando_jogo = true

	# Caso os dois morram quase juntos,
	# a morte do Hesse terá prioridade
	# e o jogo será reiniciado.
	mensagem_vitoria.hide()

	# Pequena espera para a barra conseguir mostrar zero.
	await get_tree().create_timer(0.5).timeout

	get_tree().reload_current_scene()
