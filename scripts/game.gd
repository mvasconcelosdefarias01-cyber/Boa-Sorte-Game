extends Node2D
## Boa Sorte, cenário 01. Estado serializável separado do desenho provisório.
const TILE := 32
const SIZE := Vector2i(640, 360)
const ROAD_MAP = preload("res://scripts/road_map.gd")
const CITY_MAP = preload("res://scripts/city_map.gd")
const CITY_ENTRY := Vector2i(3,13)
const ROAD_CITY_ENTRY := Vector2i(44,13)
const ROAD_ENTRY := Vector2i(3,13)
const FARM_ROAD_ENTRY := Vector2i(62,17)
const FARM_HOUSE_SCALE := 0.5625
const ACTOR_SCALE := 0.875
const FARM_HOUSE_FOOTPRINT := Rect2i(47,12,6,4)
const SAVE_SCHEMA := 1
const HOME_LAYOUT_VERSION := 2
const HOME_SIZE := Vector2i(17,10)
const HOME_ENTRY := Vector2i(8,8)
const HOME_WAKE := Vector2i(13,5)
const LAKE_TOP := 31
const LAKE_LEFT := [12,11,9,9,8,8,8,9,10,12,13]
const LAKE_RIGHT := [14,17,20,22,23,23,23,22,21,20,16]
const LAKE_ANCHOR := Vector2(16,43)
const TOOLS := ["TOOL_AXE", "TOOL_PICK", "TOOL_HOE", "TOOL_SCYTHE", "TOOL_WATER", "TOOL_HAMMER", "SEED_CORN", "HAND"]
const TOOL_NAMES := ["Machado", "Picareta", "Enxada", "Foice", "Regador", "Martelo", "Milho", "Mão"]
const FOOD := {"coffee":60, "bar":40, "fruit":20}
const WEIGHTS := {"wood":0.5,"stone":0.75,"fiber":0.1,"scrap":0.25,"waste":0.05,"SEED_CORN":0.05,"corn":0.2,"coffee":0.1,"bar":0.2,"fruit":0.05,"bench":2.0}
const PRICES := {"wood":2,"stone":2,"fiber":1,"scrap":3,"corn":10}
const REPAIRS := {
 "H01":{"name":"Telhado e fachada","hits":6,"cost":{"wood":8,"stone":6},"at":[49,16]},
 "H02":{"name":"Paredes e piso","hits":4,"cost":{"wood":2,"stone":4},"at":[4,4]},
 "H03":{"name":"Janelas","hits":3,"cost":{"wood":4},"at":[12,1]},
 "H04":{"name":"Cama","hits":2,"cost":{"wood":2,"fiber":2},"at":[13,3]},
 "H05":{"name":"Sofá","hits":2,"cost":{"wood":2,"fiber":1},"at":[4,6]},
 "H06":{"name":"Fogão","hits":2,"cost":{"stone":2,"scrap":2},"at":[2,2]},
 "H07":{"name":"Pia","hits":2,"cost":{"wood":2,"scrap":1},"at":[5,2]}}
const DIRT := {"dirt_web":[2,3],"dirt_dust":[6,4],"dirt_papers":[9,5],"dirt_rubble":[13,6],"dirt_rug":[13,7],"dirt_utensils":[5,3]}
const CONDEMNED := {"old_table":[7,4],"old_chair_a":[6,5],"old_chair_b":[9,4],"old_cabinet":[2,4],"old_shelf":[9,2],"old_low_table":[3,7],"old_wardrobe":[14,7]}
const CONDEMNED_SIZE := {"old_table":[2,1],"old_chair_a":[1,1],"old_chair_b":[1,1],"old_cabinet":[1,2],"old_shelf":[2,2],"old_low_table":[2,1],"old_wardrobe":[2,2]}
const FURNITURE := {"bed":{"at":[13,2],"size":[2,3],"repair":"H04"},"sofa":{"at":[3,6],"size":[3,1],"repair":"H05"},"stove":{"at":[2,2],"size":[1,1],"repair":"H06"},"sink":{"at":[4,2],"size":[3,1],"repair":"H07"},"bench":{"at":[0,0],"size":[1,1],"repair":""}}
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
var arrival_latch := false
var road_map = ROAD_MAP.new()
var city_map = CITY_MAP.new()
var lia_x := 63.0
var lia_arriving := false
var lia_leaving := false
var camera_origin := Vector2.ZERO
var selected := 0
var menu_preferences := {"uiScale":1.0,"effectsVolume":0.75,"highContrast":false,"repeatAction":true}
var inventory_cursor := 0
var editor_item := ""
var editor_rotation := 0
var build_preview_tile := HOME_ENTRY
var build_keyboard_preview := false
var repair_target := Vector2i.ZERO
var name_edit: LineEdit
var font: Font
var asset_manifest: Dictionary = {}
var asset_textures: Dictionary = {}
var sounds: Dictionary = {}
var audio_player: AudioStreamPlayer
var ui: CanvasLayer
var elapsed := 0.0
var moving_this_frame := false
var world_mouse_held := false
var pointer_over_ui := false
var impact_effects: Array[Dictionary] = []

func _ready() -> void:
 font = ThemeDB.fallback_font
 load_assets()
 audio_player = AudioStreamPlayer.new()
 audio_player.volume_db = -9.0
 add_child(audio_player)
 ui = load("res://scripts/ui.gd").new()
 add_child(ui)
 ui.setup(self)
 if OS.has_feature("headless"):
  get_viewport().set_update_mode(SubViewport.UPDATE_ALWAYS)
 queue_redraw()

func reset_pending_actions() -> void:
 action_timer = 0.0
 world_mouse_held = false
 pending = {}
 queued = false
 food_timer = 0.0
 food_pending = ""
 auto_save_accumulator = 0.0
 move_weight_accumulator = 0.0
 impact_effects.clear()

func new_game(player_name: String) -> bool:
 player_name = player_name.strip_edges()
 if player_name.length() < 2 or player_name.length() > 20:
  say("Nome: use de 2 a 20 caracteres.")
  return false
 reset_pending_actions()
 arrival_latch = false
 s = {"schemaVersion":SAVE_SCHEMA,"homeLayoutVersion":HOME_LAYOUT_VERSION,"name":player_name,"mapId":"FARM01","position":[59.5,12.9],"facing":[-1,0],"day":1,"minutes":480,"hp":100,"hpMax":100,"stamina":100,"staminaMax":100,"level":1,"xp":0,"coins":0,"inventory":{},"hotbar":TOOLS.duplicate(),"water":20,"repairs":{},"dirt":{},"condemned":{},"objects":{},"soil":{},"drops":{},"furniture":{},"mail":{"wood":20,"stone":12,"fiber":3,"scrap":3,"bench":1},"storage":{},"shipment":{},"fruitTaken":0,"arrivalGranted":false,"liaExited":false,"validSleepDay":0,"completed":false,"lateNoted":false,"nightTransactionId":0,"morningSeen":false,"preferences":menu_preferences.duplicate(true)}
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
 if name_edit: name_edit.hide()
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

func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion or event is InputEventMouseButton:
  if ui: pointer_over_ui = ui.blocks_world_at(event.position)
  if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
   world_mouse_held = false

