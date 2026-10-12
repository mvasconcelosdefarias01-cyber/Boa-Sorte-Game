# Boa Sorte — correspondência dos PNGs originais para o cenário 01

Fontes: `/workspace/shared/visual_revision/Arquivos-para-o-jogo/` (24 PNGs) e GDD/direção de arte em `/workspace/shared/boa_sorte_references/`. Este inventário trata os PNGs como **referências de produção**; seus nomes e ilustrações não são instruções de implementação. Como o North Asset Forge 2D não está montado, o usuário autorizou a produção no repositório `/workspace/Boa-Sorte-Game/assets`. A amostra exportada ainda é **protótipo derivado de referências**, sem aprovação como arte final.

## Contrato de exportação para Godot

- Grade FARM01/HOME01 de 32 × 32 px; personagens 32 × 64 px por frame, pivô estável nos pés [16, 63]; ícones 24 × 24 px; nearest e escala inteira. PNG RGBA com fundo alpha 0 e pixels sólidos alpha 255. Verificar quatro direções pelo **lado para o qual a face aponta na imagem**. A bolsa de Lia fica no quadril esquerdo dela (à direita na vista frontal), com alça cruzada; não espelhar mecanicamente.
- Entregar PNGs modulares e manifest com `id`, `path`, `source`, `state`, `direction`, `frame_size`, `duration`, `pivot`, `footprint`, `collider`, `use_area`, `contact_frame` quando aplicável e hash de fonte/export. O jogo deve importar pelo ID; spritesheets precisam declarar linhas e colunas.
- Layout obrigatório FARM01: casa no alto à direita (x44..55, y7..15, porta em 49,16), ruínas no alto à esquerda, lago embaixo à esquerda e corredores de dois tiles livres. HOME01 mede 24 × 18; sala/cozinha à esquerda e quarto à direita. Renderizar cada objeto pelo seu estado; a reforma H01..H07, sete móveis condenados e seis grupos de sujeira mudam independentemente.
- Prioridade de produção: **1** ator e Lia fiéis (idle/andar para validar proporção/âncora); **2** casa H01 e base modular dos dois mapas; **3** árvores, rochas, madeira, cactos e capim como instâncias; **4** milho, ferramentas, consumíveis e recursos; **5** animações de ação e acabamento. Não usar o conceito de fazenda nem as duas imagens internas como fundos achatados: repetiriam objetos após remoção e impediriam estados parciais.

## Inventário completo e destino

Caminhos abaixo são relativos à pasta `Arquivos-para-o-jogo/`. `FARM01` = exterior; `HOME01` = interior. IDs efetivamente exportados constam em `Boa-Sorte-Game/assets/manifest.json`.

