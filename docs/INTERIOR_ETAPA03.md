# Boa Sorte — contrato de interior, etapa 03

Escopo desta etapa: enquadramento compacto de HOME01 sobre fundo preto, paredes e duas janelas independentes do reparo H02/H03. A planta segue os conceitos de interior abandonado e restaurado recebidos pelo usuário: cozinha/sala à esquerda, quarto à direita, sofá abaixo da cozinha e entrada no centro da parede inferior. Os conceitos são referência de composição; piso, janelas, móveis, sujidades e condenados continuam instâncias separadas. Este documento fixa a planta para implementação e revisão, sem alegar validação em captura Godot, cuja permissão gráfica foi negada no ambiente.

## Planta congelada

- Grade de 32 px, **17 × 10 tiles** (`x=0..16`, `y=0..9`), tamanho 544 × 320 no canvas lógico 640 × 360. Desenhar em `screen=(48,20)+tile*32`, deixando margens pretas de 48 px à esquerda/direita e 20 px acima/abaixo. A câmera em HOME01 não deve fazer clamp para o tamanho antigo 24 × 18 nem deslocar a casa quando o personagem anda; `screen_tile` e clique do editor usam a mesma origem. O fundo fora do retângulo permanece preto/charcoal escuro uniforme.
- Paredes externas em `x=0`, `x=16`, **duas linhas no norte `y=0..1`**, e `y=9` ao sul, exceto vão de entrada `x=8..9,y=9`. Parede divisória `x=11,y=2..8`, com passagem de **dois tiles** `y=4..5`. Piso caminhável `x=1..15,y=2..8`, menos divisória, móveis e condenados. Sala/cozinha `x=1..10`; quarto `x=12..15`.
- Entrada da fazenda: personagem surge em torno de `(8.5,7.9)` e pode voltar ao exterior a partir de `x=8..9,y=8`, após o cooldown de transição. Acordar perto da cama em `(12.5,5.9)` ou outro tile comprovadamente livre e adjacente, nunca dentro do colchão. A interação de saída não deve disparar involuntariamente ao entrar.
- Janelas no norte: cozinha top-left `(4,0)`, quarto top-left `(13,0)`, cada PNG **64 × 64 px**; antiga pregada/fechada e restaurada aberta. H03 controla as duas janelas simultaneamente, **independente de H02**. Os quatro cruzamentos H02 antigo/novo × H03 antigo/novo devem renderizar corretamente. Parede norte modular `interior/north_wall_old/new`, 32 × 64 px com pivô `[16,64]`, ocupa visualmente e bloqueia **y0..1**. Janelas `interior/window_old/new`, 64 × 64 px, pivô `[32,64]`; ponto de desenho deve produzir exatamente os top-left acima. Renderizar piso/parede, depois janela, depois móveis e atores, para que o balcão não seja substituído por imagem achatada. PNGs RGBA, alpha 0/255, nearest.

| Instância | Tile superior esquerdo | Footprint lógico | Observação |
| --- | ---: | ---: | --- |
| Fogão H06 | `(2,2)` | 1 × 1 | Cozinha esquerda, visual 32 × 48 com pivô na base. |
| Pia H07 | `(4,2)` | 3 × 1 | Abaixo da janela da cozinha; visual 96 × 64 sem compressão vertical. |
| Sofá H05 | `(3,6)` | 3 × 1 | Parte inferior da sala; visual 96 × 64. |
| Cama H04 | `(13,2)` | 2 × 3 | Quarto direito; visual 64 × 96 e faixa acessível em `x=12`. |
| Mesa condenada | `(7,4)` | 2 × 1 | ID `old_table`; colisor e editor devem considerar os dois tiles. |
| Cadeira condenada A | `(6,5)` | 1 × 1 | ID `old_chair_a`. |
| Cadeira condenada B | `(9,4)` | 1 × 1 | ID `old_chair_b`. |
| Armário condenado | `(2,4)` | 1 × 2 | ID `old_cabinet`. |
| Estante condenada | `(9,2)` | 2 × 2 | ID `old_shelf`; não entra na parede divisória. |
| Mesa baixa condenada | `(3,7)` | 2 × 1 | ID `old_low_table`. |
| Guarda-roupa condenado | `(14,7)` | 2 × 2 | ID `old_wardrobe`; ocupa até x15/y8, sem invadir parede x16. |

Os condenados acima usam o **footprint do manifest**, não o colisor de um tile do código antigo. Desenhar seus sprites com o pivô no centro da base do footprint declarado, preservar IDs e estado de demolição, e permitir alvo/interação por qualquer célula ocupada. O banco continua opcional e entra só pelo editor depois da reforma; sua posição inicial `[0,0]` significa “não colocado”.