func _process(delta: float) -> void:
 elapsed += delta
 for i in range(impact_effects.size()-1,-1,-1):
  impact_effects[i].time -= delta
  if impact_effects[i].time <= 0: impact_effects.remove_at(i)
 if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): world_mouse_held = false
 transition_cooldown = maxf(0.0,transition_cooldown-delta)
 if mode != "PLAY": moving_this_frame = false
 if mode == "PLAY":
  process_movement(delta)
  update_map_passage()
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
    elif s.preferences.get("repeatAction",true) and world_mouse_held and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not pointer_over_ui:
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
 elif mode == "BUILD":
  var mouse = get_viewport().get_mouse_position()
  if not build_keyboard_preview and mouse.x > 175 and mouse.y > 80 and mouse.y < 308: build_preview_tile = screen_tile(mouse)
 if message_timer > 0: message_timer -= delta
 if ui: ui.refresh()
 queue_redraw()

func process_movement(delta: float) -> void:
 moving_this_frame = false
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
  moving_this_frame = candidate.distance_squared_to(old) > 0.000001
  if weight >= 32:
   move_weight_accumulator += delta
   if move_weight_accumulator >= 10:
    move_weight_accumulator -= 10
    s.stamina = maxi(0,s.stamina-1)
 if absf(v.x) > absf(v.y): s.facing = [1 if v.x > 0 else -1,0]
 else: s.facing = [0,1 if v.y > 0 else -1]

func can_walk(p: Vector2i) -> bool:
 if s.mapId == "ROAD01": return road_map.can_walk(p)
 if s.mapId == "CITY01": return city_map.can_walk(p)
 if s.mapId == "FARM01":
  if p.x < 0 or p.x >= 64 or p.y < 0 or p.y >= 48: return false
  if is_lake(p) or (p.x >= 8 and p.x <= 17 and p.y >= 8 and p.y <= 15): return false
  if FARM_HOUSE_FOOTPRINT.has_point(p): return false
  for id in s.objects:
   var ob = s.objects[id]
   if not ob.removed and tile_of(ob.at) == p: return false
  return true
 if not home_floor(p): return false
 for id in CONDEMNED:
  if s.condemned[id] > 0 and condemned_covers(id,p): return false
 for id in s.furniture:
  if furniture_covers(id,p): return false
 return true

func home_floor(p: Vector2i) -> bool:
 return p.x >= 1 and p.x < HOME_SIZE.x-1 and p.y >= 2 and p.y < HOME_SIZE.y-1 and (p.x != 11 or p.y == 4 or p.y == 5)

func condemned_covers(id: String,p: Vector2i) -> bool:
 var at = tile_of(CONDEMNED[id])
 var size = tile_of(CONDEMNED_SIZE[id])
 return p.x >= at.x and p.x < at.x+size.x and p.y >= at.y and p.y < at.y+size.y

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
   if event.keycode == KEY_ESCAPE and (ui.title_options or ui.new_slot_select or ui.overwrite_slot != 0):
    ui.title_options = false; ui.new_slot_select = false; ui.overwrite_slot = 0; ui.refresh(true); return
   if ui.title_options:
    change_option(event.keycode)
    ui.refresh(true)
    return
   if ui.overwrite_slot != 0: return
   if event.keycode >= KEY_1 and event.keycode <= KEY_3:
    slot = event.keycode - KEY_0
    if ui.new_slot_select: ui.choose_new_slot(slot); ui.refresh(true)
    elif ui.overwrite_slot == 0:
     if FileAccess.file_exists(save_path(slot)): load_game(slot)
     else: ui.start_new_game_in_slot(slot); ui.refresh(true)
   elif event.keycode == KEY_N: ui.request_new_game(); ui.refresh(true)
  elif mode == "NAME":
   if event.keycode == KEY_ENTER: new_game(name_edit.text)
   elif event.keycode == KEY_ESCAPE: mode = "TITLE"; ui.refresh(true)
  elif mode == "INTRO":
   if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER: advance_intro()
   elif event.keycode == KEY_ESCAPE: skip_intro()
  elif mode == "PLAY":
   if event.keycode >= KEY_1 and event.keycode <= KEY_8: selected = event.keycode - KEY_1
   elif event.keycode == KEY_E: interact()
   elif event.keycode == KEY_I: mode = "MODAL"; modal = "inventory"; inventory_cursor = 0
   elif event.keycode == KEY_J: mode = "MODAL"; modal = "journal"
   elif event.keycode == KEY_B and s.mapId == "HOME01": mode = "BUILD"; editor_item = ""; editor_rotation = 0; build_keyboard_preview = false
   elif event.keycode == KEY_ESCAPE: mode = "MODAL"; modal = "pause"
   elif event.keycode == KEY_F5: save_game(slot); say("Partida salva.")
   elif event.keycode == KEY_F9: load_game(slot)
  elif mode == "MODAL":
   if event.keycode == KEY_ESCAPE:
    if modal == "options": modal = "pause"
    elif modal == "waste_confirm": modal = "sales"
    else: mode = "PLAY"; modal = ""
   elif event.keycode == KEY_I or event.keycode == KEY_J: mode = "PLAY"; modal = ""
   elif modal == "inventory" and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
    var step = -1 if event.keycode == KEY_LEFT else 1 if event.keycode == KEY_RIGHT else -6 if event.keycode == KEY_UP else 6
    inventory_cursor = clampi(inventory_cursor+step,0,23)
    ui.update_inventory_selection()
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
    confirm_repair()
   elif event.keycode == KEY_S and modal == "pause": save_game(slot); say("Partida salva.")
   elif modal == "inventory" and event.keycode >= KEY_6 and event.keycode <= KEY_8:
    assign_hotbar(event.keycode-KEY_1,inventory_item_at(inventory_cursor))
  elif mode == "BUILD":
   if event.keycode == KEY_ESCAPE: editor_item = ""; mode = "PLAY"
   elif event.keycode == KEY_R: editor_rotation = (editor_rotation+1)%4
   elif event.keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_LEFT,KEY_DOWN,KEY_RIGHT]:
    var offset = Vector2i.ZERO
    if event.keycode in [KEY_W,KEY_UP]: offset = Vector2i.UP
    elif event.keycode in [KEY_S,KEY_DOWN]: offset = Vector2i.DOWN
    elif event.keycode in [KEY_A,KEY_LEFT]: offset = Vector2i.LEFT
    else: offset = Vector2i.RIGHT
    build_preview_tile = Vector2i(clampi(build_preview_tile.x+offset.x,0,HOME_SIZE.x-1),clampi(build_preview_tile.y+offset.y,0,HOME_SIZE.y-1))
    build_keyboard_preview = true
   elif event.keycode == KEY_ENTER and editor_item != "": place_furniture(editor_item,build_preview_tile,editor_rotation)
   elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
    editor_item = ["bed","sofa","stove","sink","bench"][event.keycode-KEY_1]
    editor_rotation = s.furniture[editor_item].rotation
 if event is InputEventMouseMotion and mode == "BUILD":
  if event.position.x > 175 and event.position.y > 80 and event.position.y < 308: build_keyboard_preview = false
 if event is InputEventMouseButton and event.pressed:
  if mode == "PLAY":
   if event.button_index == MOUSE_BUTTON_LEFT: world_mouse_held = true; begin_action()
   elif event.button_index == MOUSE_BUTTON_RIGHT: interact()
   elif event.button_index == MOUSE_BUTTON_WHEEL_UP: selected = (selected+7)%8
   elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: selected = (selected+1)%8
  elif mode == "BUILD" and event.button_index == MOUSE_BUTTON_LEFT and editor_item != "":
   place_furniture(editor_item, screen_tile(event.position), editor_rotation)
  elif mode == "INTRO" and event.button_index == MOUSE_BUTTON_LEFT: advance_intro()
 elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
  world_mouse_held = false

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

func confirm_repair() -> void:
 mode = "PLAY"; modal = ""
 if action_check("TOOL_HAMMER",repair_target) == "":
  pending = {"tool":"TOOL_HAMMER","target":[repair_target.x,repair_target.y]}
  action_timer = 0.55

