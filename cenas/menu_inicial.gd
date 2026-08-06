extends Control

# Cena que será aberta ao clicar em "Jogar".
# Ajuste o caminho caso a principal.tscn
# esteja dentro de alguma pasta.
@export_file("*.tscn") var cena_do_jogo: String = "res://cenas/principal.tscn"

@onready var botao_jogar: Button = %BotaoJogar
@onready var botao_sair: Button = %BotaoSair

func _ready() -> void:
	# O jogo captura o mouse, então aqui
	# garantimos que ele esteja visível.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	botao_jogar.pressed.connect(_on_jogar_pressed)
	botao_sair.pressed.connect(_on_sair_pressed)

	# Deixa o botão "Jogar" já selecionado,
	# permitindo iniciar com Enter.
	botao_jogar.grab_focus()


func _on_jogar_pressed() -> void:
	get_tree().change_scene_to_file(cena_do_jogo)


func _on_sair_pressed() -> void:
	get_tree().quit()