| Reparo | Ponto de uso | Sujidade independente | Tile |
| --- | ---: | --- | ---: |
| H02 piso/parede | `(4,4)` | `dirt_web` | `(2,3)` |
| H03 janelas | `(12,1)` | `dirt_dust` | `(6,4)` |
| H04 cama | `(13,3)` | `dirt_papers` | `(9,5)` |
| H05 sofá | `(4,6)` | `dirt_rubble` | `(13,6)` |
| H06 fogão | `(2,2)` | `dirt_rug` | `(13,7)` |
| H07 pia | `(5,2)` | `dirt_utensils` | `(5,3)` |

H01 permanece fora da casa. Os seis pontos internos têm ao menos um tile de contato acessível a partir da entrada com os quatro móveis e sete condenados ainda presentes, mesmo com a parede norte ocupando `y0..1` (verificação estática de ocupação: 73 tiles alcançáveis, inclusive 18 no quarto). H03 fica na parede ao lado da janela do quarto e é alcançado pelo piso em `(12,2)`, sem atravessar a cama; ao repará-lo, as duas janelas mudam. Sujidades e condenados continuam removíveis um por vez e estados persistidos. A demolição não apaga móvel preservado, o reparo não remove sujeira e H02 não resolve H03 por acidente.

## HUD e editor dentro da casa

O HUD exterior sobreporia janelas e entrada nesta planta: missão ocupa `x=4..192,y=4..73`, estatísticas `x=421..636,y=4..80` e hotbar `x=126..514,y=307..356`. HOME01 usa modo contextual **sempre utilizável**: faixa preta superior `y=0..19` com dia/hora, moedas, vida e estamina em blocos separados; hotbar de oito ícones vertical em `x=4..44,y=25..304`, dentro da margem preta esquerda; faixa inferior `x=54..635,y=341..359` alterna objetivo e aviso temporário, nunca os dois sobrepostos. Os detalhes ficam no diário. O botão selecionado mantém contorno/foco, número e tooltip, com mouse e teclado. Pausa, modais e editor podem usar painéis maiores; a vista em jogo não deve esconder janela, cama ou saída. Verificar texto/ícones em 100%, 125% e 150% antes de aceitar a composição.

O editor recebe a nova origem de tela e usa os footprints acima. Precisa conservar acesso à entrada, cozinha, passagem `x=11,y=4..5` e lateral da cama. Preview válido/inválido não pisa no HUD lateral. As rotações r0..r3 dos quatro móveis preservados usam sprites do mesmo estilo; o footprint gira, a altura visual pode ultrapassar a célula de colisão e o pivô continua na base.

## Saves antigos 24 × 18

Adicionar versão de layout de HOME01 ao save; um slot sem essa marca é legado 24 × 18 e deve ser migrado **uma vez antes de usar as novas colisões/desenho**. Não rejeitar apenas por manter o schema global 1. Preservar nome, progresso H01–H07, golpes pagos/concluídos, seis sujidades, sete condenados, dia/hora, inventários, stamina, missão e IDs dos móveis. Se o save estiver dentro da casa, mover o personagem para um tile livre perto da entrada ou da cama; migrar drops internos para tiles livres ou armazenamento, sem perda.

Para cada móvel legado colocado, tentar primeiro posição/orientação projetadas para a planta nova e validar footprint, parede, corredor, outros móveis e acesso à cama; em conflito, buscar deterministicamente o tile livre mais próximo. Se não houver lugar, guardar **o próprio móvel recuperável** no armazenamento/editor e informar o jogador, sem descartar nem duplicar. Os quatro móveis originais podem usar posições padrão acima quando o save ainda mantinha o arranjo inicial. Um banco já colocado não deve voltar a `mail.bench` como segundo item. Salvar o resultado com versão nova e fazer reload idempotente; testar tanto slot antigo com móvel rotacionado/banco quanto slot de nova partida.

## Aceite

Uma captura posterior autorizada em 720p e 1080p deve mostrar sala/cozinha esquerda, quarto direita, paredes com duas janelas e piso compacto inteiro com preto ao redor, sem HUD sobre janela/entrada e sem cortar mobiliário alto. Reparar H02 e H03 em ordens diferentes deve alterar apenas seus componentes; H04–H07 conservam os móveis. O personagem alcança todos os consertos, seis sujeiras e sete condenados, entra/sai, usa o editor, dorme e acorda sem ficar preso. Save/reload mantém mudanças e migra slot 24 × 18 sem perder móvel. Até captura e interação reais, o aceite é estrutural/provisório.