func furniture_name(id: String) -> String:
 return str({"bed":"Cama","sofa":"Sofá","stove":"Fogão","sink":"Pia","bench":"Banco"}.get(id,id))

func action_check(tool: String, p: Vector2i) -> String:
 if s.mapId in ["ROAD01","CITY01"]: return "Cuide da sua fazenda ao voltar."
 if s.mapId != "FARM01" and tool in ["SEED_CORN","TOOL_WATER"]: return "Cultive na fazenda."
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
   if ob.kind.begins_with("stone"):
    impact_effects.append({"id":"props/rock_%s_3" % ob.kind.trim_prefix("stone_"),"at":[p.x,p.y],"time":0.32})
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
 say("Atalho %d: %s" % [index+1,short_name(item)])
 return true

func deposit_storage(item: String) -> bool:
 if not ["wood","stone","fiber","scrap","waste","corn"].has(item): return false
 if int(s.inventory.get(item,0)) <= 0: say("Nada para guardar."); return false
 s.inventory[item] -= 1
 s.storage[item] = int(s.storage.get(item,0))+1
 save_game(slot)
 say("1 %s guardado na encomenda." % short_name(item))
 return true

func withdraw_storage(item: String) -> bool:
 if int(s.storage.get(item,0)) <= 0: say("Estoque vazio."); return false
 if not can_add(item,1): say("Mochila pesada ou cheia."); return false
 s.storage[item] -= 1
 s.inventory[item] = int(s.inventory.get(item,0))+1
 save_game(slot)
 say("1 %s retirado do estoque." % short_name(item))
 return true

func change_option(code: int) -> void:
 var preferences: Dictionary = s.preferences if not s.is_empty() else menu_preferences
 if code == KEY_1:
  var scales = [1.0,1.25,1.5]
  var index = scales.find(float(preferences.uiScale))
  preferences.uiScale = scales[(index+1)%3]
 elif code == KEY_2: preferences.highContrast = not preferences.highContrast
 elif code == KEY_3: preferences.repeatAction = not preferences.repeatAction
 elif code == KEY_4: preferences.effectsVolume = maxf(0.0,float(preferences.effectsVolume)-0.25)
 elif code == KEY_5: preferences.effectsVolume = minf(1.0,float(preferences.effectsVolume)+0.25)
 if audio_player: audio_player.volume_db = linear_to_db(maxf(0.001,float(preferences.effectsVolume)))
 if not s.is_empty(): save_game(slot)

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
 if is_lake(p) or lake_shore(p) or FARM_HOUSE_FOOTPRINT.has_point(p): return false
 if p.x >= 8 and p.x <= 17 and p.y >= 8 and p.y <= 15: return false
 if p.x >= 57 and p.y >= 9 and p.y <= 12: return false
 if object_at(p) != "": return false
 return true

func is_lake(p: Vector2i) -> bool:
 var row = p.y-LAKE_TOP
 return row >= 0 and row < LAKE_LEFT.size() and p.x >= LAKE_LEFT[row] and p.x <= LAKE_RIGHT[row]

func lake_shore(p: Vector2i) -> bool:
 if is_lake(p): return false
 for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
  if is_lake(p+direction): return true
 return false
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
  if s.condemned[id] > 0 and condemned_covers(id,p): return id
 return ""
func dirt_at(p: Vector2i) -> String:
 if s.mapId != "HOME01": return ""
 for id in DIRT:
  if not s.dirt[id] and tile_of(DIRT[id]) == p: return id
 return ""
func repair_at(p: Vector2i) -> String:
 if s.mapId not in ["FARM01","HOME01"]: return ""
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
   transition_to("HOME01",HOME_ENTRY); return
  if p.distance_to(Vector2i(57,14)) <= 2:
   mode = "MODAL"; modal = "sales"; return
  if p.distance_to(Vector2i(60,14)) <= 2:
   mode = "MODAL"; modal = "mail"; return
  if p.distance_to(Vector2i(60,15)) <= 2:
   take_fruit(); return
  if near_lake(p) and selected_item() == "TOOL_WATER":
   if s.stamina < 1: say("Falta 1 de estamina."); return
   s.stamina -= 1; s.water = 20; say("Regador cheio."); return
  if road_portal():
   if not arrival_latch: transition_to("ROAD01",ROAD_ENTRY)
   return
  if p.y <= 1 or p.y >= 46:
   say("Esta saída ficará para depois."); return
  if p.x >= 8 and p.x <= 18 and p.y >= 8 and p.y <= 16: say("Esta construção ficará para depois."); return
 elif s.mapId == "ROAD01":
  if road_portal():
   if not arrival_latch:
    if p.x <= 2: transition_to("FARM01",FARM_ROAD_ENTRY)
    else: transition_to("CITY01",CITY_ENTRY)
   return
 elif s.mapId == "CITY01":
  if road_portal():
   if not arrival_latch: transition_to("ROAD01",ROAD_CITY_ENTRY)
   return
 elif s.mapId == "HOME01":
  if p.y >= HOME_ENTRY.y and p.x >= HOME_ENTRY.x and p.x <= HOME_ENTRY.x+1:
   transition_to("FARM01",Vector2i(49,17)); return
  if s.repairs.H04.completed and near_furniture("bed",p):
   mode = "MODAL"; modal = "sleep"; return
  if near_furniture("bench",p): say("Um banco simples."); return
 say("Nada para interagir aqui.")

func near_lake(p: Vector2i) -> bool:
 return s.mapId == "FARM01" and can_walk(p) and lake_shore(p)
func near_furniture(id: String,p: Vector2i) -> bool:
 if not s.furniture[id].placed: return false
 var at = tile_of(s.furniture[id].at)
 var size = furniture_size(id,s.furniture[id].rotation)
 return p.x >= at.x-1 and p.x <= at.x+size.x and p.y >= at.y-1 and p.y <= at.y+size.y
func transition_to(map_id: String,p: Vector2i) -> void:
 mode = "TRANSITION"
 transition_cooldown = 0.5
 reset_pending_actions()
 s.mapId = map_id
 s.position = [p.x+0.5,p.y+0.9]
 arrival_latch = road_portal()
 update_camera()
 mode = "PLAY"
 save_game(slot)

func road_portal() -> bool:
 var p = tile_of(s.position)
 if s.mapId == "FARM01": return p.x >= 61 and p.y >= 16 and p.y <= 18
 if s.mapId == "ROAD01": return (p.x <= 2 and abs(p.y-road_map.center_row(p.x)) <= 4) or (p.x >= 46 and abs(p.y-road_map.center_row(p.x)) <= 2)
 if s.mapId == "CITY01": return p.x <= 2 and abs(p.y-13) <= 2
 return false

func update_map_passage() -> void:
 if not road_portal():
  arrival_latch = false
  return
 if arrival_latch or transition_cooldown > 0 or mode != "PLAY": return
 var p = tile_of(s.position)
 if s.mapId == "FARM01" and p.x >= 63: transition_to("ROAD01",ROAD_ENTRY)
 elif s.mapId == "ROAD01" and p.x == 0: transition_to("FARM01",FARM_ROAD_ENTRY)
 elif s.mapId == "ROAD01" and p.x == 47: transition_to("CITY01",CITY_ENTRY)
 elif s.mapId == "CITY01" and p.x == 0: transition_to("ROAD01",ROAD_CITY_ENTRY)

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

