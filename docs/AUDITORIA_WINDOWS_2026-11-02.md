# Auditoria de fidelidade — 02/11/2026

## Escopo fixo
- Programa: ibisPaint **para Windows**.
- Versão-alvo: **14.1.4**, disponibilizada em 28/10/2026.
- Motor: Lua/LuaJIT + LÖVE 11.5, sem renderizador de pinceladas ou exportação.
- Repositório: SrTristeSad/Ibis-Lua; apenas a árvore da branch main.
- Implementação antiga: removida por completo.

## Referências verificadas
1. Versão oficial Windows 14.1.4: https://ibispaint.com/information.jsp?newsID=313331619
2. Produto oficial Windows: https://ibispaint.com/productWin.jsp
3. Captura Windows de New Canvas: https://img.utdstc.com/screen/a65/274/a65274b8eed31f3f889105ad4259cd2290958b5cb1ff1e9b74ffed7e65%3A600
4. Captura Windows de janela de camadas: https://img.utdstc.com/screen/344/970/344970ad640d31c7b97ff56c968af1ca47289acda116499bf94c128b7d6e0d85%3A600
5. Microsoft Store Windows (biblioteca de pincéis): https://store-images.s-microsoft.com/image/apps.32378.14202576542330599.5d8d33ef-6e70-4d7f-953d-99930bb9592a.1715e9a7-d182-4d1e-a9b7-883949af7782
6. Manual oficial: https://ibispaint.com/lecture/index.jsp?no=4
7. Parâmetros documentados de pincéis: https://ibispaint.com/lecture/index.jsp?lang=en&no=118

**Proveniência:** a captura Uptodown documenta uma versão Windows anterior (14.0.6). Só confirma a organização e geometria observadas nessa versão. Não comprova que cada pixel permanece idêntico na 14.1.4. O tutorial oficial é compartilhado entre plataformas e não substitui a captura Windows.

## Diferenças detectadas e corrigidas nesta iteração
- Janela New Canvas estava centralizada sem referência Windows: agora é um painel de galeria ancorado à direita, com linhas de dimensões, presets e controles.
- Galeria tinha um botão Back no rodapé e quase nenhum dos ícones superiores do Windows: agora reproduz a faixa de comandos.
- Os botões inferiores tinham ações atribuídas à ordem errada: agora seguem Brush/Eraser, Tool Selector, Properties, Color, Fullscreen, Undo, Redo, Layer, Back.
- O painel de pincéis não possuía as abas de parâmetros nem o catálogo lateral com as mesmas categorias observadas: foram adicionadas abas e estados independentes.
- As quinze ferramentas agora têm pictogramas específicos no módulo Lua.
- Fullscreen ganhou um estado visual dedicado, acessível pelo botão inferior e pelo Escape.

## Testes
- Lua 5.1 e LuaJIT: testes de sintaxe, estados e cobertura das quinze ferramentas.
- LÖVE real no Linux sob Xvfb: screenshots de nove estados (title, gallery, newCanvas, editor, brush, layer, color, tools, fullscreen).
- Capturas do fluxo real: https://github.com/SrTristeSad/Ibis-Lua/actions/workflows/visual-smoke.yml
- Execução no Windows e comparação de pixels com a 14.1.4: **pendentes**.

## Lacunas de fidelidade que não foram declaradas concluídas
- Ícones desenhados em Lua a partir de screenshots: ainda não estão medidos pixel a pixel nem são os assets proprietários originais.
- Versão 14.1.4 precisa de capturas de referência em resolução e escala idênticas ao protótipo.
- Galeria online, ranking, imagens e assets protegidos não reproduzidos.
- Diversas janelas e módulos continuam sem inventário e sem layout verificado: filtros, texto, material, animação, vetores e outros.
- Barra de janelas, atalhos, tipografia e proporções responsivas precisam de medição no Windows real.
- Os presets de papel da captura antiga podem ter mudado na versão-alvo; dimensões não confirmadas permanecem marcadas como pendentes.

**Resultado:** esta iteração corrigiu diferenças verificáveis de estrutura e navegação, mas não atesta equivalência visual 1:1.
