extends Node2D
## Boa Sorte, cenário 01. Estado serializável separado do desenho provisório.
const TILE := 32
const SIZE := Vector2i(640, 360)
const SAVE_SCHEMA := 1
const TOOLS := ["TOOL_AXE", "TOOL_PICK", "TOOL_HOE", "TOOL_SCYTHE", "TOOL_WATER", "TOOL_HAMMER", "SEED_CORN", "HAND"]
const TOOL_NAMES := ["Machado", "Picareta", "Enxada", "Foice", "Regador", "Martelo", "Milho", "Mão"]
const FOOD := {"coffee":60, "bar":40, "fruit":20}
const WEIGHTS := {"wood":0.5,"stone":0.75,"fiber":0.1,"scrap":0.25,"waste":0.05,"SEED_CORN":0.05,"corn":0.2,"coffee":0.1,"bar":0.2,"fruit":0.05,"bench":2.0}
const PRICES := {"wood":2,"stone":2,"fiber":1,"scrap":3,"corn":10}
const REPAIRS := {
 "H01":{"name":"Telhado e fachada","hits":6,"cost":{"wood":8,"stone":6},"at":[49,16]},
 "H02":{"name":"Paredes e piso","hits":4,"cost":{"wood":2,"stone":4},"at":[5,5]},
 "H03":{"name":"Janelas","hits":3,"cost":{"wood":4},"at":[10,3]},
 "H04":{"name":"Cama","hits":2,"cost":{"wood":2,"fiber":2},"at":[19,7]},
 "H05":{"name":"Sofá","hits":2,"cost":{"wood":2,"fiber":1},"at":[8,10]},
 "H06":{"name":"Fogão","hits":2,"cost":{"stone":2,"scrap":2},"at":[3,3]},
 "H07":{"name":"Pia","hits":2,"cost":{"wood":2,"scrap":1},"at":[6,3]}}
const DIRT := {"dirt_web":[3,8],"dirt_dust":[6,11],"dirt_papers":[12,10],"dirt_rubble":[17,11],"dirt_rug":[10,13],"dirt_utensils":[4,6]}
const CONDEMNED := {"old_table":[11,6],"old_chair_a":[12,6],"old_chair_b":[11,7],"old_cabinet":[2,5],"old_shelf":[13,4],"old_low_table":[7,12],"old_wardrobe":[21,11]}
const FURNITURE := {"bed":{"at":[19,7],"size":[2,3],"repair":"H04"},"sofa":{"at":[8,10],"size":[3,1],"repair":"H05"},"stove":{"at":[3,3],"size":[1,1],"repair":"H06"},"sink":{"at":[6,3],"size":[3,1],"repair":"H07"},"bench":{"at":[0,0],"size":[1,1],"repair":""}}
const LETTER := "Olá, {name}! Seja bem-vindo a Boa Sorte. É uma alegria saber que a fazenda de seu avô Olegário vai receber cuidado novamente. Espero que você encontre aqui um bom lugar para viver e começar essa nova jornada. Enviei ferramentas, materiais para os primeiros consertos, 200 moedas e 20 sementes de milho. Assim que terminar a reforma da casa, passe na minha residência para conversarmos. Desejo trabalho proveitoso e muita sorte nesse começo. Um abraço, Jair, prefeito de Boa Sorte."
const DIALOGUE := [
 "Lia: Você deve ser {name}. Sou Lia, dos correios. Trouxe uma carta do prefeito Jair e uma encomenda para você.",
 "Você: Obrigado, Lia. Faz tempo que ninguém cuida deste lugar?",
 "Lia: A fazenda ficou fechada por um bom tempo. Muita gente por aqui ainda se lembra de seu avô Olegário.",
 "Lia: Boa Sorte é pequena. A gente se conhece, e notícia acaba chegando junto com a correspondência. Eu passo entregando cartas por estas bandas.",
 "Você: E o prefeito?",
 "Lia: O senhor Jair pediu para lhe dar as boas-vindas. A carta explica: depois de arrumar a casa, ele quer conversar com você.",
 "Lia: Tem também regador e martelo no kit. Guarde os materiais para a reforma. Se cansar, coma alguma coisa: café dá mais energia, barra de cereal um pouco menos, fruta menos ainda. Deixei uma cesta de umbus junto ao correio para ajudar se a comida acabar.",
 "Você: Vou começar pela casa e pelo milho.",
 "Lia: Boa ideia. Tente deixar tudo pronto antes de escurecer. Vou continuar minhas entregas. Até mais!"]
var s: Dictionary = {}
var mode := "TITLE"
var slot := 1
var dialog_index := 0
var intro_letter_seen := false
var modal := ""
var message := ""
var message_timer := 0.0
var action_timer := 0.0
var pending: Dictionary = {}
var food_timer := 0.0
var food_pending := ""
var queued := false
var clock_accumulator := 0.0
var auto_save_accumulator := 0.0
var move_weight_accumulator := 0.0
var transition_cooldown := 0.0
var lia_x := 63.0
var lia_arriving := false
var lia_leaving := false
var camera_origin := Vector2.ZERO
var selected := 0
var inventory_cursor := 0
var editor_item := ""
var editor_rotation := 0
var repair_target := Vector2i.ZERO
var name_edit: LineEdit
var font: Font
var asset_manifest: Dictionary = {}
var asset_textures: Dictionary = {}
var sounds: Dictionary = {}
var audio_player: AudioStreamPlayer
var elapsed := 0.0

func _ready() -> void:
 font = ThemeDB.fallback_font
 load_assets()
 audio_player = AudioStreamPlayer.new()
 audio_player.volume_db = -9.0
 add_child(audio_player)
 name_edit = LineEdit.new()
 name_edit.position = Vector2(205, 157)
 name_edit.size = Vector2(230, 30)
 name_edit.placeholder_text = "Seu nome (2–20 caracteres)"
 name_edit.max_length = 20
 add_child(name_edit)
 name_edit.text_submitted.connect(func(value: String): new_game(value))
 name_edit.hide()
 if OS.has_feature("headless"):
  get_viewport().set_update_mode(SubViewport.UPDATE_ALWAYS)
 queue_redraw()

func reset_pending_actions() -> void:
 action_timer = 0.0
 pending = {}
 queued = false
 food_timer = 0.0
 food_pending = ""
 auto_save_accumulator = 0.0
 move_weight_accumulator = 0.0

func new_game(player_name: String) -> bool:
 player_name = player_name.strip_edges()
 if player_name.length() < 2 or player_name.length() > 20:
  say("Nome: use de 2 a 20 caracteres.")
  return false
 reset_pending_actions()
 s = {"schemaVersion":SAVE_SCHEMA,"name":player_name,"mapId":"FARM01","position":[59.5,12.9],"facing":[-1,0],"day":1,"minutes":480,"hp":100,"hpMax":100,"stamina":100,"staminaMax":100,"level":1,"xp":0,"coins":0,"inventory":{},"hotbar":TOOLS.duplicate(),"water":20,"repairs":{},"dirt":{},"condemned":{},"objects":{},"soil":{},"drops":{},"furniture":{},"mail":{"wood":20,"stone":12,"fiber":3,"scrap":3,"bench":1},"storage":{},"shipment":{},"fruitTaken":0,"arrivalGranted":false,"liaExited":false,"validSleepDay":0,"completed":false,"lateNoted":false,"nightTransactionId":0,"morningSeen":false,"preferences":{"uiScale":1.0,"effectsVolume":0.75,"highContrast":false,"repeatAction":true}}
 for id in REPAIRS: s.repairs[id] = {"hitsDone":0,"paid":false,"completed":false}
 for id in DIRT: s.dirt[id] = false
 for id in CONDEMNED: s.condemned[id] = 2
 for id in FURNITURE:
  var f = FURNITURE[id]
  s.furniture[id] = {"at":f.at.duplicate(),"rotation":0,"placed":id != "bench"}
 make_objects()
 mode = "INTRO"
 if audio_player: audio_player.volume_db = linear_to_db(float(s.preferences.effectsVolume))
 dialog_index = 0
 intro_letter_seen = false
 lia_x = 63.0
 lia_arriving = true
 lia_leaving = false
 name_edit.hide()
 queue_redraw()
 return true

func make_objects() -> void:
 # Stable IDs and deterministic positions. Tutorial plot contains exactly 8 removable props.
 var plot = [[40,22,"bush"],[42,22,"bush"],[40,25,"bush"],[44,24,"bush"],[41,23,"stick"],[43,25,"stick"],[42,24,"stone_small"],[44,22,"stone_medium"]]
 var counts = {"tree":48,"bush":20,"mandacaru":6,"cactus":6,"stone_small":11,"stone_medium":7,"stone_large":4,"stick":10,"log":8,"trash_metal":8,"trash_plastic":7}
 var index := 0
 for row in plot:
  add_object("plot_%02d" % index, row[2], Vector2i(row[0],row[1]))
  index += 1
 var rng = RandomNumberGenerator.new()
 rng.seed = 1906
 for kind in counts:
  for i in counts[kind]:
   var p := Vector2i.ZERO
   for attempt in 1200:
    p = Vector2i(rng.randi_range(2,61),rng.randi_range(3,45))
    if is_clear_spawn(p): break
   add_object("%s_%02d" % [kind,i],kind,p,i)

func add_object(id: String, kind: String, p: Vector2i, variant := 0) -> void:
 var hits := 1
 var tree_stage: int = (variant / 4) % 4
 match kind:
  "tree": hits = [1,2,4,6][tree_stage]
  "stone_medium","log","mandacaru": hits = 3
  "stone_large": hits = 5
  "cactus": hits = 2
 s.objects[id] = {"kind":kind,"at":[p.x,p.y],"hits":hits,"maxHits":hits,"stage":tree_stage if kind == "tree" else 0,"variant":variant,"removed":false,"dropCreated":false}

