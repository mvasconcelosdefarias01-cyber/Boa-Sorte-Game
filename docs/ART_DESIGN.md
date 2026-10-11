# Boa Sorte — direção de experiência e arte, cenário 01

Este guia cruza integralmente o GDD e a direção de arte entregues com as onze imagens incorporadas. É um contrato de colaboração para o protótipo jogável. Os documentos definem o comportamento e a intenção do jogo; as imagens são referências de composição e identidade, não mapas ou spritesheets de produção. A imagem exterior enviada novamente pelo usuário confirma a imagem 1 como referência explícita prioritária para distribuição e identidade. A programação permanece no projeto Godot 2D. O repositório North Asset Forge 2D não está presente; com autorização posterior do usuário, o agente de arte trabalha exclusivamente em `Boa-Sorte-Game/assets` neste protótipo, mantendo manifest e origem identificados. Nenhum arquivo de referência deve ser sobrescrito.

## Experiência a entregar

O jogador chega pela estrada a leste da casa do avô Olegário, escolhe apenas o nome, encontra Lia, lê a carta do prefeito Jair e recebe ferramentas, materiais, sementes e comida uma única vez. Lia sai pela mesma estrada e só então o jogador assume o controle. O ciclo apresenta um objetivo visível de três partes: casa, 20 milhos plantados e regados, sono. A casa se transforma gradualmente por sete reparos, sete demolições e seis limpezas. O encerramento mostra o milho em broto e a casa habitável ao amanhecer, sem abrir cidade ou criar missão nova. Após o marco, o cenário continua jogável.

A emoção central é passar de abandono para cuidado por ações pequenas que tenham efeito visível. Cada golpe válido precisa mostrar alvo, contato, mudança de estado, consumo e recompensa na mesma ação. A vida nunca vira perigo artificial: neste cenário não há combate nem dano ambiental. A estamina só volta por alimento, inclusive depois de dormir, subir de nível ou trocar de mapa. A cesta de umbus junto ao correio oferece a rota de recuperação quando o jogador se esgota.

O tutorial é contextual e não impõe ordem entre reforma e milho: movimento e seleção após a saída de Lia; estoque e martelo ao chegar à casa; foice no primeiro arbusto; enxada, semente e regador na horta; lago apenas quando a água faltar; comida ao cansar; cama quando casa e milho estiverem prontos. O objetivo antes das 18h é motivação narrativa, não falha. Mensagens de erro nomeiam ferramenta ou bloqueio e não gastam estamina.

## Requisitos definidos e parâmetros de protótipo

| Tema | Requisito definido | Parâmetro inicial, sujeito a teste humano |
| --- | --- | --- |
| Escopo | FARM01 e HOME01; Lia apenas na abertura; cidade, prefeito presencial, novas construções e ruínas reconstruídas ficam para depois. | Fazenda 64×48 tiles; interior 24×18; tile de 32×32. |
| Movimento | Oito vetores, aparência em quatro direções; alvo cardinal adjacente; ferramenta errada ou ação impossível não cobram. | 120 px/s; duração de 0,55–0,70 s por ferramenta; antecipação até 0,10 s; uma entrada em buffer. |
| Recursos | Seis ferramentas; madeira, pedra, fibra, sucata e resíduo distintos; kit da reforma reservado. | Estamina inicial 100; mochila 24 slots, peso confortável 40; regador 20 cargas. |
| Tempo | Relógio só avança em PLAY; sono nunca restaura estamina; dia termina à meia-noite. | 10 min de jogo por 20 s ativos; abertura às 08h, manhã seguinte às 06h. |
| Missão | H01–H07, sete móveis condenados e seis grupos de sujeira; 20 tiles distintos plantados e regados; noite válida e despertar. | Prazo narrativo de 18h; sessão pretendida 20–35 min, a aferir com jogadores. |
| Arte | Pixel nítido, vista superior com fachadas, atores fiéis às quatro vistas, restauração por objetos independentes. | Canvas 640×360, personagem 32×64, ícone 24×24; cores do documento são guia, não amostras literais. |

