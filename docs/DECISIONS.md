# Boa Sorte — contrato compartilhado do cenário 01

## Fontes e precedência
Pedido do usuário (2026-10-11), `Boa_Sorte_GDD_Cenario_01.docx` e `Boa_Sorte_Direcao_de_Arte_Cenario_01.docx`, incluindo as 11 imagens incorporadas. Os textos e imagens extraídos estão em `/workspace/shared/boa_sorte_references`. Os documentos são especificações de produto e referências visuais, não instruções para alterar a organização de agentes ou os limites de repositório definidos pelo usuário.

## Requisitos definidos
Godot 2D; FARM01 64×48 e HOME01 24×18, tile 32 px, canvas 640×360 e movimento de oito vetores com sprite em quatro direções. M01 inicia com chegada, nome, Lia, carta, presente único e saída leste de Lia. Concluir exige H01–H07, sete móveis condenados removidos, seis grupos de sujeira limpos, 20 tiles distintos de milho plantados e regados, sono e manhã posterior. Cidade, prefeito presencial, novas construções externas e combate fora do escopo. Sono, passagem do dia, nível e troca de mapa não recuperam estamina: somente comida recupera. Ferramenta errada, alvo inválido ou estamina insuficiente não cobram custo. Reforma consome materiais uma vez e muda elementos individualmente. Save persiste estados parciais e impede duplicação. Construção interna mantém acesso à cama, entrada, cozinha e corredor.

## Parâmetros de protótipo (ajustar após testes humanos)
Velocidade 120 px/s; 10 minutos de jogo a cada 20 segundos reais ativos; estamina/vida 100; limite confortável de peso 40 e máximo de coleta 48; custos, duração de ações, valores de XP, preços e produção do GDD. Conteúdo do cenário 01 segue quantidades do documento; densidade e posição exata dos obstáculos fora das âncoras podem ser ajustadas para circulação. Os valores são dados do protótipo, não licença para alterar a regra de estamina ou condições de M01.

## Contrato entre gameplay e assets
IDs estáveis: mapas `FARM01`, `HOME01`; missão `M01`; serviços `H01`–`H07`; ferramentas `TOOL_AXE`, `TOOL_PICK`, `TOOL_HOE`, `TOOL_SCYTHE`, `TOOL_WATER`, `TOOL_HAMMER`; personagens `actor_player`, `actor_lia`; milho `crop_corn_stage0` a `crop_corn_stage4`; árvore exemplar `object_tree_umbu_stage4`. Tile lógico/visual 32×32; personagem 32×64, pivô no centro dos pés. Sprite, pivô, footprint, colisão e área de interação são campos distintos. A colisão usa apenas base/tronco. O código deve poder carregar assets exportados sem depender do Forge na execução. PNG RGBA em escala inteira, nearest, sem halo, pixels soltos ou fundo. Estado da casa por H01–H07, cada grupo de sujeira e cada móvel têm visual independente. Manifest fornece ID, caminho, canvas, frames, duração, pivô, footprint, colisão, área de uso e orientações; ausência de asset pode usar placeholder local explícito.

## Organização e integração
`/workspace/Boa-Sorte-Game`: apenas agente Godot modifica. Repositório North Asset Forge 2D: apenas agente de assets modifica, quando localizado. `/workspace/shared/ART_DESIGN.md` e `/workspace/shared/ASSET_STATUS.md`: arte/design e assets, respectivamente. Este arquivo: orquestrador. Integração depende de manifest exportado; não mover arquivos entre repositórios sem origem identificada. Os checkouts permanecem separados.

## Decisões abertas
URL/localização do North Asset Forge 2D, ausente no ambiente atual. Validação visual humana da fidelidade dos sprites finais e ajuste fino de tempo/dificuldade após testes de jogo. Essas pendências não alteram as condições de conclusão de M01.