func collect_waste() -> bool:
 if int(s.inventory.get("waste",0)) <= 0: say("Não há resíduo na mochila."); return false
 s.inventory.waste -= 1
 save_game(slot)
 say("Resíduo encaminhado para coleta, sem moedas.")
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
  if s.repairs.H04.completed and s.mapId == "HOME01":
   var wake = bed_wake_tile()
   s.position = [wake.x+0.5,wake.y+0.5]
  else: s.mapId = "FARM01"; s.position = [49.5,17.9]
  if s.validSleepDay == night and not s.completed:
   s.completed = true
   say("Bom dia! Casa restaurada, milho brotando. Missão concluída!")
  else: say("Um novo dia. A estamina continua em %d." % s.stamina)
  save_game(slot)
 mode = "PLAY"

func bed_wake_tile() -> Vector2i:
 if not s.furniture.bed.placed: return HOME_ENTRY
 var at = tile_of(s.furniture.bed.at)
 var size = furniture_size("bed",int(s.furniture.bed.rotation))
 var choices: Array[Vector2i] = []
 for y in range(at.y-1,at.y+size.y+1):
  for x in range(at.x-1,at.x+size.x+1):
   var p = Vector2i(x,y)
   if x != at.x-1 and x != at.x+size.x and y != at.y-1 and y != at.y+size.y: continue
   if can_walk(p): choices.append(p)
 if choices.is_empty(): return HOME_ENTRY
 choices.sort_custom(func(a: Vector2i,b: Vector2i) -> bool: return a.distance_squared_to(HOME_WAKE) < b.distance_squared_to(HOME_WAKE))
 return choices[0]

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
 if p.x < 1 or p.y < 2 or p.x+size.x >= HOME_SIZE.x or p.y+size.y >= HOME_SIZE.y: return "Fora do piso interno."
 if id in ["stove","sink"] and (p.x+size.x > 11 or p.y > 4): return "Fogão e pia ficam na cozinha."
 var occupied: Array[Vector2i] = []
 for y in range(p.y,p.y+size.y):
  for x in range(p.x,p.x+size.x):
   var t = Vector2i(x,y)
   if not home_floor(t) or x == 11 or y == HOME_ENTRY.y and x >= HOME_ENTRY.x and x <= HOME_ENTRY.x+1 or x == 10 and y >= 4 and y <= 6 or x == 12 and y >= 4 and y <= 5: return "Bloqueia uma passagem."
   if condemned_at(t) != "" or dirt_at(t) != "": return "Limpe ou remova o objeto primeiro."
   for other in s.furniture:
    if other != id and furniture_covers(other,t): return "Outro móvel ocupa o espaço."
   occupied.append(t)
 # Breadth-first walk from door; require kitchen doorway and an adjacent bed tile.
 var open: Array[Vector2i] = [HOME_ENTRY]
 var seen: Dictionary = {}
 while not open.is_empty():
  var t = open.pop_front()
  if seen.has(key(t)): continue
  seen[key(t)] = true
  for v in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var n = t+v
   if not home_floor(n): continue
   if condemned_at(n) != "" or dirt_at(n) != "": continue
   if n in occupied: continue
   var blocked := false
   for other in s.furniture:
    if other != id and furniture_covers(other,n): blocked = true
   if not blocked and not seen.has(key(n)): open.append(n)
 if not seen.has(key(Vector2i(12,5))) or not seen.has(key(Vector2i(3,5))): return "Bloqueia o quarto ou a cozinha."
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
 if not parsed is Dictionary or int(parsed.get("schemaVersion",-1)) != SAVE_SCHEMA: say("Partida salva incompatível."); return false
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
 var migrated = int(s.get("homeLayoutVersion",0)) < HOME_LAYOUT_VERSION
 if migrated: migrate_home_layout()
 if s.mapId == "FARM01" and FARM_HOUSE_FOOTPRINT.has_point(tile_of(s.position)):
  s.position = [49.5,17.9]
 if s.mapId == "ROAD01" and (not can_walk(tile_of(s.position)) or road_portal()):
  s.position = [ROAD_ENTRY.x+0.5,ROAD_ENTRY.y+0.9]
 if s.mapId == "CITY01" and (not can_walk(tile_of(s.position)) or road_portal()):
  s.position = [CITY_ENTRY.x+0.5,CITY_ENTRY.y+0.9]
 arrival_latch = road_portal()
 update_camera()
 if name_edit: name_edit.hide()
 mode = "PLAY" if s.liaExited else "INTRO"
 if mode == "INTRO":
  dialog_index = 0
  intro_letter_seen = false
  lia_x = 63.0
  lia_arriving = true
  lia_leaving = false
 if migrated: save_game(n)
 queue_redraw()
 return true

func migrate_home_layout() -> void:
 var legacy_defaults = {"bed":Vector2i(19,7),"sofa":Vector2i(8,10),"stove":Vector2i(3,3),"sink":Vector2i(6,3)}
 var old_furniture: Dictionary = s.furniture.duplicate(true)
 for id in FURNITURE:
  s.furniture[id] = {"at":FURNITURE[id].at.duplicate(),"rotation":int(old_furniture.get(id,{}).get("rotation",0)),"placed":false}
 for id in ["bed","stove","sink","sofa","bench"]:
  var old: Dictionary = old_furniture.get(id,{})
  if not bool(old.get("placed",false)): continue
  var old_at = tile_of(old.get("at",FURNITURE[id].at))
  var desired = tile_of(FURNITURE[id].at) if legacy_defaults.has(id) and old_at == legacy_defaults[id] else project_legacy_home_tile(old_at)
  var found = migration_furniture_position(id,desired,int(old.get("rotation",0)))
  if found.x >= 0:
   s.furniture[id].at = [found.x,found.y]
   s.furniture[id].placed = true
  elif id == "bench":
   s.mail.bench = int(s.mail.get("bench",0))+1
   say("Banco antigo guardado no correio para recolocação.")
  else: say("Um móvel antigo ficou disponível no editor para recolocação.")
 for id in s.drops:
  var drop = s.drops[id]
  if drop.mapId != "HOME01": continue
  var drop_at = migration_free_tile(project_legacy_home_tile(tile_of(drop.at)))
  if drop_at.x >= 0: drop.at = [drop_at.x,drop_at.y]
  else:
   s.storage[drop.item] = int(s.storage.get(drop.item,0))+int(drop.amount)
   drop.mapId = "STORED"
 if s.mapId == "HOME01":
  var player_at = migration_free_tile(project_legacy_home_tile(tile_of(s.position)))
  if player_at.x < 0: player_at = HOME_ENTRY
  s.position = [player_at.x+0.5,player_at.y+0.5]
 s.homeLayoutVersion = HOME_LAYOUT_VERSION

func project_legacy_home_tile(p: Vector2i) -> Vector2i:
 return Vector2i(clampi(roundi(1.0+(p.x-1)*14.0/21.0),1,HOME_SIZE.x-2),clampi(roundi(2.0+(p.y-1)*6.0/15.0),2,HOME_SIZE.y-2))

func migration_furniture_position(id: String,desired: Vector2i,rotation: int) -> Vector2i:
 var positions: Array[Vector2i] = []
 for y in range(2,HOME_SIZE.y-1):
  for x in range(1,HOME_SIZE.x-1): positions.append(Vector2i(x,y))
 positions.sort_custom(func(a: Vector2i,b: Vector2i) -> bool: return a.distance_squared_to(desired) < b.distance_squared_to(desired) if a.distance_squared_to(desired) != b.distance_squared_to(desired) else a.y < b.y if a.y != b.y else a.x < b.x)
 for p in positions:
  if migration_furniture_fits(id,p,rotation): return p
 return Vector2i(-1,-1)

