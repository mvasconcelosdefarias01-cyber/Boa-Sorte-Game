# Lago e gramados — etapa 5

A pedido do jogador, esta etapa altera somente a distribuição da grama e o lago. Todos os PNGs anteriores foram preservados por comparação SHA-256. A grama decorativa não adiciona colisores nem objetos ao save.

## Fonte e integração

O lago foi adaptado com ImageGen usando a nova referência inline do jogador. A fonte está em `assets/sources/imagegen/lake_source.png`; não é um recorte exato do PNG original. A normalização reproduzível está em `assets/import_lake_slice.py`, com hashes, origem, dimensão e pivô em `assets/manifest.json`. O sprite mantém água azul/turquesa, pedras laranjas e juncos. A fidelidade visual em execução aguarda teste do jogador.

`environment/lake_base` tem 576×416 pixels, pivô [288,416], origem no tile (7,30), âncora (16,43). Os três overlays `environment/lake_water_0..2` acrescentam pequenos reflexos a 2 quadros por segundo. A máscara restringe os reflexos aos pixels azuis internos; bordas, pedras e juncos permanecem estáticos. Filtro nearest e alpha binário.

A colisão foi ajustada após inspecionar o sprite final: tiles com mais de 20% de pixels de água entram na máscara, preenchendo intervalos horizontais. Nas linhas y31..41, os intervalos x inclusivos são: 12..14, 11..17, 9..20, 9..22, 8..23, 8..23, 8..23, 9..22, 10..21, 12..20, 13..16. São 123 tiles, todos dentro do antigo retângulo. O contorno é aproximado à grade de gameplay de 32 pixels. O ponto de referência do ator continua bloqueado pela água.

`is_lake` é compartilhado por movimento e solo; `lake_shore` identifica vizinhos ortogonais secos. Encher o regador requer margem caminhável, ferramenta selecionada e 1 de estamina, como antes. A borda não pode ser arada. Não há expansão sobre objetos ou solo dos saves antigos.

## Gramados

Seis manchas decorativas próximas ao lago, com tufos adjacentes e intervalos de areia. Fora dele, clusters determinísticos de 3×3 têm maior ocupação, formando pequenos gramados em outras regiões. Horta, ruína, casa, estrada, água e margem imediata ficam excluídas. Objetos existentes e solo cultivado têm prioridade no desenho.

O teste encontrou 481 posições potenciais de grama no mapa, contra 217 na fórmula anterior sem exclusões, e 18 posições no anel próximo ao lago. São posições potenciais: objetos, câmera e cultivo reduzem o número desenhado. A distribuição não altera recursos nem progresso.

## Verificações e limites

- 165 PNGs e 10 WAVs validados; PNGs anteriores mantêm seus hashes.
- Três frames distintos, todos os pixels animados contidos na máscara de água.
- `tests/lake_stage5.gd`: 123 tiles bloqueados, 37 margens caminháveis aptas a reabastecimento, grama fora da água/horta, recarga, save/reload e falta de estamina.
- `tests/qa.gd`: ciclo lógico de abertura, reforma, cultivo e manhã seguinte; dormir não recupera estamina.
- A execução gráfica foi negada pelo controle de permissões em etapas anteriores. Não foi repetida. Headless não valida aparência em movimento; apresentação e animação no Windows permanecem para teste humano.

## Revisão 5B — borda

Rochas e juncos refinados via ImageGen, em `assets/sources/imagegen/lake_border_refined.png`. Integração por `assets/import_lake_border.py` depois do importador original. Os 112284 pixels azuis originais foram restaurados exatamente; frames, máscara, colisão e gameplay não mudaram. Novo sprite inspecionado estaticamente; aparência em execução no Windows aguarda teste humano. Pacote `BoaSorte-Etapa05B-Windows11.zip`.