| PNG original | Uso/IDs de exportação | Cena e preparação |
|---|---|---|
| `Actors/PERSONAGEM PRINCIPAL/Jovem fazendeiro pixel art.png` | `actor_player` frente (`down`) | FARM01/HOME01; identidade de chapéu, cabelo, camisa terracota, jeans, cinto e botas; normalizar para frame 32 × 64. |
| `Actors/PERSONAGEM PRINCIPAL/Rancheiro de costas em pixel art.png` | `actor_player` costas (`up`) | FARM01/HOME01; alinhar pés e escala do chapéu; retirar ponto isolado inferior se presente. |
| `Actors/PERSONAGEM PRINCIPAL/Jovem rancheiro em pixel art.png` | `actor_player` perfil que olha para **direita** (`right`) | FARM01/HOME01; recortar vista própria; conferir pivô com frente/costas. |
| `Actors/PERSONAGEM PRINCIPAL/Rancheiro pixelado em perfil lateral.png` | `actor_player` perfil que olha para **esquerda** (`left`) | FARM01/HOME01; recortar vista própria, sem inverter automaticamente a direita. |
| `Actors/LIA - CARTEIRA/Mensageira rural de amarelo e azul.png` | `actor_lia` frente (`down`), retrato neutro | Abertura FARM01 e UI de diálogo; amarelo/azul e bolsa postal coerentes. |
| `Actors/LIA - CARTEIRA/Entregadora postal em vista traseira.png` | `actor_lia` costas (`up`) | Rota roteirizada da abertura; preservar alça e bolsa anatômicas. |
| `Actors/LIA - CARTEIRA/Carteira postal pixelada em perfil esquerdo.png` | `actor_lia` perfil que olha para **esquerda** (`left`) | Entrada/saída; perfil próprio e continuidade da bolsa. |
| `Actors/LIA - CARTEIRA/Carteira postal em perfil, à direita.png` | `actor_lia` perfil que olha para **direita** (`right`) | Entrada/saída; perfil próprio e continuidade da bolsa. |
| `Casa da fazenda/Abandonada/Casa rural abandonada em pixel art.png` | `house_H01_old`, partes de telhado/fachada/porta/janela antiga | FARM01, x44..55 y7..15; retirar fundo/folhagem como objetos separados; porta no 49,16. |
| `Casa da fazenda/Reformada/Casa rural restaurada em pixel art.png` | `house_H01_restored`, telha/fachada/porta/janela íntegra | FARM01; mesmo footprint/pivô da casa antiga; H01 muda exterior, H03 janelas permanecem um estado independente. |
| `Construção em ruinas/Ruína de pedra sem teto.png` | `prop_ruin` modular | FARM01 x8..17 y8..15; ruína inspecionável, sem reconstrução; separar detritos vegetais e muros se colidirem. |
| `Arvores/Árvores da Caatinga_ quatro estágios e tocos.png` | `object_tree_{umbu,juazeiro,catingueira,jurema}_stage{1..4}` e `_stump` | FARM01; 4 linhas visuais × 4 fases + toco. Margens e halos impedem slicing regular ingênuo. Associação de espécie por linha requer conferência de direção de arte; separar tronco/copa e collider de tronco. |
| `CAPIM/Seis tufos de grama rasteira.png` | `ground_grass_clump_01..06` | FARM01; seis variantes dispersas, sem colisão de bloqueio, sem repetir padrão uniforme. |
| `Cactos/Cactos mandacaru e palma em pixel art.png` | `prop_mandacaru_{1..3}`, `prop_palma_{1..3}` | FARM01; topo vertical ramificado e linha inferior de palma alastrada; distinguir footprint/colisão e não infligir dano por proximidade. |
| `Madeira/Quatro sprites de madeira caída.png` | `prop_stick_01..02`, `prop_log_01..02` | FARM01; objetos cortáveis independentes, danos/drops em dados; não colar ao chão. |
| `Pedras/Rochas pixeladas em três estados de dano.png` | `prop_rock_{small,medium,large}_{intact,cracked,broken}` | FARM01; linhas pequena/média/grande, colunas íntegras/rachadas/quebradas; footprint e colisão por tamanho. |
| `Milho/Sete sprites de milho em pixel art.png` | `crop_corn_stage1..5`, `item_seed_corn`, `item_corn` | FARM01/horta e UI; cinco fases + dois ícones conforme leitura visual. Separar solo seco/arado/úmido do milho; GDD exige 20 posições plantadas/regadas. |
| `Ferramentas/Seis ferramentas rurais em pixel art.png` | `TOOL_HOE`, `TOOL_WATER`, `TOOL_PICK`, `TOOL_AXE`, `TOOL_SCYTHE`, `TOOL_HAMMER` | Hotbar e overlays de ação; disposição 3 × 2 lida visualmente (enxada/regador/picareta em cima; machado/foice/martelo embaixo); respeitar frame de contato. |
| `Elementos/Cinco recursos da fazenda em pixel art.png` | `item_wood`, `item_stone`, `item_fiber`, `item_waste`, `item_scrap` | Drops/inventário/venda; imagens de madeira, pedra, fibra, resíduos e sucata em 3 + 2; contadores não devem se confundir. |
| `Umbu e barra de cereal/Umbu e barra de cereal.png` | `item_fruit_umbu`, `item_cereal_bar` | Consumo/UI; apenas alimento restaura estamina, inclusive após dormir. |
| `Café/Trio de café em pixel art.png` | `item_coffee_bean`, `item_coffee_pack`, `item_coffee_cup` | UI e consumo; usar xícara como ícone inequívoco do café consumível; pacote/grão só se houver função de dados. |
| `CENÁRIO DA FAZENDA CONCEITO/Fazenda abandonada em pixel art.png` | **Referência de composição**, sem export de fundo | FARM01: casa direita, ruínas esquerda, lago inferior esquerdo, vegetação irregular. É RGB achatado; converter terreno e objetos em camadas/instâncias, preservar rotas. |
| `CENÁRIO INTERNO CASA/ABANDONADA/Interior de fazenda abandonada em pixel art.png` | **Referência de estado inicial**, sem export de fundo | HOME01: base de piso/paredes e instâncias individuais de 6 sujeiras, 7 móveis condenados e 4 preservados quebrados. |
| `CENÁRIO INTERNO CASA/REFORMADA/Casa rural restaurada, pronta para jogar.png` | **Referência de resultado**, sem export de fundo | HOME01: piso H02, janelas H03 e cama/sofá/fogão/pia H04..H07 íntegros; não recolocar automaticamente os 7 móveis condenados. |