func is_clear_spawn(p: Vector2i) -> bool:
 if p.x >= 39 and p.x <= 45 and p.y >= 21 and p.y <= 26: return false
 if p.x >= 43 and p.x <= 56 and p.y >= 5 and p.y <= 18: return false
 if p.x >= 56 and p.y >= 9 and p.y <= 17: return false
 if p.x >= 8 and p.x <= 23 and p.y >= 31 and p.y <= 41: return false
 if p.x >= 8 and p.x <= 17 and p.y >= 8 and p.y <= 15: return false
 if p.x >= 23 and p.x <= 50 and p.y >= 17 and p.y <= 21: return false
 if p.x >= 23 and p.x <= 39 and p.y >= 22 and p.y <= 31: return false
 for id in s.objects:
  if tile_of(s.objects[id].at) == p: return false
 return true

func _process(delta: float) -> void:
 elapsed += delta
 transition_cooldown = maxf(0.0,transition_cooldown-delta)
 if mode == "PLAY":
  process_movement(delta)
  clock_accumulator += delta
  auto_save_accumulator += delta
  if clock_accumulator >= 20.0:
   clock_accumulator -= 20.0
   s.minutes += 10
   if s.minutes >= 1440: close_night()
   elif s.minutes >= 1080 and not s.lateNoted and not s.completed:
    s.lateNoted = true
    say("Ainda dá para continuar. Amanhã você termina com calma.")
  if auto_save_accumulator >= 30.0:
   auto_save_accumulator = 0.0
   save_game(slot)
  if action_timer > 0:
   action_timer -= delta
   if action_timer <= 0:
    if not pending.is_empty():
     resolve_action(pending.tool, tile_of(pending.target))
     pending = {}
    if queued:
     queued = false
     begin_action()
    elif s.preferences.get("repeatAction",true) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
     begin_action()
  if food_timer > 0:
   food_timer -= delta
   if food_timer <= 0 and food_pending != "": finish_eating()
  gather_near_drops()
 elif mode == "INTRO":
  if lia_arriving:
   lia_x -= delta * 3.2
   if lia_x <= 61.0:
    lia_x = 61.0
    lia_arriving = false
  elif lia_leaving:
   lia_x += delta * 3.2
   if lia_x >= 63.0:
    lia_x = 63.0
    lia_leaving = false
    s.liaExited = true
    mode = "PLAY"
    save_game(slot)
    say("Um novo começo: restaure a casa e plante 20 milhos.")
 if message_timer > 0: message_timer -= delta
 queue_redraw()

func process_movement(delta: float) -> void:
 if action_timer > 0 or food_timer > 0: return
 var v = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
 v += Vector2(float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A)),float(Input.is_key_pressed(KEY_S))-float(Input.is_key_pressed(KEY_W)))
 if v.length() > 1: v = v.normalized()
 if v == Vector2.ZERO: return
 var factor := 1.0
 if s.stamina <= 0: factor *= 0.5
 elif s.stamina < s.staminaMax * 0.2: factor *= 0.7
 var weight = carried_weight()
 if weight > 40: factor *= 0.8
 factor = maxf(0.4,factor)
 var old = Vector2(s.position[0],s.position[1])
 var candidate = old + v * 120.0 * factor * delta / TILE
 if can_walk(Vector2i(floori(candidate.x),floori(candidate.y))):
  s.position = [candidate.x,candidate.y]
  if weight >= 32:
   move_weight_accumulator += delta
   if move_weight_accumulator >= 10:
    move_weight_accumulator -= 10
    s.stamina = maxi(0,s.stamina-1)
 if absf(v.x) > absf(v.y): s.facing = [1 if v.x > 0 else -1,0]
 else: s.facing = [0,1 if v.y > 0 else -1]

func can_walk(p: Vector2i) -> bool:
 if s.mapId == "FARM01":
  if p.x < 0 or p.x >= 64 or p.y < 0 or p.y >= 48: return false
  if is_lake(p) or (p.x >= 8 and p.x <= 17 and p.y >= 8 and p.y <= 15): return false
  if p.x >= 44 and p.x <= 55 and p.y >= 7 and p.y <= 15: return false
  for id in s.objects:
   var ob = s.objects[id]
   if not ob.removed and tile_of(ob.at) == p: return false
  return true
 if p.x < 1 or p.x > 22 or p.y < 1 or p.y > 16: return false
 if p.x == 15 and (p.y < 7 or p.y > 9): return false
 for id in CONDEMNED:
  if s.condemned[id] > 0 and tile_of(CONDEMNED[id]) == p: return false
 for id in s.furniture:
  if furniture_covers(id,p): return false
 return true

func furniture_size(id: String, rot: int) -> Vector2i:
 var base = tile_of(FURNITURE[id].size)
 return Vector2i(base.y,base.x) if rot % 2 else base

func furniture_covers(id: String, p: Vector2i) -> bool:
 var f = s.furniture[id]
 if not f.placed: return false
 var at = tile_of(f.at)
 var size = furniture_size(id,f.rotation)
 return p.x >= at.x and p.x < at.x+size.x and p.y >= at.y and p.y < at.y+size.y

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if mode == "TITLE":
   if event.keycode >= KEY_1 and event.keycode <= KEY_3:
    slot = event.keycode - KEY_0
    if FileAccess.file_exists(save_path(slot)): load_game(slot)
    else: mode = "NAME"; name_edit.show(); name_edit.grab_focus()
   elif event.keycode == KEY_N: mode = "NAME"; name_edit.show(); name_edit.grab_focus()
  elif mode == "NAME":
   if event.keycode == KEY_ENTER: new_game(name_edit.text)
   elif event.keycode == KEY_ESCAPE: mode = "TITLE"; name_edit.hide()
  elif mode == "INTRO":
   if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER: advance_intro()
   elif event.keycode == KEY_ESCAPE: skip_intro()
  elif mode == "PLAY":
   if event.keycode >= KEY_1 and event.keycode <= KEY_8: selected = event.keycode - KEY_1
   elif event.keycode == KEY_E: interact()
   elif event.keycode == KEY_I: mode = "MODAL"; modal = "inventory"; inventory_cursor = 0
   elif event.keycode == KEY_J: mode = "MODAL"; modal = "journal"
   elif event.keycode == KEY_B and s.mapId == "HOME01": mode = "BUILD"; editor_item = ""; editor_rotation = 0
   elif event.keycode == KEY_ESCAPE: mode = "MODAL"; modal = "pause"
   elif event.keycode == KEY_F5: save_game(slot); say("Partida salva.")
   elif event.keycode == KEY_F9: load_game(slot)
  elif mode == "MODAL":
   if event.keycode == KEY_ESCAPE or event.keycode == KEY_I or event.keycode == KEY_J: mode = "PLAY"; modal = ""
   elif modal == "inventory" and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
    var step = -1 if event.keycode == KEY_LEFT else 1 if event.keycode == KEY_RIGHT else -6 if event.keycode == KEY_UP else 6
    inventory_cursor = clampi(inventory_cursor+step,0,23)
   elif modal == "inventory" and event.keycode == KEY_ENTER:
    var item = inventory_item_at(inventory_cursor)
    if FOOD.has(item): eat(item)
    else: say("Selecione alimento para consumir.")
   elif modal == "inventory" and event.keycode == KEY_0: assign_hotbar(selected,"HAND")
   elif modal == "options": change_option(event.keycode)
   elif modal == "pause" and event.keycode == KEY_O: modal = "options"
   elif modal == "mail" and event.keycode >= KEY_4 and event.keycode <= KEY_9:
    var stock_item = ["wood","stone","fiber","scrap","corn","waste"][event.keycode-KEY_4]
    if event.shift_pressed: withdraw_storage(stock_item)
    else: deposit_storage(stock_item)
   elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
    if modal == "inventory": assign_hotbar(event.keycode-KEY_1,inventory_item_at(inventory_cursor))
    elif modal == "mail":
     if event.keycode == KEY_1: take_fruit()
     if event.keycode == KEY_2: buy_food("coffee",25)
     if event.keycode == KEY_3: buy_food("bar",15)
    elif modal == "sales":
     var item = ["wood","stone","fiber","scrap","corn"][event.keycode-KEY_1]
     if event.shift_pressed: withdraw_one(item)
     else: ship_one(item)
   elif event.keycode == KEY_SPACE and modal == "sleep": mode = "PLAY"; close_night()
   elif event.keycode == KEY_SPACE and modal == "repair":
    mode = "PLAY"; modal = ""
    if action_check("TOOL_HAMMER",repair_target) == "":
     pending = {"tool":"TOOL_HAMMER","target":[repair_target.x,repair_target.y]}
     action_timer = 0.55
   elif event.keycode == KEY_S and modal == "pause": save_game(slot); say("Partida salva.")
   elif modal == "inventory" and event.keycode >= KEY_6 and event.keycode <= KEY_8:
    assign_hotbar(event.keycode-KEY_1,inventory_item_at(inventory_cursor))
  elif mode == "BUILD":
   if event.keycode == KEY_ESCAPE: editor_item = ""; mode = "PLAY"
   elif event.keycode == KEY_R: editor_rotation = (editor_rotation+1)%4
   elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
    editor_item = ["bed","sofa","stove","sink","bench"][event.keycode-KEY_1]
    editor_rotation = s.furniture[editor_item].rotation
 if event is InputEventMouseButton and event.pressed:
  if mode == "PLAY":
   if event.button_index == MOUSE_BUTTON_LEFT: begin_action()
   elif event.button_index == MOUSE_BUTTON_RIGHT: interact()
   elif event.button_index == MOUSE_BUTTON_WHEEL_UP: selected = (selected+7)%8
   elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: selected = (selected+1)%8
  elif mode == "BUILD" and event.button_index == MOUSE_BUTTON_LEFT and editor_item != "":
   place_furniture(editor_item, screen_tile(event.position), editor_rotation)
  elif mode == "INTRO" and event.button_index == MOUSE_BUTTON_LEFT: advance_intro()

