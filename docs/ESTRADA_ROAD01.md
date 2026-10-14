# Estrada entre a fazenda e a futura Boa Sorte

ROAD01 é um mapa independente de 48×24 tiles de 32 px. O projeto já desenha FARM01 e HOME01 a partir de `main.tscn` e `scripts/game.gd`; a estrada segue esse padrão, com dados estáticos em `scripts/road_map.gd`. Não há uma nova instância do jogador nem troca do dicionário de estado da partida.

## Composição e assets

Estrada de terra central com curvas suaves discretizadas na grade e cinco tiles livres de largura. Margens acessíveis com capim; bordas superior/inferior mais densas, com árvores de diferentes estágios, arbustos, mandacarus, palmas, pedras, gravetos e troncos. Elementos são sprites independentes, usando os mesmos IDs, pivôs, escala, ordenação por profundidade e filtragem nearest da fazenda. Copas não colidem; a base ocupa um tile conforme o padrão existente.

Todos os PNGs anteriores foram comparados por SHA-256 e preservados. Nenhum asset foi gerado. Não existem sprites independentes de cerca ou placa no catálogo atual; esses elementos da referência não foram improvisados. A saída leste é visivelmente fechada por duas colunas de troncos e rochas existentes, com colisão em todas as linhas, impedindo contorno pelas margens. A estrada continua desenhada sob o bloqueio, sugerindo a futura conexão. Cidade, NPCs, missões, recompensas e desbloqueio não foram criados.

## Conexões

- FARM01: passagem leste x61..63, y16..18, alinhada ao caminho em frente à casa. E interage na passagem; caminhar até x63 também aciona a saída.
- Destino ROAD01: tile (1,12), livre de obstáculos, dentro da zona oeste.
- Retorno ROAD01: E na zona oeste ou caminhar até x0; destino FARM01 (62,17), livre.
- `arrival_latch` impede repetição enquanto o personagem não sair da zona de chegada. A trava é reconstruída ao carregar uma partida nessa zona; o cooldown existente continua em uso.
- `transition_to` conserva o estado, cancela ações pendentes, atualiza posição/câmera e salva seguindo o padrão existente.

Objetos da estrada são estáticos, não recursos removíveis. Ferramentas na estrada não acessam solo ou reparos da fazenda em coordenadas coincidentes. Inventário, vida, estamina, horário, plantios, objetos removidos e reformas continuam no mesmo estado persistente. Norte/sul da fazenda e entrada/saída da casa mantêm seu comportamento anterior.

A câmera usa limites próprios de ROAD01 (1536×768 px) e os limites anteriores de FARM01/HOME01. Não há deslocamento da câmera além do mapa.

## Verificações executadas

`tests/road_transition.gd` roda a cena no Godot headless, usa eventos de movimento e verifica:

- Três ciclos de ida e volta, chegadas caminháveis e ausência de rebote.
- Reativação após sair da zona e trava após recarregar sobre a chegada.
- Corredor inteiro livre, busca de rota até o bloqueio e impossibilidade de cruzar ou contornar o bloqueio leste.
- Ferramentas não alteram plantios/reparos da fazenda pela estrada.
- Persistência de estado após cada percurso e save/reload; contagem de nós sem duplicação do ator.
- Câmera limitada nos quatro extremos; saídas norte/sul preservadas.
- Todos os sprites usados existem no catálogo.

`tests/qa.gd` passou no ciclo lógico anterior de abertura, reforma, cultivo, sono, save/reload e estamina recuperada apenas por alimentos. Todos os assets foram preservados por hash. A cena é executada em modo headless: isso verifica comportamento e carregamento, não qualidade visual. A execução gráfica foi negada anteriormente pelo controle de permissões e não foi repetida. Percurso manual, oclusão das copas, composição em movimento e execução no Windows permanecem para validação humana.

Pacote: `dist/BoaSorte-Estrada-Windows11.zip`, com executável e instruções. Não requer Godot instalado para jogar.

Ajuste solicitado após teste: passagem e retorno movidos para a altura do caminho frontal (y17); caminho estendido até a borda leste. Demais elementos preservados.