func migration_furniture_fits(id: String,p: Vector2i,rotation: int) -> bool:
 var size = furniture_size(id,rotation)
 if id in ["stove","sink"] and (p.x+size.x > 11 or p.y > 4): return false
 for y in range(p.y,p.y+size.y):
  for x in range(p.x,p.x+size.x):
   var tile = Vector2i(x,y)
   if not home_floor(tile) or x == 11 or y == HOME_ENTRY.y and x >= HOME_ENTRY.x and x <= HOME_ENTRY.x+1 or x == 10 and y >= 4 and y <= 6 or x == 12 and y >= 4 and y <= 5: return false
   for condemned_id in CONDEMNED:
    if int(s.condemned.get(condemned_id,0)) > 0 and condemned_covers(condemned_id,tile): return false
   for dirt_id in DIRT:
    if not bool(s.dirt.get(dirt_id,false)) and tile_of(DIRT[dirt_id]) == tile: return false
   for other in s.furniture:
    if other != id and furniture_covers(other,tile): return false
 var previous = s.furniture[id].duplicate(true)
 s.furniture[id] = {"at":[p.x,p.y],"rotation":rotation,"placed":true}
 var seen = home_reachable_tiles()
 var valid = seen.has(key(Vector2i(3,5))) and seen.has(key(Vector2i(12,5)))
 if valid:
  for repair_id in ["H02","H03","H04","H05","H06","H07"]:
   if s.repairs[repair_id].completed: continue
   var target = tile_of(REPAIRS[repair_id].at)
   var adjacent = false
   for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    if seen.has(key(target+direction)): adjacent = true
   if not adjacent: valid = false
 if valid and s.furniture.bed.placed:
  valid = false
  var bed_at = tile_of(s.furniture.bed.at)
  var bed_size = furniture_size("bed",int(s.furniture.bed.rotation))
  for y in range(bed_at.y-1,bed_at.y+bed_size.y+1):
   for x in range(bed_at.x-1,bed_at.x+bed_size.x+1):
    if x == bed_at.x-1 or x == bed_at.x+bed_size.x or y == bed_at.y-1 or y == bed_at.y+bed_size.y:
     if seen.has(key(Vector2i(x,y))): valid = true
 s.furniture[id] = previous
 return valid

func home_reachable_tiles() -> Dictionary:
 var open: Array[Vector2i] = [HOME_ENTRY]
 var seen: Dictionary = {}
 while not open.is_empty():
  var p = open.pop_front()
  if seen.has(key(p)) or not home_floor(p) or home_tile_blocked(p): continue
  seen[key(p)] = true
  for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]: open.append(p+direction)
 return seen

func migration_free_tile(desired: Vector2i) -> Vector2i:
 var positions: Array[Vector2i] = []
 for y in range(2,HOME_SIZE.y-1):
  for x in range(1,HOME_SIZE.x-1): positions.append(Vector2i(x,y))
 positions.sort_custom(func(a: Vector2i,b: Vector2i) -> bool: return a.distance_squared_to(desired) < b.distance_squared_to(desired) if a.distance_squared_to(desired) != b.distance_squared_to(desired) else a.y < b.y if a.y != b.y else a.x < b.x)
 var reachable = home_reachable_tiles()
 for p in positions:
  if reachable.has(key(p)): return p
 return Vector2i(-1,-1)

func home_tile_blocked(p: Vector2i) -> bool:
 for id in CONDEMNED:
  if int(s.condemned.get(id,0)) > 0 and condemned_covers(id,p): return true
 for id in s.furniture:
  if furniture_covers(id,p): return true
 return false
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

func asset(id: String, ground: Vector2, sprite_scale: float = 1.0) -> bool:
 if not asset_textures.has(id): return false
 var tex: Texture2D = asset_textures[id]
 var pivot = asset_manifest[id].get("pivot", [tex.get_width()/2,tex.get_height()])
 if sprite_scale == 1.0: draw_texture(tex,ground-Vector2(pivot[0],pivot[1]))
 else: draw_texture_rect(tex,Rect2((ground-Vector2(pivot[0],pivot[1])*sprite_scale).round(),Vector2(tex.get_size())*sprite_scale),false)
 return true

# Temporary vector art. Gameplay uses IDs and footprints; PNG exports can replace drawing.
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,Vector2(SIZE)),Color.BLACK if not s.is_empty() and s.mapId == "HOME01" else Color("243348"))
 if mode == "TITLE" or mode == "NAME": return
 if s.is_empty(): return
 var player = Vector2(s.position[0],s.position[1])*TILE
 update_camera()
 draw_set_transform(-camera_origin)
 if s.mapId == "FARM01": draw_farm()
 elif s.mapId == "ROAD01": draw_road()
 elif s.mapId == "CITY01": draw_city()
 else: draw_home()
 draw_drops()
 if mode == "INTRO" and not s.liaExited: draw_lia(Vector2(lia_x+0.5,12.9)*TILE)
 draw_actor(player)
 if s.mapId == "FARM01":
  draw_farm_crops(false,player.y)
  draw_farm_props(false,player.y)
  draw_impact_effects()
 elif s.mapId == "ROAD01": draw_road_props(false,player.y)
 elif s.mapId == "CITY01": draw_city_objects(false,player.y)
 if mode == "PLAY" or mode == "BUILD":
  var t = target_tile() if mode == "PLAY" else build_preview_tile
  var valid = action_check(selected_item(),t) == "" if mode == "PLAY" and TOOLS.has(selected_item()) else editor_item != "" and placement_error(editor_item,t,editor_rotation) == "" if mode == "BUILD" else false
  var color = Color("f1dfb1") if valid else Color("b85d43")
  draw_rect(Rect2(Vector2(t)*TILE,Vector2(TILE,TILE)),color,false,2)
  if mode == "BUILD" and editor_item != "":
   var footprint = furniture_size(editor_item,editor_rotation)
   draw_rect(Rect2(Vector2(t)*TILE,Vector2(footprint)*TILE),Color(color,0.35),true)
 draw_set_transform(Vector2.ZERO)

func update_camera() -> void:
 var player = Vector2(s.position[0],s.position[1])*TILE
 if s.mapId == "HOME01":
  camera_origin = (Vector2(HOME_SIZE)*TILE-Vector2(SIZE))*0.5
  return
 if s.mapId == "CITY01":
  camera_origin = (player-Vector2(SIZE)*0.5).round()
  camera_origin.x = clampf(camera_origin.x,CITY_MAP.BOUNDS.position.x*TILE,CITY_MAP.BOUNDS.end.x*TILE-SIZE.x)
  camera_origin.y = clampf(camera_origin.y,CITY_MAP.BOUNDS.position.y*TILE,CITY_MAP.BOUNDS.end.y*TILE-SIZE.y)
  return
 var map_size = ROAD_MAP.SIZE if s.mapId == "ROAD01" else Vector2i(64,48)
 camera_origin = (player-Vector2(SIZE)*0.5).round()
 camera_origin.x = clampf(camera_origin.x,0,map_size.x*TILE-SIZE.x)
 camera_origin.y = clampf(camera_origin.y,0,map_size.y*TILE-SIZE.y)

func draw_road() -> void:
 var first = Vector2i(floori(camera_origin.x/TILE),floori(camera_origin.y/TILE))
 for y in range(maxi(0,first.y),mini(ROAD_MAP.SIZE.y,first.y+13)):
  for x in range(maxi(0,first.x),mini(ROAD_MAP.SIZE.x,first.x+21)):
   var p = Vector2i(x,y)
   asset("ground/path" if road_map.is_path(p) else farm_sand_id(p),Vector2(p)*TILE+Vector2(16,32))
   if not road_map.is_path(p) and not road_map.blocked.has(p) and terrain_hash(p)%4 < 2:
    asset("props/grass_clump_%d" % (terrain_hash(p)%6+1),Vector2(p)*TILE+Vector2(16,32))
 draw_road_props(true,float(s.position[1])*TILE)

