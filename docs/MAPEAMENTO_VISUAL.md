# Mapeamento visual — Windows (02/11/2026)

## Regra de evidência

Versão-alvo: **Windows 14.1.4**, anunciada oficialmente em 28/10/2026.
Capturas externas abaixo são da edição Windows, mas **não têm metadados suficientes para provar que representam a versão 14.1.4**. Não afirmar pixel-perfect até obter referência dessa compilação na mesma resolução e escala.

## W1 — My Gallery / New Canvas (Windows, terceiros)

URL: https://ibis-paint.uptodown.com/windows
Imagem: https://img.utdstc.com/screen/a65/274/a65274b8eed31f3f889105ad4259cd2290958b5cb1ff1e9b74ffed7e65b1ae2a%3A600

Observado: barra superior escura My Gallery, botões à direita (incluindo +, Select, Edit); fundo de galeria off-white; New Canvas **painel ancorado à direita** sob barra superior, título escuro, Import Picture, W/H com controles, Speed ↔ Quality, lista longa de modelos e botão OK no rodapé.

Modelos visíveis: SD (Speed), 1:1 (SD), 3:4 (SD), 9:16 (SD), Twitter Header, Chat Stamp, Vertical, Manga Manuscript, Postcard (JP), A4, A5, B4, B5.

Implementação: gallery_header, gallery_screen, draw_new_canvas.
Ainda não verificado: tamanhos exatos, fontes, ícones, posição das opções e alterações introduzidas em versões posteriores.

## W2 — Editor e pincéis (Windows, Microsoft Store)

URL: https://apps.microsoft.com/detail/9pfdf2zd4z4n
Imagem: https://store-images.s-microsoft.com/image/apps.62782.14202576542330599.5d8d33ef-6e70-4d7f-953d-99930bb9592a.91fbe5d5-ba54-4efc-92b2-f5f6b5059862

Observado: **barra vertical de ferramentas à esquerda**, ícones pequenos e seleção colorida; janela Brush flutuante sobre o canvas, com lista de brushes, propriedades e sliders; controles na parte inferior.

Implementação: editor_screen, draw_editor_panel(brush), draw_size_controls.
Limites: UI do pincel ainda parcial, ícones vetoriais próprios sem equivalência aprovada.

## W3 — Editor / janela Layer (Windows, terceiros)

URL: https://ibis-paint.en.uptodown.com/windows
Imagem: https://img.utdstc.com/screen/344/970/344970ad640d31c7b97ff56c968af1ca47289acda116499bf94c128b7d6e0d85%3A600

Observado: janela de camadas flutuante no lado inferior direito, cabeçalho, miniaturas, visibilidade, adição de camada e menus pequenos; barra de controle inferior permanece.

Implementação: draw_editor_panel(layer). Conteúdo simulado, sem renderização de obra.

## W4 — Referência oficial dos controles

URL: https://ibispaint.com/lecture/index.jsp?no=4

Documenta 15 ferramentas, a ordem dos 9 controles do rodapé e 6 botões na parte superior direita. Fonte funcional oficial, porém material multiplataforma; as dimensões e o desenho específico no Windows 14.1.4 precisam verificação.

## W5 — Tela inicial histórica

URL: https://prtimes.jp/main/html/rd/p/000000010.000015594.html

Screenshot original Windows **9.4.2** comprova paleta azul, logo, navegação circular e Daily Ranking, mas também mostra o antigo botão Collection. Este botão foi removido posteriormente e não foi desenhado na reconstrução. Nenhum pixel dessa tela pode ser declarado referência 14.1.4.

## W6 — Mudanças 14.1.4

URL: https://ibispaint.com/information.jsp?newsID=313331619

Inclui mudanças em Settings/login, checkmark de alguns diálogos e status de nuvem na galeria após sincronização. Essas interfaces não foram inventadas: os estados dependentes de nuvem/login precisam de referências e/ou conexão real, fora do escopo simulado.

## Resultados e problemas restantes

- **Corrigido no código**: barras pretas de letterbox derivadas de largura virtual fixa; desenho agora utiliza toda a janela e âncoras relativas.
- **Corrigido no código**: New Canvas deixou de ser modal central genérico; agora é lateral como no Windows.
- **Corrigido no código**: toolbar de texto no rodapé foi trocada por barra vertical com ferramentas e footer iconográfico.
- **Testado**: screenshots de título, gallery, new canvas, editor e layer gerados por LÖVE Linux/Xvfb. Não são comparações com o ibisPaint original.
- **Não concluídos**: equivalência visual de ícones, todas as configurações, menus, ferramentas, fontes, estados hover, conteúdo de My Gallery e detalhes de New Canvas.
- **Sem percentual de fidelidade**: falta referência original Windows **14.1.4** com DPI, resolução, idioma e estado registrados.

