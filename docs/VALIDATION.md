# Verificação do protótipo

Godot 4.6.3, em 11/10/2026. O projeto foi executado pelo motor em modo headless. `tests/qa.gd` concluiu com código 0, 186 verificações PASS e nenhum erro. `tests/smoke_render.gd` abriu FARM01/HOME01 e carregou 135 PNGs, 10 WAVs e as vinte orientações visuais de móveis. `python3 assets/validate_assets.py` passou para formato, dimensões, alpha e metadados.

## Cobertura executada
Abertura, carta, entrega única, saída/skip de Lia; rotas até porta/correio/horta/lago; sete reparos e materiais exatos; sete demolições, seis limpezas; ferramenta incorreta e zero estamina; fruta de resgate; plantio/rega em ambas as ordens, vinte posições distintas, recusa de rega repetida; casa pronta, sono e manhã, estamina preservada; save/reload, dano parcial, árvore/toco e drops sem duplicação; venda/retirada e liquidação única; editor rejeitando passagem e colocando banco; estoque livre, atalhos, pilhas 99+1, opções, migração de campos antigos; gesto de alimento de 0,8 s com recuperação única no fim.

O harness reposiciona o personagem e repõe estamina para acelerar casos independentes. Portanto, essa cobertura demonstra regras e estados, mas não é um percurso manual completo da abertura até a manhã seguinte.

## Validação ainda necessária
O ambiente não tem display gráfico nem Xvfb. Não houve inspeção do jogo renderizado em uma janela, captura de framebuffer, teste humano em 720p/1080p ou medição do ritmo da missão. Conferir legibilidade da UI ampliada, alinhamento de sprites/colisões, contato das ferramentas, oclusão, noite, animações e satisfação do trabalho.

A arte é de protótipo, com menos detalhe que as referências. Permanecem retratos finais, música/ambiente, remapeamento completo de teclas, volumes separados e acabamento do correio em abas. A mochila organiza pilhas automaticamente e o estoque usa transferências por teclado. Esses limites estão descritos no README; a aderência integral de apresentação aos documentos ainda não está concluída.

## Organização
Foram usados os três subagentes solicitados (direção, assets, Godot), sem agentes adicionais. Após a ausência do North Asset Forge 2D, o usuário autorizou produzir no repositório Boa Sorte. Assets e programação ficaram em diretórios distintos. A revisão final e os testes adicionais foram concluídos pelo orquestrador.