func draw_road_props(behind_actor: bool,actor_feet_y: float) -> void:
 for ob in road_map.props:
  if ((float(ob.at[1])+1.0)*TILE <= actor_feet_y) != behind_actor: continue
  var pos = Vector2(ob.at[0],ob.at[1])*TILE
  if prop_visible(prop_asset_id(ob),pos): draw_prop(ob,pos)

func draw_farm() -> void:
 var first = Vector2i(floori(camera_origin.x/TILE),floori(camera_origin.y/TILE))
 var last = first+Vector2i(21,13)
 var occupied: Dictionary = {}
 var grass_tiles: Array[Vector2i] = []
 var lake_sprite_ready = asset_textures.has("environment/lake_base")
 for id in s.objects:
  if not s.objects[id].removed: occupied[key(tile_of(s.objects[id].at))] = true
 for y in range(maxi(0,first.y),mini(48,last.y)):
  for x in range(maxi(0,first.x),mini(64,last.x)):
   var p = Vector2i(x,y)
   var c = Color("dfae55") if (x*17+y*13)%7 > 1 else Color("d5a751")
   if (x >= 56 and y >= 9 and y <= 12) or (x >= 47 and x <= 63 and y >= 16 and y <= 18): c = Color("c99854")
   if is_lake(p) and not lake_sprite_ready: c = Color("287fbd") if (x+y)%2 else Color("2c89be")
   if x >= 8 and x <= 17 and y >= 8 and y <= 15: c = Color("9b855c")
   if x >= 40 and x <= 44 and y >= 22 and y <= 25: c = Color("b99055")
   if s.soil.has(key(p)):
    c = Color("795335") if s.soil[key(p)].wateredDayId != s.day else Color("a36c3b")
   draw_rect(Rect2(Vector2(p)*TILE,Vector2(TILE,TILE)),c)
   if is_lake(p):
    if not lake_sprite_ready: asset("ground/water",Vector2(p)*TILE+Vector2(16,32))
   elif s.soil.has(key(p)):
    asset("ground/soil_wet" if s.soil[key(p)].wateredDayId == s.day else "ground/soil_tilled",Vector2(p)*TILE+Vector2(16,32))
   elif (x >= 56 and y >= 9 and y <= 12) or (x >= 47 and x <= 63 and y >= 16 and y <= 18): asset("ground/path",Vector2(p)*TILE+Vector2(16,32))
   elif (x >= 40 and x <= 44 and y >= 22 and y <= 25) or (x >= 8 and x <= 17 and y >= 8 and y <= 15): asset("ground/soil_untilled",Vector2(p)*TILE+Vector2(16,32))
   else:
    var sand_id = farm_sand_id(p)
    asset(sand_id,Vector2(p)*TILE+Vector2(16,32))
    if not occupied.has(key(p)) and farm_grass_clump(p): grass_tiles.append(p)
   if s.soil.has(key(p)):
    draw_rect(Rect2(Vector2(p)*TILE+Vector2(4,8),Vector2(24,15)),Color("70482f"),false,2)
 if lake_sprite_ready:
  asset("environment/lake_base",LAKE_ANCHOR*TILE)
  asset("environment/lake_water_%d" % (int(elapsed*2.0)%3),LAKE_ANCHOR*TILE)
 for p in grass_tiles:
  asset("props/grass_clump_%d" % (terrain_hash(p)%6+1),Vector2(p)*TILE+Vector2(16,32))
 # The ruin sprite covers the reserved x8..17, y8..15 footprint.
 if not asset("props/ruin",Vector2(13,16)*TILE):
  draw_rect(Rect2(8*TILE,8*TILE,10*TILE,8*TILE),Color("70482f"),false,7)
  world_label("RUÍNAS",Vector2(10,10)*TILE,18,Color("f1dfb1"))
 if not asset("buildings/house_H01_restored" if s.repairs.H01.completed else "buildings/house_H01_old",Vector2(49.5,16)*TILE,FARM_HOUSE_SCALE):
  draw_rect(Rect2(Vector2(FARM_HOUSE_FOOTPRINT.position)*TILE,Vector2(FARM_HOUSE_FOOTPRINT.size)*TILE),Color("f1dfb1") if s.repairs.H01.completed else Color("b7a276"))
 asset("buildings/repair_H03_window_open" if s.repairs.H03.completed else "buildings/repair_H03_window_boarded",(Vector2(49.5,16)+(Vector2(53,14)-Vector2(49.5,16))*FARM_HOUSE_SCALE)*TILE,FARM_HOUSE_SCALE)
 if not asset("props/sales_chest",Vector2(57.5,15)*TILE): draw_rect(Rect2(57*TILE,14*TILE,30,29),Color("70482f"))
 if not asset("props/mailbox",Vector2(60.5,15)*TILE): draw_rect(Rect2(60*TILE,14*TILE,29,29),Color("e6b539"))
 draw_farm_crops(true,Vector2(s.position[0],s.position[1]).y*TILE)
 draw_farm_props(true,Vector2(s.position[0],s.position[1]).y*TILE)
 for p in [Vector2i(31,0),Vector2i(63,17),Vector2i(38,47)]:
  draw_rect(Rect2(Vector2(p)*TILE,Vector2(30,30)),Color("b85d43"),false,3)

func terrain_hash(p: Vector2i) -> int:
 return posmod(p.x*92821+p.y*68917+p.x*p.y*257,997)

func farm_sand_id(p: Vector2i) -> String:
 var patch = posmod(floori(p.x/4.0)*37+floori(p.y/4.0)*53,17)
 if patch < 5 and terrain_hash(p)%7 < 5: return "ground/sand_variant_%d" % (terrain_hash(p)%3+1)
 return "ground/grass"

func farm_grass_clump(p: Vector2i) -> bool:
 if p.x >= 43 and p.x <= 56 and p.y >= 5 and p.y <= 18: return false
 if p.x >= 39 and p.x <= 45 and p.y >= 21 and p.y <= 26: return false
 if is_lake(p) or lake_shore(p): return false
 if (p.x >= 56 and p.y >= 9 and p.y <= 12) or (p.x >= 47 and p.x <= 63 and p.y >= 16 and p.y <= 18): return false
 if p.x >= 8 and p.x <= 17 and p.y >= 8 and p.y <= 15: return false
 if lake_distance(p) <= 3:
  var lake_patches = [Vector2i(13,29),Vector2i(24,33),Vector2i(25,36),Vector2i(19,43),Vector2i(13,43),Vector2i(6,36)]
  var offsets = [Vector2i.ZERO,Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(1,1)]
  for i in lake_patches.size():
   for j in range(3+i%3):
    if p == lake_patches[i]+offsets[j]: return true
  return false
 var cluster = posmod(floori(p.x/3.0)*71+floori(p.y/3.0)*113,13)
 return cluster < 4 and terrain_hash(p)%3 < 2

func lake_distance(p: Vector2i) -> int:
 var distance := 1000
 for row in LAKE_LEFT.size():
  var nearest_x = clampi(p.x,LAKE_LEFT[row],LAKE_RIGHT[row])
  distance = mini(distance,absi(p.y-(LAKE_TOP+row))+absi(p.x-nearest_x))
 return distance

