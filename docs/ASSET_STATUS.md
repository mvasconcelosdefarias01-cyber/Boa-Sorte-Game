> Revisão visual posterior: veja [ASSET_MAPPING.md](ASSET_MAPPING.md) e [VISUAL_FIXES.md](VISUAL_FIXES.md) para a amostra derivada das referências e suas pendências. O registro abaixo descreve a base anterior.

# Boa Sorte — pacote de assets do cenário 01

## Entrega

A instrução posterior do usuário autorizou usar `Boa-Sorte-Game` como repositório de trabalho. Assets estão em `assets/`, sem alterações em cenas, scripts ou configuração Godot pelo agente de assets. `assets/manifest.json` lista **135 PNGs** e **10 efeitos WAV** com caminhos `res://` estáveis, além de aliases para `actor_player`, `actor_lia`, `H01` a `H07` e ferramentas. `assets/build_assets.py` e `assets/build_audio.py` regeneram o pacote; `assets/validate_assets.py` verifica os exports.

## Integração

- `actors/actor_player.png` e `actors/actor_lia.png`: sheets **64 × 256 px**, frame **32 × 64 px**, duas colunas (`idle`, `walk`), linhas `down`, `left`, `right`, `up`; pivô local **[16, 63]**. Sapatos terminam em y=62 em todos os frames.
- `actors/action_{axe,pick,hoe,scythe,water,hammer,sow,clean,eat}.png`: sheets **128 × 256 px**, 4 frames por direção e frame de contato 2. Lia possui `lia_deliver.png` e `lia_talk.png`.
- `buildings/house_H01_old.png` e `house_H01_restored.png`: fachada 384 × 288 (12 × 9 tiles), pivô [176, 288] para ancoragem em (49,5; 16) tiles; ocupa x44..55, y7..15 e mantém o limiar da porta em y16. `repair_H03_window_boarded/open.png` são estados separados. `ground/` contém solo, caminho, grama, água, borda de lago e piso/parede antigos e restaurados.
- `flora/`, `props/`, `crops/`, `furniture/`, `dirt/` e `icons/` trazem PNGs independentes. `furniture/` inclui quatro orientações visuais de cama, sofá, fogão, pia e banco, com footprints e pivôs no manifest. Não usar a imagem externa de referência como mapa achatado. Restaurar móveis e limpar grupos separadamente.
- `audio/`: efeitos curtos PCM16 mono 22050 Hz para seis ferramentas, coleta, comida, confirmação de UI e passo na areia. `manifest.json` contém caminhos em `audio`.

## Validação e limites

`python3 assets/validate_assets.py` passou: caminhos existentes, dimensões, metadados, PNG RGBA, alpha binário, orientações de móveis distintas e frames divisíveis. Os dez WAVs foram abertos com `wave` e confirmados como PCM16 mono a 22050 Hz. Prévia visual examinada: silhuetas e cores da casa, protagonista, Lia, árvores, cactos, ruínas e móveis. A semente de milho recebeu montículo e contraste; os pés dos atores foram alinhados após essa inspeção.

**Arte provisória:** os sprites desenhados para o protótipo têm densidade e acabamento inferiores às 11 referências. Não foram validados por teste humano em 720p/1080p nem em todas as telas do jogo. A ficha de asset especifica pivôs, footprints e colisões para integração, mas colisões efetivas e leitura em execução dependem do projeto Godot. Não há música, ambiente contínuo nem retratos finais. Os PNGs originais fornecidos permanecem intactos.