## Observações de formato e fidelidade

Os 8 PNGs de personagens medem 1024 × 1536. Os conceitos de fazenda e interior são RGB 1448 × 1086, sem alpha. Os demais PNGs são RGBA grandes, contendo uma ou várias ilustrações; muitos têm pixels parcialmente transparentes. Os originais permanecem intactos. As fontes ImageGen da amostra estão preservadas em `assets/sources/imagegen/`, excluídas da importação pelo `assets/sources/.gdignore`; os importadores `assets/import_*_slice.py` registram hashes de origem e de exportação no manifest.

## Entrega efetiva da amostra

| Referências originais | Export no Boa-Sorte-Game | Estado e limite |
|---|---|---|
| Oito vistas do fazendeiro e Lia | `assets/sprites/actors/actor_player.png`, `actor_lia.png` | `prototype_reference_derived`; atlas 64×256, linhas baixo/esquerda/direita/cima, 2 frames por direção, pivô [16,63]. Ainda faltam os 6 frames de caminhada do GDD e teste visual em movimento. |
| Casa externa abandonada/restaurada e folhas de janelas | `assets/sprites/buildings/house_H01_old.png`, `house_H01_restored.png`, `repair_H03_window_boarded.png`, `repair_H03_window_open.png` | `prototype_reference_derived`; H01 384×288, porta em [176,288] alinhada ao tile (49,16); H03 overlay único 64×64 ancorado em (53,14). Silhueta/alpha e combinações H01×H03 revisadas estaticamente. |
| Interior antigo/restaurado | `assets/sprites/ground/floor_{old,new}.png`, `wall_{old,new}.png`; `assets/sprites/furniture/{bed,sofa,stove,sink}_{broken,intact}.png` e `_intact_r0..r3` | Tiles 32×32 e móveis independentes por estado. Sofá/pia 96×64 sobre footprint 3×1; arte sobe além da colisão. Rotações r1..r3 são aproximações técnicas provisórias da arte nova. Piso/parede antigos repetem rachaduras e pedem variantes de acabamento. |
| Seis ferramentas | `assets/sprites/icons/{hoe,water,pick,axe,scythe,hammer}.png` | `prototype_reference_derived`, 24×24, folha original 3×2. |

Os outros sprites ainda são protótipos geométricos anteriores. Sheets de ações `actors/action_*`, `actors/action_eat` e `actors/lia_talk/give` não foram refeitas; o código mantém o corpo novo e aplica overlay provisório nas ações. A vegetação, recursos, sujeiras, objetos externos e HUD ainda precisam de revisão gráfica fiel às 24 referências. `python3 assets/validate_assets.py` verificou 135 PNGs, alpha binário, dimensões/metadados e 10 WAVs. A importação no editor Godot foi feita em modo headless; a aprovação visual em execução está pendente porque a abertura gráfica foi negada no ambiente.