func advance_intro() -> void:
 if lia_leaving or lia_arriving: return
 if dialog_index == 1 and not intro_letter_seen:
  intro_letter_seen = true
  return
 dialog_index += 1
 if dialog_index >= DIALOGUE.size(): finish_intro()

func finish_intro() -> void:
 lia_arriving = false
 if not s.arrivalGranted:
  s.arrivalGranted = true
  s.coins = 200
  s.inventory = {"SEED_CORN":20,"coffee":2,"bar":2,"fruit":4}
  save_game(slot)
 dialog_index = DIALOGUE.size()
 lia_leaving = true

func skip_intro() -> void:
 finish_intro()
 lia_arriving = false
 lia_leaving = false
 lia_x = 63.0
 s.liaExited = true
 mode = "PLAY"
 save_game(slot)
 say("Um novo começo: restaure a casa e plante 20 milhos.")

func target_tile() -> Vector2i:
 var p = tile_of(s.position)
 var mouse_world = (get_viewport().get_mouse_position()+camera_origin)/TILE
 var diff = mouse_world - Vector2(p)
 if absf(diff.x) > absf(diff.y): return p + Vector2i(1 if diff.x >= 0 else -1,0)
 return p + Vector2i(0,1 if diff.y >= 0 else -1)

func selected_item() -> String:
 return str(s.hotbar[selected]) if s.has("hotbar") and s.hotbar.size() == 8 else TOOLS[selected]

func begin_action() -> void:
 if mode != "PLAY": return
 if action_timer > 0:
  queued = true
  return
 var target = target_tile()
 var tool: String = selected_item()
 if FOOD.has(tool): eat(tool); return
 if not TOOLS.has(tool): say("Este item não é usado como ferramenta."); return
 var check = action_check(tool,target)
 if check != "": say(check); return
 if tool == "TOOL_HAMMER":
  var repair_id = repair_at(target)
  if repair_id != "" and not s.repairs[repair_id].paid:
   repair_target = target
   mode = "MODAL"
   modal = "repair"
   return
 pending = {"tool":tool,"target":[target.x,target.y]}
 action_timer = {"TOOL_AXE":0.70,"TOOL_PICK":0.70,"TOOL_HOE":0.55,"TOOL_SCYTHE":0.65,"TOOL_WATER":0.55,"TOOL_HAMMER":0.55,"SEED_CORN":0.45,"HAND":0.45}[tool]

func action_check(tool: String, p: Vector2i) -> String:
 if abs(p.x-floori(s.position[0]))+abs(p.y-floori(s.position[1])) != 1: return "Alvo fora de alcance."
 var cost = {"TOOL_AXE":2,"TOOL_PICK":2,"TOOL_HOE":2,"TOOL_SCYTHE":1,"TOOL_WATER":2,"TOOL_HAMMER":2,"SEED_CORN":1,"HAND":0}[tool]
 if s.stamina < cost: return "Falta %d de estamina. Coma ou procure umbu no correio." % (cost-s.stamina)
 if tool == "TOOL_HAMMER":
  var id = repair_at(p)
  if id == "": return "Não há reparo nesse tile."
  if s.repairs[id].completed: return "Este serviço já está pronto."
  if not s.repairs[id].paid and not has_repair_material(id): return "Faltam materiais na encomenda."
  return ""
 if tool == "TOOL_HOE":
  if not tillable(p): return "Solo ocupado ou não cultivável."
  if s.soil.has(key(p)) and s.soil[key(p)].tilled: return "Solo já arado."
  return ""
 if tool == "SEED_CORN":
  if int(s.inventory.get("SEED_CORN",0)) <= 0: return "Não há sementes."
  if not s.soil.has(key(p)) or not s.soil[key(p)].tilled or s.soil[key(p)].cropId != "": return "Prepare solo vazio com a enxada."
  return ""
 if tool == "TOOL_WATER":
  if s.water <= 0: return "Reabasteça no lago."
  if not s.soil.has(key(p)) or not s.soil[key(p)].tilled: return "Regue solo arado."
  if s.soil[key(p)].wateredDayId == s.day: return "Você já regou hoje."
  return ""
 if s.mapId == "HOME01":
  var c = condemned_at(p)
  var d = dirt_at(p)
  if c != "": return "" if tool == "TOOL_AXE" else "Use o machado."
  if d != "": return ("" if s.stamina >= 1 else "Falta 1 de estamina.") if tool == "HAND" else "Limpe com a mão livre."
  if repair_at(p) != "": return "Este móvel será reparado. Use o martelo."
 var obid = object_at(p)
 if obid != "":
  var kind = s.objects[obid].kind
  var required = "HAND" if kind.begins_with("trash") else "TOOL_PICK" if kind.begins_with("stone") else "TOOL_SCYTHE" if kind in ["bush","mandacaru","cactus"] else "TOOL_AXE"
  if required == "HAND" and s.stamina < 1: return "Falta 1 de estamina."
  if required != tool: return "Use %s." % {"HAND":"a mão livre","TOOL_PICK":"a picareta","TOOL_SCYTHE":"a foice","TOOL_AXE":"o machado"}[required]
  return ""
 if tool == "HAND" and s.soil.has(key(p)) and s.soil[key(p)].cropId == "crop_corn" and s.soil[key(p)].cropAge >= 4: return "" if s.stamina >= 1 else "Falta 1 de estamina."
 return "Não há alvo para esta ação."

func resolve_action(tool: String, p: Vector2i) -> bool:
 var error = action_check(tool,p)
 if error != "": say(error); return false
 var cost = {"TOOL_AXE":2,"TOOL_PICK":2,"TOOL_HOE":2,"TOOL_SCYTHE":1,"TOOL_WATER":2,"TOOL_HAMMER":2,"SEED_CORN":1,"HAND":0}[tool]
 if tool == "TOOL_HAMMER":
  var id = repair_at(p)
  if not s.repairs[id].paid:
   for material in REPAIRS[id].cost: s.mail[material] -= REPAIRS[id].cost[material]
   s.repairs[id].paid = true
  s.repairs[id].hitsDone += 1
  if s.repairs[id].hitsDone >= REPAIRS[id].hits:
   s.repairs[id].completed = true
   award_xp(3)
   say("%s restaurado!" % REPAIRS[id].name)
   save_game(slot)
  else: say("%s: %d/%d" % [REPAIRS[id].name,s.repairs[id].hitsDone,REPAIRS[id].hits])
 elif tool == "TOOL_HOE":
  s.soil[key(p)] = {"tilled":true,"wateredDayId":0,"cropId":"","cropAge":0,"seedOrigin":"","tutorialPlantTracked":false,"xpCycle":true}
  award_xp(1)
  say("Terra preparada.")
 elif tool == "SEED_CORN":
  s.inventory.SEED_CORN -= 1
  s.soil[key(p)].cropId = "crop_corn"
  s.soil[key(p)].seedOrigin = "intro" if not s.completed else "free"
  if s.soil[key(p)].wateredDayId == s.day and not s.completed: s.soil[key(p)].tutorialPlantTracked = true
  award_xp(1)
  say("Milho plantado.")
 elif tool == "TOOL_WATER":
  s.water -= 1
  s.soil[key(p)].wateredDayId = s.day
  if s.soil[key(p)].cropId == "crop_corn" and s.soil[key(p)].seedOrigin == "intro": s.soil[key(p)].tutorialPlantTracked = true
  award_xp(1)
  say("Terra regada. %d/20" % watered_corn_count())
 elif s.mapId == "HOME01" and condemned_at(p) != "":
  var c = condemned_at(p)
  s.condemned[c] -= 1
  if s.condemned[c] <= 0:
   create_drop("wood",2,p,"HOME01")
   award_xp(2)
   say("Móvel condenado removido. +2 madeira")
 elif s.mapId == "HOME01" and dirt_at(p) != "":
  cost = 1
  s.dirt[dirt_at(p)] = true
  award_xp(1)
  say("Área limpa.")
 elif object_at(p) != "":
  var id = object_at(p)
  var ob = s.objects[id]
  if ob.kind.begins_with("trash"): cost = 1
  ob.hits -= 1
  if ob.hits <= 0:
   if ob.kind == "tree" and ob.stage == 3:
    ob.kind = "stump"; ob.hits = 2; ob.maxHits = 2
    drop_object(id,"tree_adult",p)
    ob.dropCreated = false
   else:
    ob.removed = true
    drop_object(id,ob.kind,p)
 elif tool == "HAND" and s.soil.has(key(p)):
  cost = 1
  s.soil[key(p)].cropId = ""
  s.soil[key(p)].cropAge = 0
  create_drop("corn",2,p,s.mapId)
  award_xp(2)
  say("Milho colhido. +2")
 s.stamina -= cost
 if tool.begins_with("TOOL_"): play_sound("tool_"+tool.trim_prefix("TOOL_").to_lower())
 else: play_sound("collect")
 queue_redraw()
 return true

func has_repair_material(id: String) -> bool:
 for material in REPAIRS[id].cost:
  if int(s.mail.get(material,0)) < int(REPAIRS[id].cost[material]): return false
 return true

