# HUD e baú de vendas

Interface unificada para fazenda, interior, estrada e cidade. Molduras de madeira em cores quentes, cantos retos, sombra discreta e destaque de seleção. Usa Controls e ícones aprovados; nenhum sprite do mundo foi alterado.

- Alto à direita: dia, período e horário; moedas em painel separado abaixo. O calendário mantém a contagem de dias existente, sem inventar estações ou meses.
- Baixo à direita: barras verticais V/vida verde-clara e E/estamina amarela. Preenchimento de baixo para cima, valor e máximo reais, tooltip com os números.
- Atalhos centralizados embaixo, oito ícones, teclas e quantidades inteiras. Seleção com borda contrastante; estilos só são recriados quando muda a seleção.
- Missões no botão quadrado !, abrindo a aba Objetivos do diário existente. J e Esc conservam o fluxo anterior. Resumo permanente de missão removido do HUD.
- Peso como texto discreto sobre a barra; avisos temporários no alto, fora do relógio.
- Baú: ícones de madeira, pedra, fibra, sucata e milho, quantidade enviada, seleção e tooltip com estoque/enviado. Regras de envio, retirada e pagamento ao amanhecer preservadas.

O layout anterior exclusivo das margens do interior foi substituído pelo HUD unificado solicitado; o teste antigo de não interseção com o interior foi atualizado, conservando a verificação de limites da tela e dos painéis.

Validação: `tests/ui_layout.gd` passou em100/125/150%; `ui_input.gd` e `ui_flow.gd` passaram. `hud_redesign.gd` envia clique real no botão!, verifica isolamento do mundo, proporções das barras com máximos diferentes e presença dos cinco ícones do baú. Exportação e carregamento das quatro áreas são verificados no pacote.

A execução gráfica foi bloqueada anteriormente pelo controle de permissões. Não há captura nova em execução; o visual, a animação das barras e a leitura no Windows exigem teste humano. Nenhuma aprovação visual foi inferida dos testes headless.