func draw_farm_props(behind_actor: bool,actor_feet_y: float) -> void:
 var visible: Array[String] = []
 for id in s.objects:
  var ob = s.objects[id]
  if ob.removed: continue
  var behind = (float(ob.at[1])+1.0)*TILE <= actor_feet_y
  if behind != behind_actor: continue
  var pos = Vector2(ob.at[0],ob.at[1])*TILE
  if not prop_visible(prop_asset_id(ob),pos): continue
  visible.append(id)
 visible.sort_custom(func(a: String,b: String) -> bool: return int(s.objects[a].at[1]) < int(s.objects[b].at[1]) if int(s.objects[a].at[1]) != int(s.objects[b].at[1]) else a < b)
 for id in visible: draw_prop(s.objects[id],Vector2(s.objects[id].at[0],s.objects[id].at[1])*TILE)

func prop_visible(id: String,pos: Vector2) -> bool:
 var size = asset_manifest.get(id,{}).get("size",[96,128])
 var pivot = asset_manifest.get(id,{}).get("pivot",[48,128])
 var anchor = pos+Vector2(16,32)
 var bounds = Rect2(anchor-Vector2(pivot[0],pivot[1]),Vector2(size[0],size[1]))
 return bounds.intersects(Rect2(camera_origin,Vector2(SIZE)))

func draw_impact_effects() -> void:
 for effect in impact_effects:
  var p = tile_of(effect.at)
  asset(str(effect.id),Vector2(p)*TILE+Vector2(16,32))