func drop_object(id: String, kind: String, p: Vector2i) -> void:
 if s.objects[id].dropCreated: return
 s.objects[id].dropCreated = true
 var drops: Dictionary = {}
 var xp := 1
 match kind:
  "tree_adult": drops = {"wood":8}; xp = 8
  "stump": drops = {"wood":2}; xp = 2
  "tree":
   var stage: int = s.objects[id].stage
   drops = [{"fiber":1},{"wood":1,"fiber":1},{"wood":4},{"wood":8}][stage]
   xp = [1,2,5,8][stage]
  "stick": drops = {"wood":1}
  "log": drops = {"wood":4}; xp = 3
  "stone_small": drops = {"stone":1}
  "stone_medium": drops = {"stone":3}; xp = 3
  "stone_large": drops = {"stone":6}; xp = 5
  "bush": drops = {"fiber":2}
  "mandacaru": drops = {"fiber":3}; xp = 2
  "cactus": drops = {"fiber":2}; xp = 2
  "trash_metal": drops = {"scrap":1}
  "trash_plastic": drops = {"waste":1}
 for item in drops: create_drop(item,drops[item],p,s.mapId)
 award_xp(xp)
 say("Recurso coletável no chão.")

func create_drop(item: String, amount: int, p: Vector2i, map_id: String) -> void:
 var id = "%s_%s_%s_%d" % [map_id,key(p),item,s.drops.size()]
 s.drops[id] = {"item":item,"amount":amount,"at":[p.x,p.y],"mapId":map_id}

func gather_near_drops() -> void:
 var here = Vector2(s.position[0],s.position[1])
 for id in s.drops.keys():
  var d = s.drops[id]
  if d.mapId != s.mapId or here.distance_to(Vector2(d.at[0],d.at[1])) > 1.35: continue
  if can_add(d.item,d.amount):
   s.inventory[d.item] = int(s.inventory.get(d.item,0))+d.amount
   s.drops.erase(id)
   play_sound("collect")

func can_add(item: String, amount: int) -> bool:
 var current = int(s.inventory.get(item,0))
 var before = ceili(float(current)/99.0)
 var after = ceili(float(current+amount)/99.0)
 if occupied_slots()-before+after > 24: return false
 return carried_weight()+float(WEIGHTS.get(item,0))*amount <= 48.0

func occupied_slots() -> int:
 var count := 6
 for item in s.inventory:
  if int(s.inventory[item]) > 0: count += ceili(float(s.inventory[item])/99.0)
 return count

func inventory_items() -> Array[String]:
 var items: Array[String] = []
 for id in TOOLS.slice(0,6): items.append(id)
 for id in ["SEED_CORN","coffee","bar","fruit","wood","stone","fiber","scrap","waste","corn"]:
  for stack in ceili(float(s.inventory.get(id,0))/99.0): items.append(id)
 for id in s.inventory:
  if int(s.inventory[id]) > 0 and not items.has(id):
   for stack in ceili(float(s.inventory[id])/99.0): items.append(id)
 return items

func inventory_item_at(index: int) -> String:
 var items = inventory_items()
 return items[index] if index >= 0 and index < items.size() else ""

func inventory_quantity_at(index: int) -> int:
 var item = inventory_item_at(index)
 if item == "" or item.begins_with("TOOL_"): return 0
 var prior := 0
 for i in range(index):
  if inventory_item_at(i) == item: prior += 1
 return mini(99,maxi(0,int(s.inventory.get(item,0))-prior*99))

func assign_hotbar(index: int,item: String) -> bool:
 if index < 0 or index >= 8 or item == "": return false
 if not (TOOLS.has(item) or FOOD.has(item)): say("Só ferramentas, sementes e alimentos vão aos atalhos."); return false
 s.hotbar[index] = item
 save_game(slot)
 say("Atalho %d: %s" % [index+1,item])
 return true

func deposit_storage(item: String) -> bool:
 if not ["wood","stone","fiber","scrap","waste","corn"].has(item): return false
 if int(s.inventory.get(item,0)) <= 0: say("Nada para guardar."); return false
 s.inventory[item] -= 1
 s.storage[item] = int(s.storage.get(item,0))+1
 save_game(slot)
 say("1 %s guardado na encomenda." % item)
 return true

func withdraw_storage(item: String) -> bool:
 if int(s.storage.get(item,0)) <= 0: say("Estoque vazio."); return false
 if not can_add(item,1): say("Mochila pesada ou cheia."); return false
 s.storage[item] -= 1
 s.inventory[item] = int(s.inventory.get(item,0))+1
 save_game(slot)
 say("1 %s retirado do estoque." % item)
 return true

func change_option(code: int) -> void:
 if code == KEY_1:
  var scales = [1.0,1.25,1.5]
  var index = scales.find(float(s.preferences.uiScale))
  s.preferences.uiScale = scales[(index+1)%3]
 elif code == KEY_2: s.preferences.highContrast = not s.preferences.highContrast
 elif code == KEY_3: s.preferences.repeatAction = not s.preferences.repeatAction
 elif code == KEY_4: s.preferences.effectsVolume = maxf(0.0,float(s.preferences.effectsVolume)-0.25)
 elif code == KEY_5: s.preferences.effectsVolume = minf(1.0,float(s.preferences.effectsVolume)+0.25)
 if audio_player: audio_player.volume_db = linear_to_db(maxf(0.001,float(s.preferences.effectsVolume)))
 save_game(slot)

func carried_weight() -> float:
 var total := 0.0
 for item in s.inventory: total += float(WEIGHTS.get(item,0))*int(s.inventory[item])
 return total

func award_xp(amount: int) -> void:
 s.xp += amount
 var caps = [0,100,250,500,900]
 while s.level < 5 and s.xp >= caps[s.level]:
  s.level += 1
  s.hpMax += 10
  s.staminaMax += 10
  say("Nível %d! Capacidade aumentou." % s.level)

func tillable(p: Vector2i) -> bool:
 if s.mapId != "FARM01" or p.x < 1 or p.x > 62 or p.y < 1 or p.y > 46: return false
 if is_lake(p) or p.x >= 44 and p.x <= 55 and p.y >= 7 and p.y <= 15: return false
 if p.x >= 8 and p.x <= 17 and p.y >= 8 and p.y <= 15: return false
 if p.x >= 57 and p.y >= 9 and p.y <= 12: return false
 if object_at(p) != "": return false
 return true

func is_lake(p: Vector2i) -> bool: return p.x >= 8 and p.x <= 23 and p.y >= 31 and p.y <= 41
func key(p: Vector2i) -> String: return "%d,%d" % [p.x,p.y]
func tile_of(a: Variant) -> Vector2i: return Vector2i(int(a[0]),int(a[1]))
func object_at(p: Vector2i) -> String:
 if s.mapId != "FARM01": return ""
 for id in s.objects:
  if not s.objects[id].removed and tile_of(s.objects[id].at) == p: return id
 return ""
func condemned_at(p: Vector2i) -> String:
 if s.mapId != "HOME01": return ""
 for id in CONDEMNED:
  if s.condemned[id] > 0 and tile_of(CONDEMNED[id]) == p: return id
 return ""
func dirt_at(p: Vector2i) -> String:
 if s.mapId != "HOME01": return ""
 for id in DIRT:
  if not s.dirt[id] and tile_of(DIRT[id]) == p: return id
 return ""
func repair_at(p: Vector2i) -> String:
 for id in REPAIRS:
  if (id == "H01") != (s.mapId == "FARM01"): continue
  if tile_of(REPAIRS[id].at) == p: return id
 return ""
func screen_tile(screen: Vector2) -> Vector2i: return Vector2i(floori((screen.x+camera_origin.x)/TILE),floori((screen.y+camera_origin.y)/TILE))

func interact() -> void:
 if transition_cooldown > 0: return
 var p = tile_of(s.position)
 var target = target_tile()
 if s.mapId == "FARM01":
  if p.distance_to(Vector2i(49,16)) <= 2 or target == Vector2i(49,16):
   transition_to("HOME01",Vector2i(11,15)); return
  if p.distance_to(Vector2i(57,14)) <= 2:
   mode = "MODAL"; modal = "sales"; return
  if p.distance_to(Vector2i(60,14)) <= 2:
   mode = "MODAL"; modal = "mail"; return
  if p.distance_to(Vector2i(60,15)) <= 2:
   take_fruit(); return
  if near_lake(p) and selected_item() == "TOOL_WATER":
   if s.stamina < 1: say("Falta 1 de estamina."); return
   s.stamina -= 1; s.water = 20; say("Regador cheio."); return
  if p.x >= 61 and p.y >= 9 and p.y <= 12 or p.y <= 1 or p.y >= 46:
   say("Esta saída ficará para depois."); return
  if p.x >= 8 and p.x <= 18 and p.y >= 8 and p.y <= 16: say("Esta construção ficará para depois."); return
 else:
  if p.y >= 15 and p.x >= 9 and p.x <= 13:
   transition_to("FARM01",Vector2i(49,17)); return
  if s.repairs.H04.completed and near_furniture("bed",p):
   mode = "MODAL"; modal = "sleep"; return
  if near_furniture("bench",p): say("Um banco simples."); return
 say("Nada para interagir aqui.")

func near_lake(p: Vector2i) -> bool:
 return p.x >= 7 and p.x <= 24 and p.y >= 30 and p.y <= 42 and not is_lake(p)
func near_furniture(id: String,p: Vector2i) -> bool:
 if not s.furniture[id].placed: return false
 var at = tile_of(s.furniture[id].at)
 var size = furniture_size(id,s.furniture[id].rotation)
 return p.x >= at.x-1 and p.x <= at.x+size.x and p.y >= at.y-1 and p.y <= at.y+size.y
func transition_to(map_id: String,p: Vector2i) -> void:
 mode = "TRANSITION"
 transition_cooldown = 0.5
 s.mapId = map_id
 s.position = [p.x+0.5,p.y+0.9]
 mode = "PLAY"
 save_game(slot)

