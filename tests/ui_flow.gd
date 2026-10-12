extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func find_button(node: Node,name: String) -> Button:
 if node is Button and node.text == name: return node
 for child in node.get_children():
  var found = find_button(child,name)
  if found: return found
 return null
func find_label(node: Node,name: String) -> Label:
 if node is Label and node.text.contains(name): return node
 for child in node.get_children():
  var found = find_label(child,name)
  if found: return found
 return null
func must(value: bool,description: String) -> void:
 if not value: push_error("UI FAIL: "+description); failures += 1
 else: print("UI PASS: "+description)
func event(key: int) -> InputEventKey:
 var e = InputEventKey.new(); e.keycode = key; e.pressed = true; return e
func run() -> void:
 var g = load("res://main.tscn").instantiate(); root.add_child(g)
 await process_frame
 must(find_button(g.ui.root_control,"Nova partida") != null,"título possui botão de mouse")
 find_button(g.ui.root_control,"Opções").pressed.emit(); await process_frame
 must(g.ui.title_options and find_button(g.ui.root_control,"Voltar") != null,"opções do título abrem")
 g._unhandled_input(event(KEY_ESCAPE)); await process_frame
 must(not g.ui.title_options,"Esc volta ao título")
 find_button(g.ui.root_control,"Nova partida").pressed.emit()
 await process_frame
 if g.ui.new_slot_select:
  find_button(g.ui.root_control,"Espaço 1 — substituir partida").pressed.emit(); await process_frame
  find_button(g.ui.root_control,"Substituir espaço 1").pressed.emit(); await process_frame
 must(g.mode == "NAME" and g.name_edit != null,"criação acessível por botão")
 g.name_edit.text = "A"
 find_button(g.ui.root_control,"Começar").pressed.emit(); await process_frame
 must(g.mode == "NAME" and g.name_edit.text == "A" and g.ui.name_error != "","nome inválido preserva campo e explica erro")
 g.name_edit.text = "Ana"
 find_button(g.ui.root_control,"Começar").pressed.emit()
 await process_frame
 must(g.mode == "INTRO" and g.s.name == "Ana","nome inicia partida")
 must(find_label(g.ui.root_control,"Lia se aproxima") != null,"chegada de Lia informada")
 g.lia_arriving = false; g.ui.refresh(); await process_frame
 must(find_label(g.ui.root_control,"Lia e Ana") != null,"fala aparece ao terminar aproximação")
 must(find_button(g.ui.root_control,"Pular apresentação") != null,"abertura possui avançar e pular")
 find_button(g.ui.root_control,"Pular apresentação").pressed.emit()
 await process_frame
 must(g.mode == "PLAY" and g.s.coins == 200,"pular inicia exploração uma vez")
 must(g.ui.hud != null and g.ui.stamina_bar.max_value == g.s.staminaMax,"HUD lê máximo real")
 g._unhandled_input(event(KEY_ESCAPE)); await process_frame
 must(g.mode == "MODAL" and find_button(g.ui.root_control,"Opções") != null,"pausa tem opções")
 var before = g.s.stamina
 var click = InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true
 g._unhandled_input(click)
 must(g.s.stamina == before and g.action_timer == 0,"clique em menu não usa ferramenta")
 find_button(g.ui.root_control,"Opções").pressed.emit(); await process_frame
 must(g.modal == "options","opções abrem por mouse")
 g._unhandled_input(event(KEY_ESCAPE)); await process_frame
 must(g.modal == "pause" and g.mode == "MODAL","Esc de opções mantém pausa")
 find_button(g.ui.root_control,"Continuar").pressed.emit(); await process_frame
 must(g.mode == "PLAY","continuar retorna ao jogo")
 g._unhandled_input(event(KEY_I)); await process_frame
 must(g.modal == "inventory" and find_button(g.ui.root_control,"Consumir") != null,"mochila tem ação clicável")
 g.s.inventory.fiber = 100
 g.s.stamina = 70
 g.ui.refresh(true); await process_frame
 must(g.ui.inventory_buttons.size() == 24,"mochila mostra 24 espaços clicáveis")
 must(g.icon_id("SEED_CORN") != g.icon_id("corn") and g.asset_textures.has(g.icon_id("corn")),"sementes e espiga têm ícones distintos")
 var fiber_slot := -1
 for i in range(24):
  if g.inventory_item_at(i) == "fiber": fiber_slot = i; break
 must(fiber_slot >= 0,"pilha de fibra visível")
 var stack_texts: Array[String] = []
 for offset in [0,1]:
  for child in g.ui.inventory_buttons[fiber_slot+offset].get_children():
   if child is Label: stack_texts.append(child.text)
 must(stack_texts.has("99") and stack_texts.has("1"),"duas pilhas exibem 99 e 1 nos ícones")
 var fiber_button: Button = g.ui.inventory_buttons[fiber_slot]
 fiber_button.grab_focus(); await process_frame
 must(g.inventory_cursor == fiber_slot and g.ui.inventory_detail_label.text.contains("Fibra"),"foco mostra nome completo sem recriar grade")
 must(is_instance_valid(fiber_button) and g.ui.inventory_detail_icon.texture != null,"seleção preserva botão e imagem do item")
 var chosen_style: StyleBoxFlat = fiber_button.get_theme_stylebox("normal")
 must(chosen_style.bg_color == g.ui.ochre,"seleção permanece visível")
 var bar_slot := -1
 for i in range(24):
  if g.inventory_item_at(i) == "bar": bar_slot = i; break
 g.ui.inventory_buttons[bar_slot].grab_focus(); await process_frame
 must(g.ui.inventory_detail_label.text.contains("Barra de cereal") and g.ui.inventory_detail_label.text.contains("30 de estamina"),"alimento mostra recuperação efetiva")
 g.s.stamina = g.s.staminaMax
 g.ui.update_inventory_selection()
 must(g.ui.inventory_detail_label.text.contains("estamina cheia"),"alimento informa bloqueio com estamina cheia")
 g.s.stamina = 70
 var minutes = g.s.minutes
 g._process(21.0)
 must(g.s.minutes == minutes,"mochila pausa relógio")
 find_button(g.ui.root_control,"Fechar").pressed.emit(); await process_frame
 must(g.mode == "PLAY","fechar mochila retorna ao jogo")
 g.mode = "MODAL"; g.modal = "mail"; g.ui.refresh(true); await process_frame
 find_button(g.ui.root_control,"Encomenda").pressed.emit(); await process_frame
 must(find_button(g.ui.root_control,"Guardar 1") != null,"correio permite estoque livre")
 g.mode = "MODAL"; g.modal = "sales"; g.ui.refresh(true); await process_frame
 find_button(g.ui.root_control,"Encaminhar resíduo").pressed.emit(); await process_frame
 must(g.modal == "waste_confirm","descarte exige confirmação")
 g._unhandled_input(event(KEY_ESCAPE)); await process_frame
 must(g.modal == "sales","Esc cancela descarte")
 g.s.mapId = "HOME01"; g.s.position = [11.5,14.5]
 g.mode = "BUILD"; g.modal = ""; g.ui.refresh(true); await process_frame
 must(find_button(g.ui.root_control,"Colocar") != null and find_button(g.ui.root_control,"Girar") != null,"editor possui botões de mouse")
 var editor_start: Vector2i = g.build_preview_tile
 g._unhandled_input(event(KEY_D)); g._process(0.01)
 must(g.build_preview_tile == editor_start+Vector2i.RIGHT and g.build_keyboard_preview,"editor move preview por teclado sem mouse sobrescrever")
 find_button(g.ui.root_control,"Sair").pressed.emit(); await process_frame
 must(g.mode == "PLAY","sair do editor retorna ao jogo")
 var backup: Dictionary = {}
 for i in range(1,4):
  var path: String = g.save_path(i)
  backup[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
  var file = FileAccess.open(path,FileAccess.WRITE)
  file.store_string("reserva-%d" % i)
  file.close()
 g.s = {}; g.mode = "TITLE"; g.ui.refresh(true); await process_frame
 find_button(g.ui.root_control,"Nova partida").pressed.emit(); await process_frame
 must(g.mode == "TITLE" and g.ui.new_slot_select,"três saves exigem escolha de espaço")
 find_button(g.ui.root_control,"Espaço 2 — substituir partida").pressed.emit(); await process_frame
 must(g.ui.overwrite_slot == 2 and FileAccess.get_file_as_string(g.save_path(2)) == "reserva-2","escolha não sobrescreve save")
 find_button(g.ui.root_control,"Substituir espaço 2").pressed.emit(); await process_frame
 must(g.mode == "NAME" and g.slot == 2 and FileAccess.get_file_as_string(g.save_path(2)) == "reserva-2","confirmação entra na criação sem gravar cedo")
 for path in backup:
  if backup[path] == null: DirAccess.remove_absolute(path)
  else:
   var file = FileAccess.open(path,FileAccess.WRITE)
   file.store_buffer(backup[path])
   file.close()
 g.audio_player.stop(); g.audio_player.stream = null; g.sounds.clear(); g.asset_textures.clear()
 g.queue_free(); g = null
 await process_frame
 print("UI completa")
 quit(1 if failures > 0 else 0)
