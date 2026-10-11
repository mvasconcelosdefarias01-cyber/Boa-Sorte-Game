# Boa Sorte — validação do cenário 01

Executar em Godot 4.6.3, com projeto em `/workspace/Boa-Sorte-Game`. Separar testes determinísticos de estado (headless) de observação em janela.

## Caminho obrigatório
Nova partida → nome com acento e limites 2–20 → Lia e carta (testar avanço e pular em sessões distintas) → entrega exatamente uma vez → Lia sai à direita → controle → H01–H07 (materiais reservados e 21 golpes), sete móveis com machado, seis sujeiras com mão → horta, 20 tiles arados/semeados/regados com um regador cheio → cama → noite e manhã do dia 2 → M01 concluída uma única vez. Conferir que a casa mudou por partes e milho brotou. Salvar, recarregar e conferir todos contadores, itens, posição, água, estamina e flags.

## Casos de proteção
Ferramenta errada não gasta estamina nem altera alvo. Sem estamina, movimento e busca de fruta do correio continuam. Dormir preserva estamina em qualquer dia. Rega/plantio repetidos não duplicam XP nem objetivo. Trabalho parcial, árvore com toco, drops, estoque e venda não duplicam no reload. Baú paga uma vez no fechamento. Peso reduz velocidade/desgasta somente durante movimento. Móvel rejeita posição que bloqueie entrada/corredor/cama; cancelar mantém posição e item. Cama não reparada leva à varanda na meia-noite. Prazo 18h é aviso, não falha. Cidade permanece fechada.

## Critérios visuais
Comparar com `Boa_Sorte_Direcao_de_Arte_Cenario_01_image1.png` (composição externa), image2 e image3 (transformação interior), image4–7 (protagonista) e image8–11 (Lia). Verificar pixel nearest e escala inteira, silhuetas, 4 direções, alinhamento dos pés, alvo adjacente, ferramenta e frame de contato, qualidade de HUD, legibilidade noturna, ícones e cursor de móveis. Rodar em 720p e 1080p se houver renderização disponível. Documentar separadamente o que for teste automatizado, observação visual do agente e validação humana pendente.
