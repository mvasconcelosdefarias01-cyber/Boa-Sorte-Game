# Cidade Boa Sorte — exteriores

## Referência e arquitetura

Implementação orientada pela imagem aprovada enviada pelo jogador: rio vertical central, ponte e rua principal horizontal, Correios/Banco/Prefeitura a noroeste; igreja e praça, Museu e Biblioteca e Hospital a nordeste; Mercado/Armazém/Loja/Bar a sudoeste; Restaurante/Oficina a sudeste. Quatro residências ao norte e oito ao sul, sem famílias ou moradores inventados.

`CITY01` mantém o controlador de `main.tscn` e o estado único de `scripts/game.gd`. O mapa estático fica em `scripts/city_map.gd`. Não são carregados interiores nem cenas inexistentes. A cidade ocupa 64×48 tiles de 32 px, com limite norte em y=-8. Essas coordenadas permitem manter a entrada oeste e a ponte na mesma altura y13 da estrada existente, distribuindo os bairros ao norte e ao sul sem deslocamento vertical na travessia. A câmera limita-se ao retângulo real do mapa.

Prédios são sprites independentes, com metadados de dimensão/pivô; colisões ocupam o volume térreo. Vegetação e recursos visuais existentes são reutilizados, preservando PNGs anteriores. O desenho mantém ordenação por profundidade e nearest neighbor. A referência não foi usada como fundo achatado.

## Transições e persistência

O bloqueio provisório no leste de ROAD01 é aberto somente na faixa da estrada; margens continuam bloqueadas. A conexão usa `transition_to`, o mesmo método das conexões anteriores:

- ROAD01 leste → CITY01 oeste, chegada próxima em (3,13).
- CITY01 oeste → ROAD01 leste, chegada em (44,13).
- Fazenda ↔ estrada permanece alinhada ao caminho frontal da casa (y17 na fazenda).

Chegadas ficam separadas dos gatilhos; cooldown e trava de chegada impedem rebote. Carregar uma posição inválida ou dentro da passagem reposiciona o personagem no ponto seguro. Ferramenta selecionada e direção de travessia são preservadas. Não há recriação da fazenda nem reinicialização de plantios, objetos ou reparos.

Cidade e estrada não permitem que ferramentas acessem os dados de cultivo/reparo da fazenda por coordenadas coincidentes. Não há compras, banco funcional, missões, NPCs, forja, arqueologia ou escrita. Somente a conexão oeste da cidade é ativa; as outras bordas têm barreiras visuais e colisão.

## Verificação

Os testes são executados com Godot 4.6.3 em modo headless e diretórios XDG isolados. `tests/city_transition.gd` verifica três percursos completos nos dois sentidos, preservação do estado, seleção de ferramenta, direção, ausência de rebote/duplicação, salvamento na cidade, recuperação de posição inválida, câmera, rio, ponte e acesso às 24 fachadas por busca de caminhos. O teste da estrada foi atualizado para a conexão leste agora ativa.

A montagem visual está em revisão. Captura em execução e comparação final com a referência ainda não foram realizadas: a execução gráfica foi negada anteriormente pelo controle de permissões. Testes headless não comprovam fidelidade visual, oclusão correta em movimento ou experiência manual. Não considerar o acabamento aprovado sem esse teste humano.

## Assets e revisão estática

Trinta sprites independentes foram derivados de quatro folhas geradas com ImageGen (prédios, 12 casas e elementos da praça/ponte/piso), com fontes e prompts em `assets/sources/city`, importação reproduzível em `assets/import_city.py` e hashes/recortes em `assets/manifest.json`. Mercado Boa Safra teve o letreiro corrigido na faixa existente. Pedras, árvores, arbustos, capim e cactos anteriores mantêm seus bytes.

A montagem estática foi comparada visualmente à referência. O mapa inicial foi compactado de 96×64 para 64×48 mantendo os sprites na escala original. Foram corrigidos resíduos de recorte e texto, adicionados jardins com cercas e arbustos e pedras às margens do rio. `tests/export_city_layout.gd` exporta os dados usados na prévia estática, que não é uma captura do framebuffer.

Limites visuais: a composição é uma adaptação na grade navegável; o rio tem margens retas, e jardins/varandas não são cópias pixel a pixel da referência. Aparência em movimento e oclusão ainda exigem revisão humana. Somente exteriores e conexão oeste estão ativos.

Verificações finais: 196 entradas PNG e 10 WAVs validadas; todos os PNGs anteriores preservados por SHA-256; CITY QA=0 falhas, ROAD QA=0 falhas e ciclo QA completo. A prévia `PREVIA-ESTATICA.png` no pacote é uma montagem dos mesmos sprites/posições, não uma captura de execução.