A ferramenta de diff de screenshots permanece em tools/compare_screenshots.py; gerar métricas só quando existirem imagens realmente comparáveis.

## W7 — Seletor de cor (captura publicada por usuário Windows)

Página: https://note.com/nitijo_tubuyaki/n/nddff01f99a4f

Referência visual pública: screenshot da janela Color com grade de amostras à esquerda, círculo de matiz à direita e losango interno de saturação e luminosidade, além de controles RGB/alpha.

Implementação: draw_hue_wheel e draw_editor_panel(color): círculo HSV e losango reconstruídos geometricamente, interação de matiz/saturação/luminosidade, paleta demonstrativa, prévia hexadecimal e canais RGB.

**Limites:** captura sem comprovação de ser Windows 14.1.4; não afirmar equivalência da paleta de amostras, da disposição dos canais ou das medidas. O alfa permanece simulado por opacidade do rodapé.

## Incremento de navegação e camadas — 02/11/2026

- **Viewport visual, sem edição de imagens**: módulo puro src/viewport.lua. Mouse wheel aproxima/afasta o canvas com ancoragem no cursor; Shift+mouse wheel rotaciona; Espaço+arrastar move; limites de zoom testados.
- **Modo Solo de camadas**: módulo src/model.lua preserva a visibilidade anterior, permite trocar a camada isolada, restaura o estado ao desativar e encerra o Solo quando uma operação incompatível é solicitada.
- **Bug de cliques atravessando janelas**: painéis e New Canvas interceptam cliques em suas superfícies, em vez de acionar controles posicionados atrás.
- **Campos numéricos New Canvas**: o primeiro dígito digitado substitui o conteúdo selecionado; Tab alterna os campos e Backspace edita valores.
- **Ressalva**: gestos e modo Solo foram implementados a partir de tutoriais/documentação oficial de Windows/14.1.0, mas os elementos visuais da versão-alvo 14.1.4 continuam aguardando confrontação.

Fontes: https://ibispaint.com/lecture/index.jsp?no=167 e https://ibispaint.com/newFeature.jsp

## W8 — Refinamento de New Canvas e testes de interação

- A proporção horizontal da janela lateral foi ajustada para ~69% da área lógica em janelas grandes, de acordo com a referência visual Windows apresentada em W1; **nenhuma medição 14.1.4 foi feita**.
- Os controles W/H `-`, slider arrastável e `+` agora alteram numericamente as dimensões. A faixa atual do slider (1–8192) é apenas uma escolha implementativa provisória; não é parâmetro oficial verificado. Entrada manual continua permitindo valores até 16384.
- O valor inicial **1000 x 1000** não seleciona falsamente o preset SD (Speed), porque ele tem valores diferentes.
- O pipeline executa interação end-to-end com mouse: título → galeria → novo canvas → editor → layer → zoom. Também captura nove estados em screenshots para inspeção posterior.
- Evidência original: https://ibis-paint.uptodown.com/windows (imagem Windows de versão não identificada). Falta confronto com captura real Windows 14.1.4.

## W9 — View Menu, Grid Settings e janela de referência (documentação oficial)

Referências oficiais de nomenclatura e funcionamento:

- Tutorial View Menu: https://ibispaint.com/lecture/index.jsp?no=168
- Imagem de opções: https://ibispaint.com/img/lecture/en/chapter_168_01.png
- Imagem de Grid Settings: https://ibispaint.com/img/lecture/en/chapter_168_02.png
- Referência da janela de Settings: https://ibispaint.com/lecture/index.jsp?no=81

**Verificado funcionalmente**: toggles Reference Window, Grid e Manga Manuscript; configurações de Grid 1/2 Interval, Grid 1/2 Color e Position X/Y; Reset; opções Smooth/Pixelated para exibição ampliada. O tutorial oficial apresenta controles dessas funções, porém não atesta a geometria específica **Windows 14.1.4**.

**Implementado agora**: ViewState independente de motor de pintura, opções com controles de estado, guias renderizadas sobre o canvas respeitando zoom/rotação, janela de referência demonstrativa em modo Canvas, seleção Smooth/Pixelated, botões para intervalos, origem e cores de exemplo. Novos testes de modelo e cliques reais de integração (incluindo View Menu e Grid Settings); quatro capturas adicionais incorporadas ao CI.

**Pendências**: seletor real de cores de guia, edição fina/drag dos parâmetros da grade, proporções exatas, toda a janela real de referência e referência Windows 14.1.4 em resolução, DPI e idioma medidos. Os controles de interpolação mudam apenas o estado porque não existe motor de imagens.
