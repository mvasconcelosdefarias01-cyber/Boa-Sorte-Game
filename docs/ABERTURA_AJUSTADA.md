# Abertura ajustada

Protagonista e Lia agora se encontram em y17.9, no caminho frontal conectado à cidade, com protagonista em x59.5 e Lia percorrendo x63.5→61.5→63.5. A entrega inicial e a opção de pular mantêm suas regras. Saves ainda na introdução são reposicionados para esse encontro; saves após a abertura não são movidos.

A conversa usa painel inferior de500×102px na escala normal, crescendo até128px com texto150%. O retrato grande foi removido. Carta em painel inferior500×160px com rolagem; nenhum deles sobrepõe as projeções dos personagens no encontro. Os controles Continuar/Fechar carta e Pular apresentação permanecem por mouse e teclado.

Passaram `intro_scene.gd` (projeções dos atores fora do painel em100/125/150%, chegada/saída, entrega e save antigo), `ui_layout.gd`, `ui_input.gd` e `qa.gd`. A execução gráfica permanece bloqueada pelo controle de permissões; esses testes não substituem revisão visual em movimento no Windows.

Refinamento: durante a aproximação de Lia, o protagonista passa brevemente pela direção frontal e então pela direção direita, olhando para ela durante a conversa. Usa os quadros existentes, sem deslocar os pés. Teste intro_scene verifica as duas fases e o restante da abertura.