func take_fruit() -> void:
 var allowed = s.fruitTaken < 4 or (s.stamina < s.staminaMax*0.2 and int(s.inventory.get("coffee",0))+int(s.inventory.get("bar",0))+int(s.inventory.get("fruit",0)) == 0)
 if not allowed: say("Cesta vazia por enquanto."); return
 if not can_add("fruit",1): say("Mochila pesada ou cheia."); return
 s.inventory.fruit = int(s.inventory.get("fruit",0))+1
 s.fruitTaken += 1
 say("+1 umbu da cesta de apoio.")
func buy_food(item: String,price: int) -> void:
 if s.coins < price: say("Moedas insuficientes."); return
 if not can_add(item,1): say("Mochila pesada ou cheia."); return
 s.coins -= price
 s.inventory[item] = int(s.inventory.get(item,0))+1
 say("Alimento recebido.")
func eat(item: String) -> bool:
 if food_timer > 0: return false
 if int(s.inventory.get(item,0)) <= 0: say("Alimento indisponível."); return false
 if s.stamina >= s.staminaMax: say("Estamina cheia."); return false
 food_pending = item
 food_timer = 0.8
 mode = "PLAY"; modal = ""
 say("Comendo %s..." % short_name(item))
 return true

func finish_eating() -> void:
 if food_pending == "": return
 var item = food_pending
 food_pending = ""
 if int(s.inventory.get(item,0)) <= 0: return
 s.inventory[item] -= 1
 s.stamina = mini(s.staminaMax,s.stamina+FOOD[item])
 play_sound("eat")
 say("Estamina recuperada: %d/%d." % [s.stamina,s.staminaMax])
func ship_one(item: String) -> bool:
 if not PRICES.has(item) or int(s.inventory.get(item,0)) <= 0: say("Item não vendável ou indisponível."); return false
 s.inventory[item] -= 1
 s.shipment[item] = int(s.shipment.get(item,0))+1
 save_game(slot)
 return true
func withdraw_one(item: String) -> bool:
 if int(s.shipment.get(item,0)) <= 0 or not can_add(item,1): return false
 s.shipment[item] -= 1
 s.inventory[item] = int(s.inventory.get(item,0))+1
 save_game(slot)
 return true

func house_ready() -> bool:
 for id in s.repairs:
  if not s.repairs[id].completed: return false
 for id in s.dirt:
  if not s.dirt[id]: return false
 for id in s.condemned:
  if s.condemned[id] > 0: return false
 return true
func watered_corn_count() -> int:
 var count := 0
 for id in s.soil:
  var soil = s.soil[id]
  if soil.cropId == "crop_corn" and soil.tutorialPlantTracked: count += 1
 return count
func close_night() -> void:
 mode = "NIGHT_CLOSE"
 var valid = house_ready() and watered_corn_count() >= 20
 var night = s.day
 if int(s.nightTransactionId) != night:
  if valid: s.validSleepDay = night
  var proceeds := 0
  for item in s.shipment: proceeds += int(s.shipment[item])*int(PRICES.get(item,0))
  s.coins += proceeds
  s.shipment = {}
  for id in s.soil:
   var soil = s.soil[id]
   if soil.cropId == "crop_corn" and soil.wateredDayId == night: soil.cropAge = mini(4,soil.cropAge+1)
  s.nightTransactionId = night
  s.day += 1
  s.minutes = 360
  if s.repairs.H04.completed and s.mapId == "HOME01": s.position = [19.5,11.9]
  else: s.mapId = "FARM01"; s.position = [49.5,17.9]
  if s.validSleepDay == night and not s.completed:
   s.completed = true
   say("Bom dia! Casa restaurada, milho brotando. Missão concluída!")
  else: say("Um novo dia. A estamina continua em %d." % s.stamina)
  save_game(slot)
 mode = "PLAY"

func place_furniture(id: String,p: Vector2i,rot: int) -> bool:
 var reason = placement_error(id,p,rot)
 if reason != "": say(reason); return false
 if s.stamina < 1: say("Falta 1 de estamina."); return false
 if id == "bench": s.mail.bench -= 1
 s.stamina -= 1
 s.furniture[id] = {"at":[p.x,p.y],"rotation":rot,"placed":true}
 editor_item = ""
 save_game(slot)
 say("Móvel colocado.")
 return true
func placement_error(id: String,p: Vector2i,rot: int) -> String:
 if s.mapId != "HOME01" or not FURNITURE.has(id): return "Editor disponível dentro da casa."
 var requirement: String = FURNITURE[id].repair
 if requirement != "" and not s.repairs[requirement].completed: return "Repare este móvel primeiro."
 if id == "bench" and (s.mail.bench <= 0 or not house_ready()): return "Banco disponível após concluir a casa."
 var size = furniture_size(id,rot)
 if p.x < 1 or p.y < 1 or p.x+size.x > 23 or p.y+size.y > 17: return "Fora do piso interno."
 if id in ["stove","sink"] and (p.x+size.x > 14 or p.y > 6): return "Fogão e pia ficam na cozinha."
 var occupied: Array[Vector2i] = []
 for y in range(p.y,p.y+size.y):
  for x in range(p.x,p.x+size.x):
   var t = Vector2i(x,y)
   if x == 15 or y >= 15 and x >= 9 and x <= 13 or x == 14 and y >= 6 and y <= 10: return "Bloqueia uma passagem."
   if condemned_at(t) != "" or dirt_at(t) != "": return "Limpe ou remova o objeto primeiro."
   for other in s.furniture:
    if other != id and furniture_covers(other,t): return "Outro móvel ocupa o espaço."
   occupied.append(t)
 # Breadth-first walk from door; require kitchen doorway and an adjacent bed tile.
 var open: Array[Vector2i] = [Vector2i(11,15)]
 var seen: Dictionary = {}
 while not open.is_empty():
  var t = open.pop_front()
  if seen.has(key(t)): continue
  seen[key(t)] = true
  for v in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var n = t+v
   if n.x < 1 or n.x > 22 or n.y < 1 or n.y > 16 or n.x == 15 and (n.y < 7 or n.y > 9): continue
   if n in occupied: continue
   var blocked := false
   for other in s.furniture:
    if other != id and furniture_covers(other,n): blocked = true
   if not blocked and not seen.has(key(n)): open.append(n)
 if not seen.has(key(Vector2i(15,8))) or not seen.has(key(Vector2i(3,7))): return "Bloqueia o quarto ou a cozinha."
 var bed_at = p if id == "bed" else tile_of(s.furniture.bed.at)
 var bed_size = size if id == "bed" else furniture_size("bed",s.furniture.bed.rotation)
 var bed_access := false
 for y in range(bed_at.y-1,bed_at.y+bed_size.y+1):
  for x in [bed_at.x-1,bed_at.x+bed_size.x]:
   if seen.has(key(Vector2i(x,y))): bed_access = true
 if not bed_access: return "A cama ficaria inacessível."
 return ""

func save_path(n: int) -> String: return "user://boa_sorte_slot_%d.json" % n
func save_game(n: int) -> bool:
 if s.is_empty(): return false
 s.clockAccumulator = clock_accumulator
 var path = save_path(n)
 var temp = path+".tmp"
 var f = FileAccess.open(temp,FileAccess.WRITE)
 if f == null: say("Falha ao salvar."); return false
 f.store_string(JSON.stringify(s))
 f.flush(); f.close()
 if FileAccess.file_exists(path):
  DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(path+".bak"))
 var error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),ProjectSettings.globalize_path(path))
 return error == OK
func load_game(n: int) -> bool:
 if not FileAccess.file_exists(save_path(n)): return false
 var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path(n)))
 if not parsed is Dictionary or int(parsed.get("schemaVersion",-1)) != SAVE_SCHEMA: say("Save incompatível."); return false
 reset_pending_actions()
 s = parsed
 if not s.has("hotbar") or not s.hotbar is Array or s.hotbar.size() != 8: s.hotbar = TOOLS.duplicate()
 if not s.has("storage") or not s.storage is Dictionary: s.storage = {}
 var defaults = {"uiScale":1.0,"effectsVolume":0.75,"highContrast":false,"repeatAction":true}
 if not s.has("preferences") or not s.preferences is Dictionary: s.preferences = defaults.duplicate()
 else:
  for id in defaults:
   if not s.preferences.has(id): s.preferences[id] = defaults[id]
 if audio_player: audio_player.volume_db = linear_to_db(maxf(0.001,float(s.preferences.effectsVolume)))
 slot = n
 clock_accumulator = float(s.get("clockAccumulator",0))
 name_edit.hide()
 mode = "PLAY" if s.liaExited else "INTRO"
 if mode == "INTRO":
  dialog_index = 0
  intro_letter_seen = false
  lia_x = 63.0
  lia_arriving = true
  lia_leaving = false
 queue_redraw()
 return true
func say(t: String) -> void:
 message = t
 message_timer = 3.4

func load_assets() -> void:
 var path := "res://assets/manifest.json"
 if not FileAccess.file_exists(path): return
 var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
 if parsed is Dictionary:
  asset_manifest = parsed.get("assets",{})
  for id in asset_manifest:
   var asset_path: String = asset_manifest[id].get("path", "")
   if ResourceLoader.exists(asset_path): asset_textures[id] = load(asset_path)
  for id in parsed.get("audio",{}):
   var sound_path: String = parsed.audio[id].get("path","")
   if ResourceLoader.exists(sound_path): sounds[id] = load(sound_path)

func play_sound(id: String) -> void:
 if DisplayServer.get_name() == "headless": return
 if audio_player == null or not sounds.has(id): return
 audio_player.stream = sounds[id]
 audio_player.play()

func asset(id: String, ground: Vector2) -> bool:
 if not asset_textures.has(id): return false
 var tex: Texture2D = asset_textures[id]
 var pivot = asset_manifest[id].get("pivot", [tex.get_width()/2,tex.get_height()])
 draw_texture(tex,ground-Vector2(pivot[0],pivot[1]))
 return true

