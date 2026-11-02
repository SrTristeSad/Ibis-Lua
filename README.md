# Ibis-Lua — reconstrução da interface Windows em Lua/LÖVE

**Objetivo:** interface visual e navegável do ibisPaint Windows 14.1.4, sem motor de pintura, escrita em Lua/LuaJIT e LÖVE 11.5.

## Estado atual — 02/11/2026

Esta versão **já contém telas e controles clicáveis**. A reconstrução **não está concluída nem validada como cópia 1:1**. A maior parte das capturas Windows públicas consultadas não identifica a compilação 14.1.4.

- **Tela inicial** com disposição orientada por referência Windows histórica (9.4.2). Sem Collection (função removida depois).
- **My Gallery** com barra superior, controles de navegação e estado vazio.
- **New Canvas lateral direito**, incluindo edição de dimensões, lista rolável de presets e criação de documento demonstrativo; substitui o diálogo central anterior.
- **Editor** com faixa vertical de 15 ferramentas e respectivos ícones vetoriais próprios, controles inferiores, botões superiores, painéis de pincel, cor e camadas. Visualização do canvas com **zoom pelo scroll do mouse, rotação com Shift+scroll e pan com Espaço+arrastar**.
- **Comportamentos simulados**: seleção de ferramenta, brush/eraser, dimensões, espessura, opacidade, paleta e camadas. Inclui **modo Solo**: manter pressionado o ícone de visibilidade da camada e soltar; pressionar de novo restaura os estados anteriores.
- Recursos que precisariam de processamento de imagens não são fingidos: pintura, filtros reais, importação/exportação e renderização de camadas estão fora do escopo.

**Nenhuma tela é certificada como visualmente equivalente ao original.** O desenho de diversos ícones, cores e subpainéis ainda precisa de comparação com a aplicação real versão 14.1.4.

## Execução

Instale LÖVE 11.5 (https://love2d.org/) e execute testar.bat na pasta do projeto.

No programa: clique em My Gallery, +, escolha dimensões e clique OK. Os campos W/H aceitam seleção e substituição ao digitar (Backspace apaga, Tab troca o foco). No editor, scroll amplia/reduz o canvas, Shift+scroll o rotaciona e Espaço+arrastar move a visualização sem alterar os pixels. Mantenha pressionado o olho de uma camada para ativar/desativar o modo Solo; clique curto alterna visibilidade. B/E trocam pincel/borracha, L abre camadas, C abre cores, colchetes alteram a espessura, Escape volta e F12 captura.

## Testes

- Lua: luajit tests/test_model.lua, luajit tests/test_viewport.lua, luajit tests/test_layer_solo.lua e luajit tests/test_view_state.lua
- Dependências Python: pip install -r requirements-dev.txt
- Comparador: python -m unittest discover -s tests -p "test_compare.py"
- Diferença de imagens: python tools/compare_screenshots.py --reference original.png --actual copia.png --output-dir comparison_output

O GitHub Actions realiza verificação sintática, testes do modelo, testes do comparador, integração por cliques e **captura dezessete estados no LÖVE** (título, galeria, novo canvas, editor, camadas, janela flutuante redimensionada, propriedades de camadas, menu de blending, fundo transparente, pincéis, cor, zoom/rotação, modo Solo, View Menu, Grid Settings, grade e janela de referência). Capturas automatizadas não comprovam correspondência com o software original.

## Pesquisa e qualidade

- docs/REFERENCIAS_WINDOWS.md — fontes públicas e limitações.
- docs/MAPEAMENTO_VISUAL.md — observações da interface, origem por elemento e lacunas.
- docs/INVENTARIO_14_1_4.md — inventário.
- docs/VALIDACAO.md — procedimento de verificação e critérios de aceitação.

**Avisos:** não incorporar imagens ou arquivos proprietários do ibisPaint ao projeto; não afirmar porcentagens não verificadas; não usar telas Android para preencher lacunas Windows; manter os arquivos Lua editáveis. O projeto não é afiliado à ibis inc.

## Teste de navegação real e controles New Canvas

A variável `IBIS_LUA_E2E=1` executa uma sequência de cliques dentro do próprio LÖVE (sem substituir callbacks por chamadas diretas ao modelo): abre **My Gallery**, abre **New Canvas**, aumenta a largura com `+`, digita largura e altura, cria uma tela de demonstração, abre **Layer**, muda a visibilidade de uma camada, fecha a janela e amplia o canvas com a roda do mouse. O GitHub Actions executa o teste e falha se a navegação ou o estado não corresponderem às verificações.

No painel **New Canvas** os botões `-`/`+` e os sliders W/H funcionam; os controles respondem ao arrastar. Para o slider, a faixa demonstrativa é de **1 a 8192 pixels**, enquanto os campos manuais aceitam de 1 a 16384. **Essa faixa não foi confirmada na versão oficial 14.1.4** e não representa uma afirmação sobre o comportamento exato do aplicativo proprietário.

## View Menu e grade — etapa atual

- No editor, abra **View Menu** no primeiro ícone da região superior direita.
- **Grid** alterna as linhas de referência no canvas; **Grid Settings** permite mudar os intervalos, alternar as cores demonstrativas, deslocar a origem em passos de 8 pixels e restaurar os valores da simulação.
- **Reference Window** abre uma miniatura demonstrativa do canvas, sem importação de imagens; **Manga Manuscript** alterna guias ilustrativos, ainda não validados geometricamente.
- A escolha **Smooth / Pixelated** é mantida no estado da interface. **Não há rasterização nem imagem importada**, portanto não há efeito de interpolação aplicado a pixels reais.
- Valores atuais (64/256 px e posições 0/0) e cores ilustrativas **não são valores padrão comprovados do ibisPaint Windows 14.1.4**.
- As operações foram fundamentadas na documentação oficial de View Menu: https://ibispaint.com/lecture/index.jsp?no=168. As imagens desse tutorial são multiplataforma e **não devem ser apresentadas como capturas Windows 14.1.4**.

## Janela de camadas — atualização de 02/11/2026

O painel Layer foi reconstruído a partir da documentação de **Layer Window Details** e de capturas publicadas da edição Windows. Agora apresenta Selection Layer, miniaturas demonstrativas, seleção/visibilidade de camadas, botão para adicionar camadas, opacidade com slider, Clipping, Alpha Lock, seletor de Blending Mode e opções visuais de fundo White/Light/Dark. Arraste o cabeçalho da janela Layer para reposicioná-la; arraste seu canto inferior direito para redimensioná-la. O tamanho e a posição ficam no estado da interface, sem alterar os dados da obra.

**Importante:** nenhuma dessas opções processa uma imagem real. Modos Multiply/Screen/Overlay são apenas estados selecionáveis, e a transparência é apenas um padrão quadriculado na visualização do canvas. Renomear e bloquear camadas têm suporte no modelo de dados, mas **ainda não possuem interfaces próprias**.

A versão atual inclui `tests/test_layer_properties.lua`, executado no CI, além de verificações end-to-end pelos próprios botões. A interface de camadas da build Windows 14.1.4 **não foi medida pixel a pixel**.

Fontes: https://ibispaint.com/lecture/index.jsp?no=156 e https://ibis-paint.en.uptodown.com/windows.