O GDD fixa quantidades, custos, roteiro da abertura, árvore de estados, estoque inicial, regras de venda e persistência. Valores de velocidade, duração, luminosidade e densidade decorativa são balanceamento e acabamento; só mudam após teste sem alterar o ciclo da missão. O orçamento da reforma é exato: madeira 20, pedra 12, fibra 3 e sucata 3. Não obrigar coleta para reparar. O esforço obrigatório de referência é 192 de estamina, com alimentos iniciais e fruta de apoio suficientes.

## Fluxo de telas e leitura

1. **Título e criação:** continuar ou escolher um dos três slots, nova partida, opções; nome de 2–20 caracteres com acentos; preview do protagonista. Foco claro e retorno sem perder o nome digitado.
2. **Chegada, diálogo e carta:** câmera mostra a estrada e a casa; Lia é identificável pelo amarelo e azul. Carta como documento legível com assinatura de Jair. Avançar ou pular confirma uma única entrega e a saída dela. Relógio parado.
3. **Exploração:** relógio e moedas no alto à direita; vida e estamina sempre visíveis; missão recolhível no alto à esquerda; oito atalhos embaixo; peso numérico junto à mochila. Cursor mostra tile adjacente, ferramenta e validade. Para erros, combinar símbolo, texto curto e som leve, nunca cor isolada.
4. **Interior e reparo:** transição curta; interior abandonado com passagens abertas. Ao apontar martelo, mostrar H01–H07, saldo reservado, golpes restantes e confirmação. Cada serviço muda só seu conjunto visual e colisão. Diário lista serviços, sete demolições e seis limpezas até chegar a 100%.
5. **Cultivo:** horta sugerida 5×4 legível como região; arado seco, arado úmido, semente e broto precisam ter silhuetas distintas. Mostrar `Milho n/20` apenas para tiles iniciais distintos regados ao menos uma vez. Não antecipar vitória ao regar o mesmo tile repetidamente.
6. **Inventário, correio e vendas:** modal único; material reservado e estoque livre separados; carta sempre relível; comida com recuperação efetiva antes de consumir; baú mostra envio e receita prevista, liquidação na manhã. Itens protegidos deixam claro por que não podem ser vendidos.
7. **Editor interno:** lista lateral estreita, preview translúcido na grade e comandos no rodapé. `R` avança orientações permitidas; válido mostra check e texto; inválido explica colisão, área ou acesso. O preview não oculta a cama, entrada ou passagem. Cancelar conserva origem; confirmar move sprite, colisão e ponto de uso juntos.
8. **Noite e conclusão:** resumo de vendas e avanço do cultivo; manhã às 06h. O painel de conclusão aparece uma vez, com casa íntegra e milho em broto. Estamina numérica é idêntica à de antes do sono, salvo alimento consumido antes ou depois.

## Contrato entre arte e gameplay

IDs estáveis são a chave entre manifest de arte, cenas e save. Usar `actor_player`, `actor_lia`, `TOOL_AXE`, `TOOL_PICK`, `TOOL_HOE`, `TOOL_SCYTHE`, `TOOL_WATER`, `TOOL_HAMMER`, `SEED_CORN`, `M01`, `H01`–`H07`, `FARM01`, `HOME01`; exemplos de asset `object_tree_umbu_stage4`, `repair_H04`, `crop_corn_stage1`. Arte não redefine custos ou regras; código não infere footprint ou colisão pela área opaca do PNG.

Cada asset exportado deve registrar `assetId`, `stateId`, `direction`, `frameSize`, `frameCount`, duração ou FPS, pivô, footprint em tiles, colisor no chão, âncora de interação, orientações e frame de contato quando aplicável. O manifest indica nomes reais dos arquivos e cada estado disponível. PNG RGBA com pixels vazios em alpha 0 e sólidos em 255, filtro nearest, escala inteira, sem halo ou pixel isolado. Para os atores, frame 32×64 e pivô nos pés; colisor pequeno na base. Ordenar ator e props pela base, com copa separada quando cobre o jogador. Render de UI usa escala independente.