# Temporary vector art. Gameplay uses IDs and footprints; PNG exports can replace drawing.
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,Vector2(SIZE)),Color("243348"))
 if mode == "TITLE" or mode == "NAME":
  draw_panel(Rect2(130,47,380,270))
  label("BOA SORTE",Vector2(246,87),25,Color("70482f"))
  label("A fazenda do avô Olegário",Vector2(197,113),15)
  if mode == "TITLE":
   label("N — Nova partida",Vector2(205,162),17)
   label("1 / 2 / 3 — Continuar ou criar slot",Vector2(170,195),14)
   label("Enter avança diálogos • Esc pula abertura",Vector2(153,263),12)
  else:
   label("Escolha seu nome",Vector2(225,142),16)
   label("Enter — chegar à fazenda",Vector2(207,218),14)
   label("Esc — voltar",Vector2(260,247),12)
  return
 if s.is_empty(): return
 var player = Vector2(s.position[0],s.position[1])*TILE
 camera_origin = (player-Vector2(SIZE)*0.5).round()
 var map_px = Vector2(64,48)*TILE if s.mapId == "FARM01" else Vector2(24,18)*TILE
 camera_origin.x = clampf(camera_origin.x,0,map_px.x-SIZE.x)
 camera_origin.y = clampf(camera_origin.y,0,map_px.y-SIZE.y)
 draw_set_transform(-camera_origin)
 if s.mapId == "FARM01": draw_farm()
 else: draw_home()
 draw_drops()
 if mode == "INTRO" and not s.liaExited: draw_lia(Vector2(lia_x+0.5,12.9)*TILE)
 draw_actor(player)
 if mode == "PLAY" or mode == "BUILD":
  var t = target_tile() if mode == "PLAY" else screen_tile(get_viewport().get_mouse_position())
  var valid = action_check(selected_item(),t) == "" if mode == "PLAY" and TOOLS.has(selected_item()) else editor_item != "" and placement_error(editor_item,t,editor_rotation) == "" if mode == "BUILD" else false
  var color = Color("f1dfb1") if valid else Color("b85d43")
  draw_rect(Rect2(Vector2(t)*TILE,Vector2(TILE,TILE)),color,false,2)
  if mode == "BUILD" and editor_item != "":
   var footprint = furniture_size(editor_item,editor_rotation)
   draw_rect(Rect2(Vector2(t)*TILE,Vector2(footprint)*TILE),Color(color,0.35),true)
 draw_set_transform(Vector2.ZERO)
 draw_hud()
 if mode == "INTRO":
  if lia_arriving:
   draw_panel(Rect2(32,260,576,70))
   label("Lia se aproxima pela estrada do leste...",Vector2(49,291),15)
  elif dialog_index == 1 and not intro_letter_seen:
   draw_panel(Rect2(36,48,568,264))
   label("CARTA DO PREFEITO JAIR",Vector2(56,77),17)
   wrap_text(LETTER.replace("{name}",s.name),Vector2(56,103),525,13,20)
   label("Enter / clique: continuar     Esc: pular",Vector2(329,301),11)
  else:
   draw_panel(Rect2(32,218,576,122))
  if not lia_arriving and dialog_index < DIALOGUE.size() and (dialog_index != 1 or intro_letter_seen):
   wrap_text(DIALOGUE[dialog_index].replace("{name}",s.name),Vector2(49,242),540,14,18)
   label("Enter / clique: continuar     Esc: pular",Vector2(330,329),11)
  elif dialog_index >= DIALOGUE.size(): label("Lia segue pela estrada à direita...",Vector2(55,262),15)
 elif mode == "MODAL": draw_modal()
 elif mode == "BUILD": draw_build_ui()
 if message_timer > 0:
  draw_rect(Rect2(46,181,548,26),Color("243348"))
  label(message,Vector2(53,199),13,Color("f1dfb1"))

func draw_farm() -> void:
 var first = Vector2i(floori(camera_origin.x/TILE),floori(camera_origin.y/TILE))
 var last = first+Vector2i(21,13)
 for y in range(maxi(0,first.y),mini(48,last.y)):
  for x in range(maxi(0,first.x),mini(64,last.x)):
   var p = Vector2i(x,y)
   var c = Color("dfae55") if (x*17+y*13)%7 > 1 else Color("d5a751")
   if (x >= 56 and y >= 9 and y <= 12) or (x >= 47 and x <= 59 and y >= 16 and y <= 18): c = Color("c99854")
   if is_lake(p): c = Color("287fbd") if (x+y)%2 else Color("2c89be")
   if x >= 8 and x <= 17 and y >= 8 and y <= 15: c = Color("9b855c")
   if x >= 40 and x <= 44 and y >= 22 and y <= 25: c = Color("b99055")
   if s.soil.has(key(p)):
    c = Color("795335") if s.soil[key(p)].wateredDayId != s.day else Color("a36c3b")
   draw_rect(Rect2(Vector2(p)*TILE,Vector2(TILE,TILE)),c)
   if is_lake(p): asset("ground/water",Vector2(p)*TILE+Vector2(16,32))
   elif s.soil.has(key(p)):
    asset("ground/soil_wet" if s.soil[key(p)].wateredDayId == s.day else "ground/soil_tilled",Vector2(p)*TILE+Vector2(16,32))
   elif (x >= 56 and y >= 9 and y <= 12) or (x >= 47 and x <= 59 and y >= 16 and y <= 18): asset("ground/path",Vector2(p)*TILE+Vector2(16,32))
   elif (x >= 40 and x <= 44 and y >= 22 and y <= 25) or (x >= 8 and x <= 17 and y >= 8 and y <= 15): asset("ground/soil_untilled",Vector2(p)*TILE+Vector2(16,32))
   else: asset("ground/grass",Vector2(p)*TILE+Vector2(16,32))
   if s.soil.has(key(p)):
    draw_rect(Rect2(Vector2(p)*TILE+Vector2(4,8),Vector2(24,15)),Color("70482f"),false,2)
    if s.soil[key(p)].cropId == "crop_corn": draw_crop(p,s.soil[key(p)].cropAge)
 # Lake rim and ruins
 draw_rect(Rect2(8*TILE,8*TILE,10*TILE,8*TILE),Color("70482f"),false,7)
 if not asset("props/ruin",Vector2(13,15)*TILE): world_label("RUÍNAS",Vector2(10,10)*TILE,18,Color("f1dfb1"))
 draw_rect(Rect2(44*TILE,7*TILE,12*TILE,9*TILE),Color("f1dfb1") if s.repairs.H01.completed else Color("b7a276"))
 asset("buildings/house_H01_restored" if s.repairs.H01.completed else "buildings/house_H01_old",Vector2(49.5,16)*TILE)
 for window_x in [47,52]:
  asset("buildings/repair_H03_window_open" if s.repairs.H03.completed else "buildings/repair_H03_window_boarded",Vector2(window_x,13)*TILE)
 if not asset("props/sales_chest",Vector2(57.5,15)*TILE): draw_rect(Rect2(57*TILE,14*TILE,30,29),Color("70482f"))
 if not asset("props/mailbox",Vector2(60.5,15)*TILE): draw_rect(Rect2(60*TILE,14*TILE,29,29),Color("e6b539"))
 draw_rect(Rect2(60*TILE,15*TILE,28,23),Color("4f7838"))
 for id in s.objects:
  var ob = s.objects[id]
  if ob.removed: continue
  var pos = Vector2(ob.at[0],ob.at[1])*TILE
  if pos.x < camera_origin.x-96 or pos.x > camera_origin.x+SIZE.x+96 or pos.y < camera_origin.y-128 or pos.y > camera_origin.y+SIZE.y+96: continue
  draw_prop(ob,pos)
 for p in [Vector2i(31,0),Vector2i(63,10),Vector2i(38,47)]:
  draw_rect(Rect2(Vector2(p)*TILE,Vector2(30,30)),Color("b85d43"),false,3)

func draw_crop(p: Vector2i,age: int) -> void:
 if asset("crops/crop_corn_stage%d" % (age+1),Vector2(p)*TILE+Vector2(16,32)): return
 var center = Vector2(p)*TILE+Vector2(16,20)
 var height = 5+age*5
 draw_line(center,center+Vector2(0,-height),Color("245e46"),3)
 draw_circle(center+Vector2(0,-height),3+age,Color("4f7838"))

func draw_prop(ob: Dictionary,pos: Vector2) -> void:
 var kind: String = ob.kind
 var id := ""
 match kind:
  "tree","stump":
   var species = ["umbu","juazeiro","catingueira","jurema"][int(ob.get("variant",0))%4]
   id = "flora/object_tree_%s_%s" % [species,"stump" if kind == "stump" else "stage%d" % (int(ob.stage)+1)]
  "bush": id = "props/bush_%d" % (int(ob.maxHits)%3+1)
  "mandacaru": id = "props/mandacaru"
  "cactus": id = "props/palma"
  "stone_small": id = "props/rock_small_1"
  "stone_medium": id = "props/rock_medium_1"
  "stone_large": id = "props/rock_large_1"
  "stick","log": id = "props/%s" % kind
  "trash_metal": id = "props/trash_metal_1"
  "trash_plastic": id = "props/trash_bag_1"
 if id != "" and asset(id,pos+Vector2(16,32)):
  if ob.hits < ob.maxHits: draw_line(pos+Vector2(6,5),pos+Vector2(25,24),Color("f1dfb1"),2)
  return
 if kind == "tree" or kind == "stump":
  var stage: int = ob.stage
  draw_rect(Rect2(pos+Vector2(12,-20-stage*11),Vector2(9,47+stage*11)),Color("70482f"))
  if kind != "stump":
   draw_circle(pos+Vector2(16,-16-stage*11),12+stage*7,Color("245e46"))
   draw_circle(pos+Vector2(12,-18-stage*11),10+stage*5,Color("4f7838"))
 elif kind.begins_with("stone"):
  draw_circle(pos+Vector2(16,19),12,Color("65727c"))
  draw_line(pos+Vector2(13,9),pos+Vector2(19,17),Color("aab0ab"),2)
 elif kind in ["bush","mandacaru","cactus"]:
  if kind == "mandacaru":
   draw_rect(Rect2(pos+Vector2(13,-22),Vector2(7,50)),Color("4f7838"))
   draw_rect(Rect2(pos+Vector2(3,-6),Vector2(24,6)),Color("4f7838"))
  else: draw_circle(pos+Vector2(16,18),13,Color("4f7838"))
 elif kind in ["stick","log"]: draw_rect(Rect2(pos+Vector2(3,15),Vector2(26,7)),Color("70482f"))
 else: draw_rect(Rect2(pos+Vector2(8,12),Vector2(16,13)),Color("65727c") if kind == "trash_metal" else Color("f1dfb1"))
 if ob.hits < ob.maxHits: draw_line(pos+Vector2(6,5),pos+Vector2(25,24),Color("f1dfb1"),2)

