# Ajustes incrementais após teste do jogador

Elementos aprovados: protagonista, Lia, seis ferramentas, móveis preservados e casas externas abandonada/restaurada. Seus sprites permanecem preservados.

| Etapa | Entrega | Estado |
| --- | --- | --- |
| 1 | Ícones de itens na mochila, quantidades/seleção e imagens dos recursos coletáveis | Aprovada pelo jogador |
| 2 | Fases visuais do milho e ruína oeste do ZIP | Aprovada pelo jogador |
| 3 | Interior mais compacto, margem preta, paredes e janelas elevadas | Aprovada pelo jogador |
| 4 | Pedras, madeira, cactos, árvores, arbustos, capim e terreno coerentes | Implementada; aguardando teste no Windows |
| 5 | Lago irregular com bordas, transição para solo e vegetação marginal | Pendente |

A ordem prioriza substituições locais antes de geometria, colisões e composição de mapas. Cada etapa gera um ZIP Windows independente para teste antes da próxima. O ZIP reenviado é idêntico ao anterior (24 PNGs); as fontes já extraídas foram reutilizadas após comparação SHA-256. As capturas fornecidas mostram mochila textual sem imagens, milho/vegetação simplificados, ruína pequena, lago retangular e interior com janelas no chão.

Na etapa 1, os saves e as regras de gameplay permanecem compatíveis. Estamina recupera somente por alimentos. A aprovação visual ocorre com o teste do jogador: a execução gráfica na nuvem foi recusada anteriormente pelo controle de permissões; verificações headless não substituem essa aprovação.

## Entrega da etapa 1

Pacote: `dist/BoaSorte-Etapa01-Windows11.zip` (executável com dados incorporados). Dez ícones derivados de quatro folhas originais, com fontes e recortes em `assets/manifest.json`; sementes e espigas distintas. Mochila com imagens, quantidades, seleção e detalhes por mouse/teclado; recursos no chão, resíduos e sucata usam seus ícones.

Validados: importação; 136 PNGs e 10 WAVs; gameplay/save; fluxo e eventos de UI; layouts em 100/125/150%; carregamento das cenas e assets do pacote exportado. Os hashes dos personagens, ferramentas, móveis e casas aprovados permanecem iguais. Execução gráfica/Windows e aprovação visual continuam pendentes. Interior, milho em crescimento, ruína, terreno, vegetação e lago seguem para as etapas seguintes.

## Etapa 2

Etapa 1 aprovada pelo jogador. Escopo seguinte: substituir somente as cinco fases visuais do milho e a ruína oeste pelas referências fornecidas. Preservar IDs, crescimento condicionado à rega, colheita, saves e estamina. Demais ajustes permanecem para as próximas entregas.

Entrega: `dist/BoaSorte-Etapa02-Windows11.zip`. Cinco fases recortadas da folha original, ruína sem halo e com interior transparente, dimensão 320×256 para a área reservada de 10×8 tiles. Milho alto ordenado por linha e profundidade relativa ao jogador. Correspondências e hashes no manifest; reprodução por `assets/import_corn_ruin.py`.

Validados: importação Godot 4.6.3, 136 PNGs/10 WAVs, ciclo lógico até manhã seguinte, save/reload, carregamento do pacote exportado e integridade ZIP. Todos os sprites fora de milho/ruína mantêm os hashes anteriores. Apresentação em execução no Windows permanece para teste do jogador.

## Entrega da etapa 3

Interior HOME01 reduzido de 24×18 para 17×10 tiles, centralizado sobre fundo preto. Cozinha/sala à esquerda, quarto à direita e porta inferior; duas janelas na parede norte de dois tiles de altura. H02 e H03 continuam independentes. HUD interno nas margens; móveis aprovados mantêm suas imagens. Contrato detalhado em `docs/INTERIOR_ETAPA03.md`.

Saves anteriores recebem versão de layout e adaptação de posições; móveis e drops são preservados, buscando posições livres e acesso à cama. Quando necessário, o móvel fica disponível para recolocação no editor (banco no correio). Estamina continua recuperando somente por alimentos.

Pacote: `dist/BoaSorte-Etapa03-Windows11.zip`. Verificados por testes: ciclo de reforma/cultivo/sono, migração de save real da etapa 2, cama girada, banco sem duplicação, recursos no chão, caminhos aos reparos e ao quarto, entrada/saída e despertar sem recuperar estamina, UI e layouts em 100/125/150%, carregamento de 140 PNGs e 10 WAVs. Apresentação em execução no Windows permanece para teste do jogador.

## Entrega da etapa 4

FARM01 recebe quatro espécies de árvores em quatro fases e tocos, pedras intactas/rachadas/fragmentadas, cactos, gravetos, troncos, arbustos e seis tufos de capim derivados das referências. A areia seca tem variações discretas e distribuição determinística de capim; os objetos removíveis continuam separados do terreno. O lago permanece para a etapa 5.

A altura das árvores adultas foi ajustada usando canvas de 144×144 para conservar a proporção original e presença ao lado do protagonista; o tronco mantém colisão de um tile. Fragmentos de pedra são efeito curto do golpe final. IDs, posições, golpes, recursos e saves continuam com as regras anteriores. Contrato/fonte dos recortes em `docs/EXTERIOR_ETAPA04.md` e manifest.

Pacote: `dist/BoaSorte-Etapa04-Windows11.zip`. Passaram: validação de 160 PNGs e 10 WAVs, ciclo completo de gameplay/save, teste específico de variantes/ferramentas/dano de pedras, regressão do interior e carregamento do pacote exportado. A prancha estática em escala 1× foi revisada após corrigir bordas da areia e recortes vizinhos do capim. Arte aprovada e lago mantêm os hashes anteriores. Oclusão das copas, leitura das palmas e terreno em movimento no Windows precisam do teste do jogador.
