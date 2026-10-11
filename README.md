# Boa Sorte — protótipo do cenário 01

Projeto Godot 4.6.3 2D da Fazenda do Avô Olegário. Abra `project.godot` no Godot e execute a cena principal (F6/F5), ou rode:

As decisões de implementação, a direção visual, o contrato dos assets e o plano de validação estão em `docs/`.

```bash
godot --path .
```

Na primeira tela, pressione **N** para começar ou **1–3** para abrir/criar um slot. Digite um nome de 2 a 20 caracteres e pressione Enter. Enter avança as falas de Lia; Esc conclui a apresentação e a entrega. Lia sai à direita antes de liberar o controle.

Durante o jogo: WASD/setas movem; mouse esquerdo usa o item selecionado no tile adjacente (segure para repetir); botão direito ou E interage. 1–8 e roda do mouse mudam a ferramenta. I abre a mochila de 24 espaços (setas escolhem, Enter consome alimentos, 1–8 atribuem o item escolhido aos atalhos); J abre diário e carta; B abre o editor dentro da casa (1–5 escolhem móvel, R gira, clique coloca, Esc cancela). F5 salva, F9 carrega, Esc pausa; O no menu de pausa abre opções de texto, contraste, repetição e volume de efeitos. No correio, 1 retira umbu, 2 compra café e 3 compra barra. Teclas 4–9 guardam um recurso livre por vez na encomenda e Shift+4–9 o retiram; os materiais reservados para a reforma permanecem protegidos. No baú, 1–5 enviam madeira, pedra, fibra, sucata e milho; Shift+1–5 retira o item correspondente. A cama reparada permite dormir por E e confirmar com Espaço.

A missão M01 pede os sete reparos H01–H07, a remoção dos sete móveis condenados e seis grupos de sujeira, 20 milhos plantados e regados, e então sono até a manhã seguinte. Cada serviço de reforma mostra materiais e golpes antes do primeiro uso do martelo; Espaço confirma, Esc cancela. O material é consumido no contato do primeiro golpe. A reforma consome exatamente os materiais reservados na encomenda do correio. A horta sugerida fica em x40–44, y22–25. Há oito obstáculos leves nela. O lago fica na parte inferior esquerda; com o regador selecionado, E na margem o enche. **Dormir não restaura estamina; apenas alimentos restauram.** A cesta de umbus junto ao correio evita bloqueio por falta de comida.

O projeto carrega os PNGs e WAVs de `assets/manifest.json`. Os sprites são arte provisória de protótipo com IDs, pivôs e footprints definidos para substituição futura. A lógica de objetos, cultivo, reparo e save usa IDs estáveis. O save JSON tem três slots em `user://`, escrita temporária com troca de arquivo e backup anterior.

## Verificação

Em ambiente sem diretório pessoal gravável, defina os caminhos XDG para `/tmp`:

```bash
mkdir -p /tmp/boa-godot-data /tmp/boa-godot-config /tmp/boa-godot-cache
XDG_DATA_HOME=/tmp/boa-godot-data XDG_CONFIG_HOME=/tmp/boa-godot-config XDG_CACHE_HOME=/tmp/boa-godot-cache godot --headless --path . --editor --quit
XDG_DATA_HOME=/tmp/boa-godot-data XDG_CONFIG_HOME=/tmp/boa-godot-config XDG_CACHE_HOME=/tmp/boa-godot-cache godot --headless --path . --script res://tests/qa.gd
XDG_DATA_HOME=/tmp/boa-godot-data XDG_CONFIG_HOME=/tmp/boa-godot-config XDG_CACHE_HOME=/tmp/boa-godot-cache godot --headless --path . --script res://tests/smoke_render.gd
```

`qa.gd` valida o ciclo lógico até a manhã seguinte, incluindo entrega única, ferramentas incorretas, zero estamina e fruta de resgate, limpeza, reparo, solo regado antes e depois de semear, 20 posições únicas, editor bloqueando passagem, save/reload, árvore e toco com drops separados, venda liquidada uma única vez e rotas livres. O harness reposiciona o ator e repõe estamina para acelerar os cenários; não equivale a uma partida manual completa.

`smoke_render.gd` valida que FARM01/HOME01 abrem e que os 135 PNGs e 10 WAVs importados carregam. Este ambiente não oferece display gráfico nem Xvfb; o renderizador headless não fornece framebuffer para capturar e revisar imagens. A legibilidade, a navegação por pessoa, a qualidade das animações e o equilíbrio de duração precisam de validação humana com Godot em tela. Cidade, prefeito presencial e construções externas permanecem fora do cenário 01.

Limites atuais do protótipo: a mochila organiza pilhas automaticamente, sem arrastar slots; o correio transfere recursos livres um por tecla, sem abas gráficas; não há remapeamento de teclas, trilha musical ou controle separado para música/ambiente. O consumo de alimento usa gesto de 0,8 s e recupera estamina ao terminar. Essas interações e a escala de texto ampliada precisam de revisão visual antes de considerar a apresentação final.