func draw_home() -> void:
 for y in range(18):
  for x in range(24):
   var wall = x == 0 or x == 23 or y == 0 or y == 17 or x == 15 and (y < 7 or y > 9)
   var c = Color("a36c3b") if s.repairs.H02.completed else Color("886644")
   if wall: c = Color("f1dfb1") if s.repairs.H02.completed else Color("b7a276")
   draw_rect(Rect2(x*TILE,y*TILE,TILE,TILE),c)
   var ground_id = "ground/wall_new" if wall and s.repairs.H02.completed else "ground/wall_old" if wall else "ground/floor_new" if s.repairs.H02.completed else "ground/floor_old"
   asset(ground_id,Vector2(x*TILE+16,y*TILE+32))
   if x > 0 and x < 23 and y > 0 and y < 17 and c != Color("f1dfb1"): draw_rect(Rect2(x*TILE,y*TILE,TILE,TILE),Color("70482f",0.2),false,1)
 for id in DIRT:
  if not s.dirt[id]:
   var pos = Vector2(tile_of(DIRT[id]))*TILE
   var n = DIRT.keys().find(id)+1
   if not asset("dirt/dirt_%02d_%s" % [n,["web","dust","papers","rubble","rug","utensils"][n-1]],pos+Vector2(16,32)):
    draw_circle(pos+Vector2(16,17),11,Color("65727c"))
 for id in CONDEMNED:
  if s.condemned[id] > 0:
   var pos = Vector2(tile_of(CONDEMNED[id]))*TILE
   var kind = ["table","chair","chair","cabinet","bookshelf","low_table","wardrobe"][CONDEMNED.keys().find(id)]
   if not asset("furniture/"+kind,pos+Vector2(16,32)): draw_rect(Rect2(pos+Vector2(2,4),Vector2(28,25)),Color("70482f"))
   world_label("X",pos+Vector2(9,24),14,Color("f1dfb1"))
 for id in s.furniture:
  if not s.furniture[id].placed: continue
  var f = s.furniture[id]
  var pos = Vector2(tile_of(f.at))*TILE
  var size = Vector2(furniture_size(id,f.rotation))*TILE
  var repaired = id == "bench" or s.repairs[FURNITURE[id].repair].completed
  var furniture_sprite = "furniture/%s_intact_r%d" % [id,int(f.rotation)] if repaired else "furniture/%s_broken" % id
  if not asset(furniture_sprite,pos+Vector2(size.x/2,size.y)) and not asset("furniture/"+id+("" if id == "bench" else "_intact" if repaired else "_broken"),pos+Vector2(size.x/2,size.y)):
   draw_rect(Rect2(pos+Vector2(2,2),size-Vector2(4,4)),Color("4f7838") if repaired else Color("70482f"))
  world_label(id.to_upper(),pos+Vector2(3,20),11,Color("f1dfb1"))
 for id in REPAIRS:
  if id == "H01" or s.repairs[id].completed: continue
  var pos = Vector2(tile_of(REPAIRS[id].at))*TILE
  world_label(id,pos+Vector2(3,30),11,Color("e6b539"))

func draw_drops() -> void:
 for id in s.drops:
  var d = s.drops[id]
  if d.mapId != s.mapId: continue
  var pos = Vector2(d.at[0],d.at[1])*TILE+Vector2(16,16)
  draw_circle(pos,6,Color("e6b539"))
  world_label(str(d.amount),pos+Vector2(5,3),10)

func draw_actor(pos: Vector2) -> void:
 if food_timer > 0 and draw_food_sheet(pos,tile_of(s.facing)): return
 if action_timer > 0 and not pending.is_empty():
  var action_id = {"TOOL_AXE":"axe","TOOL_PICK":"pick","TOOL_HOE":"hoe","TOOL_SCYTHE":"scythe","TOOL_WATER":"water","TOOL_HAMMER":"hammer","SEED_CORN":"sow","HAND":"clean"}.get(pending.tool,"")
  if action_id != "" and draw_action_sheet("actors/action_"+action_id,pos,tile_of(s.facing)): return
 if draw_actor_sheet("actors/actor_player",pos,tile_of(s.facing),action_timer > 0): return
 # Feet align to bottom of 32×64 canvas; clear hat, terracotta shirt and blue jeans.
 draw_ellipse_shadow(pos)
 draw_rect(Rect2(pos+Vector2(-6,-30),Vector2(12,18)),Color("304868"))
 draw_rect(Rect2(pos+Vector2(-10,-47),Vector2(20,20)),Color("b9624c"))
 draw_circle(pos+Vector2(0,-52),8,Color("d6a16b"))
 draw_rect(Rect2(pos+Vector2(-15,-63),Vector2(30,6)),Color("dfae55"))
 draw_rect(Rect2(pos+Vector2(-9,-66),Vector2(18,9)),Color("dfae55"))
 draw_rect(Rect2(pos+Vector2(-8,-11),Vector2(7,10)),Color("70482f"))
 draw_rect(Rect2(pos+Vector2(2,-11),Vector2(7,10)),Color("70482f"))
 if action_timer > 0:
  draw_line(pos+Vector2(8,-40),pos+Vector2(23,-13),Color("f1dfb1"),4)
func draw_lia(pos: Vector2) -> void:
 if draw_actor_sheet("actors/actor_lia",pos,Vector2i(1,0),lia_leaving): return
 draw_ellipse_shadow(pos)
 draw_rect(Rect2(pos+Vector2(-6,-30),Vector2(12,18)),Color("294f8f"))
 draw_rect(Rect2(pos+Vector2(-10,-47),Vector2(20,20)),Color("e6b539"))
 draw_circle(pos+Vector2(0,-52),8,Color("d6a16b"))
 draw_rect(Rect2(pos+Vector2(-10,-64),Vector2(20,8)),Color("e6b539"))
 draw_rect(Rect2(pos+Vector2(7,-38),Vector2(9,15)),Color("294f8f"))
func draw_ellipse_shadow(pos: Vector2) -> void: draw_circle(pos+Vector2(0,-2),11,Color("243348",0.35))

func draw_actor_sheet(id: String,pos: Vector2,direction: Vector2i,moving: bool) -> bool:
 if not asset_textures.has(id): return false
 var tex: Texture2D = asset_textures[id]
 var row := 0
 if direction.x < 0: row = 1
 elif direction.x > 0: row = 2
 elif direction.y < 0: row = 3
 var col := 1 if moving and int(elapsed*5)%2 == 1 else 0
 draw_texture_rect_region(tex,Rect2(pos+Vector2(-16,-64),Vector2(32,64)),Rect2(col*32,row*64,32,64))
 return true

func draw_action_sheet(id: String,pos: Vector2,direction: Vector2i) -> bool:
 if not asset_textures.has(id): return false
 var row := 0
 if direction.x < 0: row = 1
 elif direction.x > 0: row = 2
 elif direction.y < 0: row = 3
 var frame = clampi(int((1.0-action_timer/0.7)*4.0),0,3)
 draw_texture_rect_region(asset_textures[id],Rect2(pos+Vector2(-16,-64),Vector2(32,64)),Rect2(frame*32,row*64,32,64))
 return true

func draw_food_sheet(pos: Vector2,direction: Vector2i) -> bool:
 var id = "actors/action_eat"
 if not asset_textures.has(id): return false
 var row := 0
 if direction.x < 0: row = 1
 elif direction.x > 0: row = 2
 elif direction.y < 0: row = 3
 var frame = clampi(int((1.0-food_timer/0.8)*4.0),0,3)
 draw_texture_rect_region(asset_textures[id],Rect2(pos+Vector2(-16,-64),Vector2(32,64)),Rect2(frame*32,row*64,32,64))
 return true

