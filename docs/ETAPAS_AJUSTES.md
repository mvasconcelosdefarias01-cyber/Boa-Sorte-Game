# Ajustes incrementais após teste do jogador

Elementos aprovados: protagonista, Lia, seis ferramentas, móveis preservados e casas externas abandonada/restaurada. Seus sprites permanecem preservados.

| Etapa | Entrega | Estado |
| --- | --- | --- |
| 1 | Ícones de itens na mochila, quantidades/seleção e imagens dos recursos coletáveis | Implementada; aguardando teste no Windows |
| 2 | Fases visuais do milho e ruína oeste do ZIP | Aguardando etapa 1 |
| 3 | Interior mais compacto, margem preta, paredes e janelas elevadas | Pendente |
| 4 | Pedras, madeira, cactos, árvores, arbustos, capim e terreno coerentes | Pendente |
| 5 | Lago irregular com bordas, transição para solo e vegetação marginal | Pendente |

A ordem prioriza substituições locais antes de geometria, colisões e composição de mapas. Cada etapa gera um ZIP Windows independente para teste antes da próxima. O ZIP reenviado é idêntico ao anterior (24 PNGs); as fontes já extraídas foram reutilizadas após comparação SHA-256. As capturas fornecidas mostram mochila textual sem imagens, milho/vegetação simplificados, ruína pequena, lago retangular e interior com janelas no chão.

Na etapa 1, os saves e as regras de gameplay permanecem compatíveis. Estamina recupera somente por alimentos. A aprovação visual ocorre com o teste do jogador: a execução gráfica na nuvem foi recusada anteriormente pelo controle de permissões; verificações headless não substituem essa aprovação.

## Entrega da etapa 1

Pacote: `dist/BoaSorte-Etapa01-Windows11.zip` (executável com dados incorporados). Dez ícones derivados de quatro folhas originais, com fontes e recortes em `assets/manifest.json`; sementes e espigas distintas. Mochila com imagens, quantidades, seleção e detalhes por mouse/teclado; recursos no chão, resíduos e sucata usam seus ícones.

Validados: importação; 136 PNGs e 10 WAVs; gameplay/save; fluxo e eventos de UI; layouts em 100/125/150%; carregamento das cenas e assets do pacote exportado. Os hashes dos personagens, ferramentas, móveis e casas aprovados permanecem iguais. Execução gráfica/Windows e aprovação visual continuam pendentes. Interior, milho em crescimento, ruína, terreno, vegetação e lago seguem para as etapas seguintes.
