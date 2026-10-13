extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool,description: String) -> void:
 if not ok:
  push_error("FAIL: "+description)
  quit(1)
 else: print("PASS: "+description)

func act(g: Node,tool: String,p: Vector2i) -> bool:
 g.s.position = [p.x+1,p.y]
 return g.resolve_action(tool,p)

func reachable(g: Node,start: Vector2i,goal: Vector2i) -> bool:
 var open: Array[Vector2i] = [start]
 var seen: Dictionary = {}
 while not open.is_empty():
  var p = open.pop_front()
  if p == goal: return true
  if seen.has(g.key(p)): continue
  seen[g.key(p)] = true
  for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var n = p+d
   if not seen.has(g.key(n)) and g.can_walk(n): open.append(n)
 return false

func run() -> void:
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 check(g.new_game("Ana Maria"),"nome e nova partida")
 check(g.lia_arriving and g.lia_x >= 62.0,"Lia chega pela estrada leste")
 g._process(1.0)
 check(not g.lia_arriving and g.lia_x == 61.0,"Lia se aproxima sem sobrepor jogador")
 g.advance_intro()
 check(g.dialog_index == 1 and not g.intro_letter_seen,"carta abre na abertura")
 g.advance_intro()
 check(g.intro_letter_seen and g.dialog_index == 1,"carta não pula fala")
 g.finish_intro()
 check(g.s.coins == 200 and g.s.inventory.SEED_CORN == 20,"entrega inicial")
 g.finish_intro()
 check(g.s.coins == 200,"entrega idempotente")
 g.mode = "PLAY"; g.s.liaExited = true
 for destination in [Vector2i(49,17),Vector2i(60,14),Vector2i(39,22),Vector2i(24,31)]:
  check(reachable(g,Vector2i(59,12),destination),"rota alcançável %s" % destination)
 var pos = Vector2i(49,16)
 var before = g.s.stamina
 check(not act(g,"TOOL_PICK",pos),"ferramenta incorreta recusada")
 check(g.s.stamina == before,"sem custo com ferramenta incorreta")
 for id in g.REPAIRS:
  g.s.mapId = "FARM01" if id == "H01" else "HOME01"
  pos = g.tile_of(g.REPAIRS[id].at)
  for i in range(g.REPAIRS[id].hits):
   if g.s.stamina < 2: g.s.stamina = 30
   check(act(g,"TOOL_HAMMER",pos),"golpe "+id)
  check(g.s.repairs[id].completed,"reparo "+id)
 check(g.s.mail.wood == 0 and g.s.mail.stone == 0 and g.s.mail.fiber == 0 and g.s.mail.scrap == 0,"orçamento reservado exato")
 for id in g.DIRT:
  pos = g.tile_of(g.DIRT[id])
  before = g.s.stamina
  check(act(g,"HAND",pos),"limpeza "+id)
  check(g.s.stamina == before-1,"limpeza custa estamina")
 for id in g.CONDEMNED:
  pos = g.tile_of(g.CONDEMNED[id])
  for i in range(2):
   if g.s.stamina < 2: g.s.stamina = 30
   check(act(g,"TOOL_AXE",pos),"demolição "+id)
 check(g.house_ready(),"casa requer todos os 20 grupos")
 check(g.placement_error("bench",Vector2i(11,4),0) != "","editor bloqueia passagem")
 g.s.stamina = 20
 check(g.place_furniture("bench",Vector2i(6,7),0),"banco colocado")
 check(g.s.furniture.bench.placed,"banco persistente")
 g.s.mapId = "FARM01"
 g.s.stamina = 0
 before = g.s.coins
 check(not act(g,"TOOL_HOE",Vector2i(40,22)),"sem estamina bloqueia ação")
 check(g.s.coins == before,"sem estamina não gasta moedas")
 g.s.inventory.fruit = 0; g.s.inventory.coffee = 0; g.s.inventory.bar = 0
 g.s.position = [60,15]
 g.take_fruit()
 check(g.s.inventory.fruit > 0,"fruta de segurança")
 check(g.eat("fruit"),"recuperação só por comida")
 for id in g.s.objects:
  if id.begins_with("plot_"): g.s.objects[id].removed = true
 g.s.stamina = 100
 g.s.water = 20
 for y in range(22,26):
  for x in range(40,45):
   pos = Vector2i(x,y)
   check(act(g,"TOOL_HOE",pos),"arado %s" % pos)
   if pos == Vector2i(40,22):
    check(act(g,"TOOL_WATER",pos),"rega antecipada")
   check(act(g,"SEED_CORN",pos),"semeadura %s" % pos)
   if pos != Vector2i(40,22): check(act(g,"TOOL_WATER",pos),"rega %s" % pos)
   if g.s.stamina < 3: g.s.stamina = 100
 check(g.watered_corn_count() == 20,"20 posições únicas regadas")
 before = g.s.water
 check(not act(g,"TOOL_WATER",Vector2i(40,22)),"rega repetida recusada")
 check(g.s.water == before,"rega repetida não gasta água")
 g.s.stamina = 13
 g.s.mapId = "HOME01"
 g.s.position = [12.5,5.5]
 check(g.save_game(1),"save gravado")
 var h = load("res://main.tscn").instantiate()
 root.add_child(h)
 await process_frame
 check(h.load_game(1),"save recarregado")
 check(h.s.stamina == 13 and h.watered_corn_count() == 20 and h.house_ready(),"estado completo persistido")
 h.close_night()
 check(h.s.completed and h.s.day == 2,"conclusão após manhã")
 check(h.s.stamina == 13,"sono não recupera estamina")
 check(h.s.soil["40,22"].cropAge == 1,"milho cresceu uma vez")
 h.close_night()
 check(h.s.day == 3 and h.s.soil["40,22"].cropAge == 1,"milho sem água não cresce")
 h.s.mapId = "FARM01"
 var tree = h.s.objects["tree_15"]
 var tp = h.tile_of(tree.at)
 h.s.stamina = 40
 for i in range(5): check(act(h,"TOOL_AXE",tp),"árvore: golpe parcial")
 check(h.save_game(1),"golpe parcial salvo")
 var t = load("res://main.tscn").instantiate()
 root.add_child(t)
 await process_frame
 check(t.load_game(1),"golpe parcial recarregado")
 check(t.s.objects["tree_15"].hits == 1,"resistência parcial persistida")
 check(act(t,"TOOL_AXE",tp),"copa derrubada")
 check(t.s.objects["tree_15"].kind == "stump","toco persistente")
 var drops_before = t.s.drops.size()
 check(t.save_game(1),"toco salvo")
 check(t.load_game(1),"toco recarregado")
 check(t.s.drops.size() == drops_before,"drop da copa sem duplicação")
 for i in range(2): check(act(t,"TOOL_AXE",tp),"toco golpe")
 check(t.s.objects["tree_15"].removed,"toco removido")
 check(t.s.drops.size() > drops_before,"drop do toco separado")
 t.s.inventory.wood = 1
 t.s.inventory.fiber = 1
 t.s.inventory.scrap = 1
 check(t.ship_one("fiber") and t.withdraw_one("fiber"),"fibra enviável e retirável")
 check(t.ship_one("scrap") and t.withdraw_one("scrap"),"sucata enviável e retirável")
 check(t.ship_one("wood"),"venda enviada")
 var coins_before = t.s.coins
 t.close_night()
 check(t.s.coins == coins_before+2,"venda liquidada uma vez")
 check(t.save_game(1) and t.load_game(1),"noite salva e recarregada")
 check(t.s.coins == coins_before+2,"sem duplicar receita no carregamento")
 var z = load("res://main.tscn").instantiate()
 root.add_child(z)
 await process_frame
 z.new_game("Bia")
 var arrival_position = z.s.position.duplicate()
 z.skip_intro()
 z.skip_intro()
 check(z.s.liaExited and z.mode == "PLAY" and z.lia_x == 63.0,"pular posiciona Lia na saída")
 check(z.s.position == arrival_position and z.s.coins == 200,"pular preserva posição e entrega única")
 z.s.position = [49.5,17.9]
 z.repair_target = Vector2i(49,16)
 z.mode = "MODAL"; z.modal = "repair"
 var key_event = InputEventKey.new()
 key_event.pressed = true; key_event.keycode = KEY_SPACE
 z._unhandled_input(key_event)
 check(z.s.mail.wood == 20 and z.action_timer > 0,"reparo reserva apenas no contato")
 z._process(0.6)
 check(z.s.mail.wood == 12 and z.s.repairs.H01.hitsDone == 1,"confirmação inicia reparo")
 z.s.inventory.wood = 3
 check(z.deposit_storage("wood") and z.s.storage.wood == 1,"estoque livre recebe madeira")
 check(z.withdraw_storage("wood") and z.s.inventory.wood == 3,"retirada do estoque livre")
 check(z.assign_hotbar(7,"coffee") and z.s.hotbar[7] == "coffee","atalho configurável")
 check(z.inventory_items().size() <= 24 and z.inventory_item_at(0) == "TOOL_AXE","mochila em grade de 24")
 check(not z.inventory_items().has("HAND"),"mão livre não ocupa mochila")
 z.s.inventory.fiber = 99
 check(z.can_add("fiber",1),"segunda pilha permitida")
 z.s.inventory.fiber = 100
 var fiber_first = z.inventory_items().find("fiber")
 check(z.inventory_quantity_at(fiber_first) == 99 and z.inventory_quantity_at(fiber_first+1) == 1,"pilhas mostram 99 e 1")
 check(z.occupied_slots() == z.inventory_items().size(),"slots visuais e lógicos correspondem")
 z.s.stamina = 20
 z.food_timer = 0.0; z.food_pending = ""
 var coffee_before = z.s.inventory.coffee
 check(z.eat("coffee") and z.s.stamina == 20,"alimento inicia gesto sem recuperação antecipada")
 z._process(0.81)
 check(z.s.stamina == 80 and z.s.inventory.coffee == coffee_before-1,"alimento recupera no fim do gesto uma vez")
 z.change_option(KEY_1)
 z.change_option(KEY_2)
 z.change_option(KEY_3)
 check(z.s.preferences.uiScale == 1.25 and z.s.preferences.highContrast and not z.s.preferences.repeatAction,"opções de UI e ação")
 z.s.erase("preferences"); z.s.erase("hotbar"); z.s.erase("storage")
 check(z.save_game(3) and z.load_game(3),"save legado carregado")
 check(z.s.preferences.uiScale == 1.0 and z.s.hotbar.size() == 8 and z.s.storage.is_empty(),"defaults migrados")
 print("QA completa")
 for n in [g,h,t,z]:
  n.audio_player.stop()
  n.audio_player.stream = null
  n.sounds.clear()
  n.asset_textures.clear()
 g.queue_free(); h.queue_free(); t.queue_free(); z.queue_free()
 g = null; h = null; t = null; z = null
 await process_frame
 quit(0)