func draw_farm_crops(behind_actor: bool,actor_feet_y: float) -> void:
 var visible: Array[Vector2i] = []
 for id in s.soil:
  var soil = s.soil[id]
  if soil.cropId != "crop_corn": continue
  var coords = id.split(",")
  var p = Vector2i(int(coords[0]),int(coords[1]))
  if (float(p.y+1)*TILE <= actor_feet_y) != behind_actor: continue
  if p.x*TILE < camera_origin.x-64 or p.x*TILE > camera_origin.x+SIZE.x+64 or p.y*TILE < camera_origin.y-64 or p.y*TILE > camera_origin.y+SIZE.y+64: continue
  visible.append(p)
 visible.sort_custom(func(a: Vector2i,b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
 for p in visible: draw_crop(p,s.soil[key(p)].cropAge)

func draw_crop(p: Vector2i,age: int) -> void:
 if asset("crops/crop_corn_stage%d" % (age+1),Vector2(p)*TILE+Vector2(16,32)): return
 var center = Vector2(p)*TILE+Vector2(16,20)
 var height = 5+age*5
 draw_line(center,center+Vector2(0,-height),Color("245e46"),3)
 draw_circle(center+Vector2(0,-height),3+age,Color("4f7838"))

func prop_asset_id(ob: Dictionary) -> String:
 var kind: String = ob.kind
 match kind:
  "tree","stump":
   var species = ["umbu","juazeiro","catingueira","jurema"][int(ob.get("variant",0))%4]
   return "flora/object_tree_%s_%s" % [species,"stump" if kind == "stump" else "stage%d" % (int(ob.stage)+1)]
  "bush": return "props/bush_%d" % (int(ob.get("variant",0))%3+1)
  "mandacaru","cactus":
   var base = "mandacaru" if kind == "mandacaru" else "palma"
   var variant = int(ob.get("variant",0))%3+1
   return "props/%s%s" % [base,"" if variant == 1 else "_%d" % variant]
  "stone_small","stone_medium","stone_large":
   var rock_size = kind.trim_prefix("stone_")
   return "props/rock_%s_%d" % [rock_size,1 if int(ob.hits) == int(ob.maxHits) else 2]
  "stick","log": return "props/%s%s" % [kind,"" if int(ob.get("variant",0))%2 == 0 else "_2"]
  "trash_metal": return "icons/scrap"
  "trash_plastic": return "icons/trash"
 return ""

func draw_prop(ob: Dictionary,pos: Vector2) -> void:
 var kind: String = ob.kind
 var id = prop_asset_id(ob)
 if id != "" and asset(id,pos+Vector2(16,32)):
  if ob.hits < ob.maxHits and not kind.begins_with("stone"): draw_line(pos+Vector2(6,5),pos+Vector2(25,24),Color("f1dfb1"),2)
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
 for y in range(HOME_SIZE.y):
  for x in range(HOME_SIZE.x):
   var wall = y < 2 or not home_floor(Vector2i(x,y)) and not (y == HOME_SIZE.y-1 and x >= HOME_ENTRY.x and x <= HOME_ENTRY.x+1)
   var c = Color("a36c3b") if s.repairs.H02.completed else Color("886644")
   if wall: c = Color("f1dfb1") if s.repairs.H02.completed else Color("b7a276")
   draw_rect(Rect2(x*TILE,y*TILE,TILE,TILE),c)
   var ground_id = "ground/wall_new" if wall and s.repairs.H02.completed else "ground/wall_old" if wall else "ground/floor_new" if s.repairs.H02.completed else "ground/floor_old"
   asset(ground_id,Vector2(x*TILE+16,y*TILE+32))
   if home_floor(Vector2i(x,y)) and not s.repairs.H02.completed: draw_rect(Rect2(x*TILE,y*TILE,TILE,TILE),Color("70482f",0.2),false,1)
 # North wall is two tiles high; H03 changes the windows independently of H02.
 var wall_id = "interior/north_wall_new" if s.repairs.H02.completed else "interior/north_wall_old"
 for x in range(HOME_SIZE.x): asset(wall_id,Vector2(x+0.5,2)*TILE)
 var window_id = "interior/window_new" if s.repairs.H03.completed else "interior/window_old"
 for window_x in [5,14]:
  if not asset(window_id,Vector2(window_x,2)*TILE):
   draw_rect(Rect2(Vector2(window_x-1,0)*TILE,Vector2(2,2)*TILE),Color("287fbd") if s.repairs.H03.completed else Color("65727c"))
 draw_rect(Rect2(Vector2(HOME_ENTRY.x,HOME_SIZE.y-1)*TILE,Vector2(2,1)*TILE),Color("70482f"),false,2)
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
   var size = Vector2(tile_of(CONDEMNED_SIZE[id]))*TILE
   if not asset("furniture/"+kind,pos+Vector2(size.x/2,size.y)): draw_rect(Rect2(pos+Vector2(2,4),size-Vector2(4,6)),Color("70482f"))
 for id in s.furniture:
  if not s.furniture[id].placed: continue
  var f = s.furniture[id]
  var pos = Vector2(tile_of(f.at))*TILE
  var size = Vector2(furniture_size(id,f.rotation))*TILE
  var repaired = id == "bench" or s.repairs[FURNITURE[id].repair].completed
  var furniture_sprite = "furniture/%s_intact_r%d" % [id,int(f.rotation)] if repaired else "furniture/%s_broken" % id
  if not asset(furniture_sprite,pos+Vector2(size.x/2,size.y)) and not asset("furniture/"+id+("" if id == "bench" else "_intact" if repaired else "_broken"),pos+Vector2(size.x/2,size.y)):
   draw_rect(Rect2(pos+Vector2(2,2),size-Vector2(4,4)),Color("4f7838") if repaired else Color("70482f"))
 for id in REPAIRS:
  if id == "H01" or s.repairs[id].completed: continue
  var pos = Vector2(tile_of(REPAIRS[id].at))*TILE
  if Vector2(s.position[0],s.position[1]).distance_to(Vector2(tile_of(REPAIRS[id].at))) < 3.0:
   world_label("!",pos+Vector2(3,30),16,Color("e6b539"))

func draw_drops() -> void:
 var positions: Dictionary = {}
 for id in s.drops:
  var d = s.drops[id]
  if d.mapId != s.mapId: continue
  var tile_key = key(tile_of(d.at))
  var index = int(positions.get(tile_key,0))
  positions[tile_key] = index+1
  var pos = Vector2(d.at[0],d.at[1])*TILE+Vector2(16+(index%3-1)*7,17+int(index/3)*5)
  draw_circle(pos+Vector2(0,7),9,Color("243348",0.3))
  var icon = icon_id(str(d.item))
  if asset_textures.has(icon):
   var texture: Texture2D = asset_textures[icon]
   draw_texture(texture,pos-texture.get_size()*0.5)
  else: draw_circle(pos,6,Color("e6b539"))
  if int(d.amount) > 1: world_label(str(d.amount),pos+Vector2(7,11),10,Color("f1dfb1"))

func draw_actor(pos: Vector2) -> void:
 draw_set_transform(-camera_origin+pos,0.0,Vector2.ONE*ACTOR_SCALE)
 draw_actor_unscaled(Vector2.ZERO)
 draw_set_transform(-camera_origin)

func draw_actor_unscaled(pos: Vector2) -> void:
 if food_timer > 0 and reference_action_ready("actors/action_eat") and draw_food_sheet(pos,tile_of(s.facing)): return
 if action_timer > 0 and not pending.is_empty():
  var action_id = {"TOOL_AXE":"axe","TOOL_PICK":"pick","TOOL_HOE":"hoe","TOOL_SCYTHE":"scythe","TOOL_WATER":"water","TOOL_HAMMER":"hammer","SEED_CORN":"sow","HAND":"clean"}.get(pending.tool,"")
  if action_id != "" and reference_action_ready("actors/action_"+action_id) and draw_action_sheet("actors/action_"+action_id,pos,tile_of(s.facing)): return
 if draw_actor_sheet("actors/actor_player",pos,tile_of(s.facing),moving_this_frame):
  draw_actor_action_overlay(pos)
  return
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

func reference_action_ready(id: String) -> bool:
 return asset_textures.has(id) and asset_manifest.get(id,{}).get("status","") == "prototype_reference_derived"

func draw_actor_action_overlay(pos: Vector2) -> void:
 if food_timer <= 0 and (action_timer <= 0 or pending.is_empty()): return
 var direction = Vector2(s.facing[0],s.facing[1])
 if direction == Vector2.ZERO: direction = Vector2.DOWN
 var hand = pos+Vector2(direction.x*9,-37+direction.y*5)
 if food_timer > 0:
  var icon = icon_id(food_pending)
  if asset_textures.has(icon): asset(icon,hand+Vector2(0,13))
  else: draw_circle(hand,4,Color("dfae55"))
  return
 var contact = action_timer < 0.4 and action_timer > 0.18
 var tip = hand+direction*(23 if contact else 13)
 draw_line(hand,tip,Color("dfae55"),3)
 if contact: draw_circle(tip,5,Color("f1dfb1",0.75))
 var tool_icon = icon_id(str(pending.tool))
 if asset_textures.has(tool_icon):
  var texture: Texture2D = asset_textures[tool_icon]
  draw_texture(texture,tip-texture.get_size()*0.5)
func draw_lia(pos: Vector2) -> void:
 draw_set_transform(-camera_origin+pos,0.0,Vector2.ONE*ACTOR_SCALE)
 draw_lia_unscaled(Vector2.ZERO)
 draw_set_transform(-camera_origin)

func draw_lia_unscaled(pos: Vector2) -> void:
 if draw_actor_sheet("actors/actor_lia",pos,Vector2i.RIGHT if lia_leaving else Vector2i.LEFT,lia_arriving or lia_leaving): return
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

func house_count() -> int:
 var n := 0
 for id in s.repairs: if s.repairs[id].completed: n += 1
 for id in s.dirt: if s.dirt[id]: n += 1
 for id in s.condemned: if s.condemned[id] <= 0: n += 1
 return n

func shipment_value() -> int:
 var value := 0
 for item in s.shipment: value += int(s.shipment[item])*int(PRICES.get(item,0))
 return value
func short_name(id: String) -> String:
 var names = {"TOOL_AXE":"Mach.","TOOL_PICK":"Pic.","TOOL_HOE":"Enx.","TOOL_SCYTHE":"Foice","TOOL_WATER":"Água","TOOL_HAMMER":"Mart.","SEED_CORN":"Milho","HAND":"Mão","coffee":"Café","bar":"Barra","fruit":"Umbu","wood":"Mad.","stone":"Ped.","fiber":"Fibra","scrap":"Suc.","waste":"Res.","corn":"Milho","bench":"Banco"}
 return str(names.get(id,"Item"))

func format_items(items: Dictionary) -> String:
 var names = {"wood":"Madeira","stone":"Pedra","fiber":"Fibra","scrap":"Sucata","waste":"Resíduo","corn":"Milho","coffee":"Café","bar":"Barra","fruit":"Umbu","bench":"Banco"}
 var parts: Array[String] = []
 for id in items:
  if int(items[id]) > 0: parts.append("%s %d" % [names.get(id,"Item"),int(items[id])])
 return " • ".join(parts) if not parts.is_empty() else "vazio"

func icon_id(id: String) -> String:
 var names = {"TOOL_AXE":"axe","TOOL_PICK":"pick","TOOL_HOE":"hoe","TOOL_SCYTHE":"scythe","TOOL_WATER":"water","TOOL_HAMMER":"hammer","SEED_CORN":"corn_seed","HAND":"valid","wood":"wood","stone":"stone","fiber":"fiber","scrap":"scrap","waste":"trash","corn":"corn","coffee":"coffee","bar":"bar","fruit":"fruit"}
 return "icons/"+str(names.get(id,"valid"))
func world_label(t: String,p: Vector2,size: int = 14,c: Color = Color("243348")) -> void:
 draw_string(font,p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)

func draw_city() -> void:
 var first = Vector2i(floori(camera_origin.x/TILE),floori(camera_origin.y/TILE))
 for y in range(maxi(CITY_MAP.BOUNDS.position.y,first.y),mini(CITY_MAP.BOUNDS.end.y,first.y+13)):
  for x in range(maxi(0,first.x),mini(CITY_MAP.BOUNDS.end.x,first.x+21)):
   var p = Vector2i(x,y)
   var id = city_map.ground_asset_id(p,farm_sand_id(p))
   asset(id,Vector2(p)*TILE+Vector2(16,32))
   if not city_map.is_path(p) and not city_map.is_river(p) and not city_map.blocked.has(p) and not city_map.near_building(p) and terrain_hash(p)%5 < 2:
    asset("props/grass_clump_%d" % (terrain_hash(p)%6+1),Vector2(p)*TILE+Vector2(16,32))
 asset("city/bridge",Vector2(CITY_MAP.BRIDGE_ANCHOR)*TILE)
 draw_city_objects(true,float(s.position[1])*TILE)

func draw_city_objects(behind_actor: bool,actor_feet_y: float) -> void:
 var objects: Array[Dictionary] = []
 for ob in city_map.props:
  objects.append({"y":(float(ob.at[1])+1.0)*TILE,"prop":ob})
 for b in city_map.buildings+city_map.landmarks:
  objects.append({"y":float(b.at.y)*TILE,"building":b})
 objects.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.y < b.y)
 for ob in objects:
  if (ob.y <= actor_feet_y) != behind_actor: continue
  if ob.has("prop"):
   var pos = Vector2(ob.prop.at[0],ob.prop.at[1])*TILE
   if prop_visible(prop_asset_id(ob.prop),pos): draw_prop(ob.prop,pos)
  else:
   asset(ob.building.id,Vector2(ob.building.at)*TILE)