func draw_hud() -> void:
 draw_rect(Rect2(0,0,640,48),Color("243348",0.94))
 label("M01 • Um novo começo",Vector2(8,15),13,Color("f1dfb1"))
 label("Casa %d/20  Milho %d/20  Dormir %s" % [house_count(),watered_corn_count(),"✓" if s.completed else "○"],Vector2(8,32),12,Color("f1dfb1"))
 var period = "Manhã" if s.minutes < 720 else "Tarde" if s.minutes < 1080 else "Noite"
 label("D%d %02d:%02d %s  $%d" % [s.day,int(s.minutes/60),int(s.minutes)%60,period,s.coins],Vector2(399,17),13,Color("f1dfb1"))
 label("Vida %d/%d" % [s.hp,s.hpMax],Vector2(407,33),10,Color("f1dfb1"))
 draw_rect(Rect2(501,25,48,6),Color("b85d43"))
 draw_rect(Rect2(501,25,48*float(s.hp)/s.hpMax,6),Color("e6b539"))
 label("Est. %d/%d" % [s.stamina,s.staminaMax],Vector2(551,33),10,Color("f1dfb1"))
 draw_rect(Rect2(550,38,80,5),Color("70482f"))
 draw_rect(Rect2(550,38,80*float(s.stamina)/s.staminaMax,5),Color("4f7838"))
 draw_rect(Rect2(0,316,640,44),Color("243348",0.94))
 for i in range(8):
  var x = 9+i*77
  var hot = str(s.hotbar[i])
  draw_rect(Rect2(x,321,72,34),Color("a36c3b") if i == selected else Color("70482f"),false,2)
  asset(icon_id(hot),Vector2(x+17,349))
  label(str(i+1)+" "+short_name(hot),Vector2(x+30,339),10,Color("f1dfb1"))
  if hot == "TOOL_WATER": label(str(s.water),Vector2(x+48,353),10,Color("f1dfb1"))
  elif hot == "SEED_CORN" or FOOD.has(hot): label(str(s.inventory.get(hot,0)),Vector2(x+48,353),10,Color("f1dfb1"))
 label("Peso %.1f/40" % carried_weight(),Vector2(7,310),11,Color("243348"))
func house_count() -> int:
 var n := 0
 for id in s.repairs: if s.repairs[id].completed: n += 1
 for id in s.dirt: if s.dirt[id]: n += 1
 for id in s.condemned: if s.condemned[id] <= 0: n += 1
 return n

func draw_modal() -> void:
 draw_rect(Rect2(0,0,640,360),Color("243348",0.55))
 draw_panel(Rect2(74,56,492,260))
 match modal:
  "inventory":
   label("MOCHILA — 24 espaços",Vector2(93,81),16)
   for i in range(24):
    var x = 95+(i%6)*75
    var y = 91+(i/6)*43
    draw_rect(Rect2(x,y,69,39),Color("e6b539") if i == inventory_cursor else Color("a36c3b"),false,2)
    var item = inventory_item_at(i)
    if item != "":
     asset(icon_id(item),Vector2(x+15,y+29))
     label(short_name(item),Vector2(x+28,y+17),10)
     if inventory_quantity_at(i) > 0: label(str(inventory_quantity_at(i)),Vector2(x+40,y+32),10)
   label("Setas escolhem • Enter come • 1–8 atalho • 0 mão livre",Vector2(93,282),11)
   label("Peso %.1f/40 • %d/24 usados" % [carried_weight(),occupied_slots()],Vector2(93,301),12)
  "journal":
   label("DIÁRIO • Um novo começo",Vector2(93,83),17)
   label("Casa %d/20 • Reparos 7, limpezas 6, móveis 7" % house_count(),Vector2(93,108),13)
   label("Milho plantado e regado %d/20" % watered_corn_count(),Vector2(93,127),13)
   label("Durma na cama após concluir ambos.",Vector2(93,147),13)
   label("Carta de Jair:",Vector2(93,173),14)
   wrap_text(LETTER.replace("{name}",s.name),Vector2(93,194),450,11,14)
  "mail":
   label("CORREIO • Carta, encomenda e apoio",Vector2(93,83),16)
   label("Carta de Jair disponível no diário (J).",Vector2(93,109),13)
   label("Reserva: madeira %d, pedra %d, fibra %d, sucata %d" % [s.mail.wood,s.mail.stone,s.mail.fiber,s.mail.scrap],Vector2(93,132),12)
   label("Banco complementar: %d" % s.mail.bench,Vector2(93,153),12)
   label("Estoque livre: %s" % str(s.storage),Vector2(93,173),11)
   label("1 umbu • 2 café $25 • 3 barra $15",Vector2(93,199),12)
   label("4–9 guarda madeira/pedra/fibra/sucata/milho/resíduo",Vector2(93,219),11)
   label("Shift+4–9 retira estoque livre da encomenda",Vector2(93,238),11)
   label("A visita ao prefeito ficará disponível depois.",Vector2(93,278),11)
  "sales":
   label("BAÚ DE VENDAS",Vector2(93,83),17)
   label("Envios: %s" % str(s.shipment),Vector2(93,117),13)
   label("Receita prevista: $%d" % shipment_value(),Vector2(93,143),13)
   label("Enviar: 1 madeira  2 pedra  3 fibra  4 sucata  5 milho",Vector2(93,187),12)
   label("Shift + número retira. Liquidação ao dormir.",Vector2(93,213),13)
  "sleep":
   label("DORMIR ATÉ AMANHÃ?",Vector2(93,98),18)
   label("Espaço confirma • Esc cancela",Vector2(93,139),15)
   label("Estamina atual: %d. Dormir não recupera estamina." % s.stamina,Vector2(93,175),13)
   label("Missão %s" % ("pronta para terminar" if house_ready() and watered_corn_count() >= 20 else "continua amanhã"),Vector2(93,204),13)
  "repair":
   var id = repair_at(repair_target)
   label("REPARO %s — %s" % [id,REPAIRS[id].name],Vector2(93,98),17)
   label("Materiais: %s" % str(REPAIRS[id].cost),Vector2(93,134),14)
   label("Na encomenda: %s" % str(s.mail),Vector2(93,162),12)
   label("Golpes: %d • Estamina: 2 por golpe" % REPAIRS[id].hits,Vector2(93,194),13)
   label("Espaço confirma o primeiro golpe • Esc cancela",Vector2(93,239),13)
  "pause":
   label("PAUSA",Vector2(93,98),18)
   label("Esc volta • S salva • F5 salva durante o jogo",Vector2(93,145),14)
   label("WASD/setas mover • clique esquerdo usar • E interagir",Vector2(93,176),12)
   label("I mochila • J diário • B móveis • 1–8 ferramentas",Vector2(93,200),12)
   label("O opções",Vector2(93,229),13)
  "options":
   label("OPÇÕES — Esc fecha",Vector2(93,90),17)
   label("1 Escala de texto: %d%%" % int(float(s.preferences.uiScale)*100),Vector2(93,125),13)
   label("2 Contraste alto: %s" % ("sim" if s.preferences.highContrast else "não"),Vector2(93,151),13)
   label("3 Repetir ação ao segurar: %s" % ("sim" if s.preferences.repeatAction else "não"),Vector2(93,177),13)
   label("4/5 Volume dos efeitos: %d%%" % int(float(s.preferences.effectsVolume)*100),Vector2(93,203),13)
   label("As escolhas ficam no save deste slot.",Vector2(93,263),12)
func shipment_value() -> int:
 var value := 0
 for item in s.shipment: value += int(s.shipment[item])*int(PRICES.get(item,0))
 return value
func draw_build_ui() -> void:
 draw_rect(Rect2(0,48,640,35),Color("243348",0.9))
 label("MÓVEIS: 1 cama  2 sofá  3 fogão  4 pia  5 banco • R gira • clique coloca • Esc sai",Vector2(8,67),11,Color("f1dfb1"))
 if editor_item != "":
  var p = screen_tile(get_viewport().get_mouse_position())
  var err = placement_error(editor_item,p,editor_rotation)
  draw_rect(Rect2(30,278,580,34),Color("243348",0.95))
  label("%s %d° • %s" % [editor_item,editor_rotation*90,"Livre — 1 estamina" if err == "" else err],Vector2(40,300),13,Color("f1dfb1"))
func draw_panel(rect: Rect2) -> void:
 var high = not s.is_empty() and s.get("preferences",{}).get("highContrast",false)
 draw_rect(rect,Color.WHITE if high else Color("f1dfb1"))
 draw_rect(rect,Color.BLACK if high else Color("70482f"),false,5)
func label(t: String,p: Vector2,size: int = 14,c: Color = Color("243348")) -> void:
 var scale = float(s.get("preferences",{}).get("uiScale",1.0)) if not s.is_empty() else 1.0
 draw_string(font,p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(9,int(size*scale)),c)

func short_name(id: String) -> String:
 var names = {"TOOL_AXE":"Mach.","TOOL_PICK":"Pic.","TOOL_HOE":"Enx.","TOOL_SCYTHE":"Foice","TOOL_WATER":"Água","TOOL_HAMMER":"Mart.","SEED_CORN":"Milho","HAND":"Mão","coffee":"Café","bar":"Barra","fruit":"Umbu","wood":"Mad.","stone":"Ped.","fiber":"Fibra","scrap":"Suc.","waste":"Res.","corn":"Milho"}
 return str(names.get(id,id.substr(0,5)))

func icon_id(id: String) -> String:
 var names = {"TOOL_AXE":"axe","TOOL_PICK":"pick","TOOL_HOE":"hoe","TOOL_SCYTHE":"scythe","TOOL_WATER":"water","TOOL_HAMMER":"hammer","SEED_CORN":"corn_seed","HAND":"valid","wood":"wood","stone":"stone","fiber":"fiber","scrap":"scrap","waste":"trash","corn":"corn_seed","coffee":"coffee","bar":"bar","fruit":"fruit"}
 return "icons/"+str(names.get(id,"valid"))
func world_label(t: String,p: Vector2,size: int = 14,c: Color = Color("243348")) -> void:
 draw_string(font,p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)
func wrap_text(t: String,p: Vector2,width: float,size: int = 14,line_h: int = 18) -> void:
 var line := ""
 var y = p.y
 for word in t.split(" "):
  var trial = word if line == "" else line+" "+word
  if font.get_string_size(trial,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > width and line != "":
   label(line,Vector2(p.x,y),size)
   y += line_h
   line = word
  else: line = trial
 if line != "": label(line,Vector2(p.x,y),size)
