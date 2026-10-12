extends SceneTree
## Exercita despacho real de eventos Control → viewport → _unhandled_input.
var game: Node
var failures := 0

func _initialize() -> void: call_deferred("run")

func must(value: bool,description: String) -> void:
 if value: print("INPUT PASS: "+description)
 else: push_error("INPUT FAIL: "+description); failures += 1

func find_button(node: Node,caption: String) -> Button:
 if node is Button and node.text == caption: return node
 for child in node.get_children():
  var result = find_button(child,caption)
  if result: return result
 return null

func click(target: Control) -> void:
 var point = target.get_global_rect().get_center()
 var motion = InputEventMouseMotion.new()
 motion.position = point; motion.global_position = point
 root.push_input(motion,true)
 var down = InputEventMouseButton.new()
 down.button_index = MOUSE_BUTTON_LEFT; down.pressed = true
 down.position = point; down.global_position = point
 root.push_input(down,true)
 var up = InputEventMouseButton.new()
 up.button_index = MOUSE_BUTTON_LEFT; up.pressed = false
 up.position = point; up.global_position = point
 root.push_input(up,true)
 await process_frame

func key(code: int,character := 0) -> void:
 var down = InputEventKey.new()
 down.keycode = code; down.physical_keycode = code; down.unicode = character; down.pressed = true
 root.push_input(down,true)
 var up = InputEventKey.new()
 up.keycode = code; up.physical_keycode = code; up.unicode = character; up.pressed = false
 root.push_input(up,true)
 await process_frame

func run() -> void:
 game = load("res://main.tscn").instantiate(); root.add_child(game)
 await process_frame
 await click(find_button(game.ui.root_control,"Nova partida"))
 must(game.mode == "NAME" or game.ui.new_slot_select,"clique real em Nova partida")
 if game.ui.new_slot_select:
  await click(find_button(game.ui.root_control,"Espaço 1 — substituir partida"))
  must(game.ui.overwrite_slot == 1,"clique real escolhe slot ocupado")
  await click(find_button(game.ui.root_control,"Substituir espaço 1"))
 must(game.mode == "NAME","confirmação real abre nome")
 await click(game.name_edit)
 await key(KEY_A,97)
 await key(KEY_N,110)
 await key(KEY_A,97)
 must(game.name_edit.text.to_lower() == "ana","teclas reais digitam no campo")
 await key(KEY_ENTER)
 must(game.mode == "INTRO" and game.s.name.to_lower() == "ana","Enter confirma nome sem mover ator")
 game.lia_arriving = false; game.ui.refresh(true)
 await process_frame
 var before = game.dialog_index
 await click(find_button(game.ui.root_control,"Continuar"))
 must(game.dialog_index == before+1,"clique de diálogo avança uma só fala")
 await click(find_button(game.ui.root_control,"Pular apresentação"))
 must(game.mode == "PLAY","clique de pular entra na fazenda")
 var down = InputEventMouseButton.new()
 down.button_index = MOUSE_BUTTON_LEFT; down.pressed = true
 down.position = Vector2(320,180); down.global_position = down.position
 Input.parse_input_event(down)
 root.push_input(down,true)
 await process_frame
 var motion = InputEventMouseMotion.new()
 motion.position = game.ui.hotbar_buttons[0].get_global_rect().get_center()
 motion.global_position = motion.position
 root.push_input(motion,true)
 must(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and game.world_mouse_held and game.pointer_over_ui,"segurar clique no mundo e mover ao HUD")
 game.action_timer = 0.01; game.pending = {}; game.queued = false
 game._process(0.02)
 must(game.action_timer <= 0 and game.pending.is_empty(),"HUD bloqueia repetição de ferramenta")
 var up = InputEventMouseButton.new()
 up.button_index = MOUSE_BUTTON_LEFT; up.pressed = false
 up.position = motion.position; up.global_position = up.position
 Input.parse_input_event(up)
 root.push_input(up,true)
 await process_frame
 await key(KEY_ESCAPE)
 must(game.mode == "MODAL" and game.modal == "pause","Esc abre pausa")
 var stamina = game.s.stamina
 await click(find_button(game.ui.root_control,"Opções"))
 must(game.modal == "options" and game.s.stamina == stamina,"clique de menu não usa ferramenta")
 await key(KEY_ESCAPE)
 must(game.modal == "pause","Esc de opções retorna à pausa")
 await click(find_button(game.ui.root_control,"Continuar"))
 await key(KEY_I)
 must(game.modal == "inventory","tecla I abre mochila")
 await click(game.ui.inventory_buttons[6])
 must(game.inventory_cursor == 6 and game.ui.inventory_detail_label.text.contains("Sementes de milho"),"clique real escolhe ícone da semente")
 await key(KEY_RIGHT)
 must(game.inventory_cursor == 7 and game.ui.inventory_detail_label.text.contains("Café"),"seta muda foco e detalhe sem recriar mochila")
 game.audio_player.stop(); game.audio_player.stream = null; game.sounds.clear(); game.asset_textures.clear()
 game.queue_free(); game = null
 await process_frame
 print("INPUT completo")
 quit(1 if failures > 0 else 0)
