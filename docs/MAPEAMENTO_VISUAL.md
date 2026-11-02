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