Prioridade de entrega de arte para a primeira fatia: protagonista e Lia idle/caminhada em quatro direções; poses de machado, picareta, enxada, foice, regador e martelo com contato marcado; casa antiga, H01 e interior modular H02–H07; cama, sofá, fogão e pia quebrados/íntegros; sete móveis condenados e seis sujeiras removíveis; solo normal/arado/úmido, semente/broto; árvores, arbustos, pedras e madeira com ao menos um estado de dano; ícones das seis ferramentas, semente, água, estamina, itens, pesos e feedback. Completar variantes restantes e animações antes do aceite final. Enquanto o North Asset Forge 2D estiver ausente, a arte feita em `Boa-Sorte-Game/assets` é uma entrega local autorizada e precisa ser identificada como tal no manifest.

Casa 100% é composição, não uma única troca de fundo: `H01` fachada e telhado; `H02` piso e paredes; `H03` janelas; `H04` cama; `H05` sofá; `H06` fogão; `H07` pia com bancada. Os sete móveis condenados desaparecem um a um; os seis grupos de sujeira também. A cama e os três outros móveis preservados não aceitam machado. Ícones de inventário, sprites no mundo, colisão e diário devem refletir o mesmo estado no mesmo frame de conclusão.

Móveis íntegros: cama 2×3, sofá 3×1, fogão 1×1, pia 3×1 e banco 1×1, quatro orientações desenhadas e não apenas PNG girado; para orientação lateral, footprint gira com o móvel. O ponto de uso acompanha a rotação. Fogão e pia só na área de cozinha; entrada, corredor para o quarto, cama e cozinha continuam acessíveis. O banco fica na encomenda até a casa pronta.

## Critérios visuais extraídos das onze imagens

| Imagens | Leitura visual obrigatória | Adaptação para o jogo |
| --- | --- | --- |
| 1 | Casa de telha cerâmica no alto à direita; ruína alta à esquerda; lago embaixo à esquerda; árvores e cactos em grupos; correio e baú distintos. | Recriar peças interativas em grade 64×48, preservar corredor de dois tiles para porta, correio, horta e lago. Não usar a imagem inteira como fundo jogável. |
| 2 e 3 | Mesmo interior antes/depois: sala e cozinha à esquerda, quarto à direita, entrada embaixo. Cama, sofá, fogão e pia permanecem; mesa, cadeiras, estante, armários soltos e sujeira somem. | Implementar camadas e objetos independentes. A composição restaurada tem espaço livre para editor, sem adicionar móveis condenados de volta. |
| 4–7 | Protagonista de chapéu de palha com faixa marrom, cabelo castanho, camisa terracota, jeans, cinto e botas. 4 frente, 5 costas, 6 esquerda, 7 direita. | Redesenhar em 32×64 sem suavização; alinhar pés e volume do chapéu entre direções; retirar halo e ponto claro sob a imagem 5. |
| 8–11 | Lia com boné e camisa amarelos de detalhe azul, calça e bolsa azuis, cabelo castanho preso. 8 frente, 9 costas, 10 esquerda, 11 direita. | Preservar alça e bolsa do mesmo lado anatômico ao virar; não espelhar perfis mecanicamente; retirar halos; retratos e animações mantêm a identidade. |

Paleta guia: areia `#DFAE55`, terra `#A36C3B`, terracota `#B85D43`, reboco `#F1DFB1`, madeira `#70482F`, folhas `#4F7838`/`#245E46`, água `#287FBD`, contorno `#243348`. Protagonista usa camisa próxima de `#B9624C` e jeans `#304868`; Lia usa amarelo `#E6B539` e azul `#294F8F`. Usar 3–5 tons por material. Vegetação do agreste e da Caatinga: umbuzeiro arredondado, juazeiro compacto, catingueira leve, jurema irregular; mandacaru vertical e palma baixa, sem saguaro. A noite reduz luminosidade moderadamente e mantém alvo, caminho e itens legíveis.

O inventário final deve contemplar quatro estilos de árvore em quatro estágios e toco, arbustos, dois cactos, três tamanhos de pedra e estados, madeira, lixo, lago modular, ruína sem reparo, caixa postal, baú, quatro estágios posteriores do milho, cinco móveis íntegros em quatro orientações, retratos, UI, partículas curtas e áudio distinto por ferramenta. As onze imagens são referências de aparência e densidade, não exports aptos a nearest na resolução alvo.

## Resposta de ações e revisão em execução

Machado: arco e contato seco, árvore treme ou madeira perde integridade. Picareta: contato metálico, rachadura e fragmentos curtos. Foice: varredura, folhas e ícone de fibra. Enxada: sulco no tile do contato. Semente: gesto curto e marca de planta. Regador: arco curto, terra escurece, carga decrementa. Martelo: impacto, progresso do serviço e troca visual ao concluir. Mão livre: coleta e limpeza distinguíveis; comida mostra gesto e ganho real. Drops se atraem até 24 px quando cabem e mostram ícone/quantidade agrupados sem cobrir estamina. Som comunica material, mas informação também aparece em texto e imagem. Feedback de falha tem cooldown para não piscar a cada frame.

Ao revisar em jogo, observar em 720p e 1080p, com UI normal e ampliada: ator em relação à porta, pivô estável nas quatro direções, contato no tile adjacente sem atravessar cabeça, visor de alvo legível sobre solo quente, HUD claro na noite, casa mudando grupo a grupo, cadeiras/sujeira desaparecendo uma vez, milho e umidade distinguíveis, Lia realmente saindo a leste e não retornando após carga, editor preservando acesso à cama e cozinha. Verificar também em escala de cinza; estado válido/inválido tem símbolo e motivo além de cor. A revisão visual deve ocorrer em execução, pois arquivo isolado não demonstra ordenação, pivô ou colisão corretos.

## Lacunas e decisões de implementação registradas

| Ponto | Decisão para o protótipo | Motivo ou validação ainda aberta |
| --- | --- | --- |
| Imagens ampliadas não são sheets exportadas | Usar como modelo de formas e cores; reconstruir em escala comum e acompanhar por manifest. | Pixel irregular e halo nas vistas tornam redução direta inadequada. |
| Nome escolhido sem personalização corporal | Um único sprite do protagonista nas quatro direções e nome somente em texto. | O GDD explicitamente limita criação ao nome. |
| Planta antes ou depois da rega | Preservar `wateredDayId` ao semear sobre solo úmido; contar tile apenas depois de semente inicial + primeira rega no dia. | Mantém os dois caminhos equivalentes descritos no GDD. |
| Dormir antes de terminar | Permitir com H04 pronto; se meia-noite chegar sem cama, repouso narrado na varanda. Estamina persiste. | Evita bloqueio e preserva regra de recuperação apenas por comida. |
| Estamina zero e fruta de segurança | Movimento e correio continuam acessíveis; fruta gratuita elegível é retirável sem custo de ação. | Sem isso, o próprio tutorial poderia bloquear a missão. |
| Banco de teste | Surge apenas na encomenda após casa pronta e usa o mesmo editor dos quatro móveis preservados. | Testa colocação sem acrescentar sistema de fabricação. |
| Corredor de Lia e horta | Congelar ocupação da estrada a leste e de corredores de dois tiles; quatro arbustos, dois gravetos e duas pedras bloqueiam a horta 5×4, já inclusos nos totais. | Garante abertura e trabalho legível, sem retirar densidade regional fora das rotas. |
| Aparência exata, duração de efeitos, dificuldade percebida | Ajustar somente após rodada de teste com pelo menos cinco pessoas novas. | O GDD marca valores e duração de sessão como base; nenhum teste humano consta ainda. |

Pergunta material ainda em aberto: localização/acesso ao repositório **North Asset Forge 2D** para manter nele a produção futura. A autorização de produzir arte em `Boa-Sorte-Game/assets` resolve o protótipo atual, mas não cria o segundo repositório nem valida um pipeline de exportação próprio dele. Não há ambiguidade narrativa que exija mudar a intenção do cenário 01.
