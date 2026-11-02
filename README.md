# Ibis-Lua — reconstrução da interface Windows em Lua/LÖVE

**Objetivo:** interface visual e navegável do ibisPaint Windows 14.1.4, sem motor de pintura, escrita em Lua/LuaJIT e LÖVE 11.5.

## Estado atual — 02/11/2026

Esta versão **já contém telas e controles clicáveis**. A reconstrução **não está concluída nem validada como cópia 1:1**. A maior parte das capturas Windows públicas consultadas não identifica a compilação 14.1.4.

- **Tela inicial** com disposição orientada por referência Windows histórica (9.4.2). Sem Collection (função removida depois).
- **My Gallery** com barra superior, controles de navegação e estado vazio.
- **New Canvas lateral direito**, incluindo edição de dimensões, lista rolável de presets e criação de documento demonstrativo; substitui o diálogo central anterior.
- **Editor** com faixa vertical de 15 ferramentas e respectivos ícones vetoriais próprios, controles inferiores, botões superiores, painéis de pincel, cor e camadas.
- **Comportamentos simulados**: seleção de ferramenta, brush/eraser, dimensões, espessura, opacidade, paleta e camadas.
- Recursos que precisariam de processamento de imagens não são fingidos: pintura, filtros reais, importação/exportação e renderização de camadas estão fora do escopo.

**Nenhuma tela é certificada como visualmente equivalente ao original.** O desenho de diversos ícones, cores e subpainéis ainda precisa de comparação com a aplicação real versão 14.1.4.

## Execução

Instale LÖVE 11.5 (https://love2d.org/) e execute testar.bat na pasta do projeto.

No programa: clique em My Gallery, +, escolha dimensões e clique OK. O editor usa B (pincel), E (borracha), L (camadas), C (cores), colchetes (espessura), Escape (voltar) e F12 (captura).

## Testes

- Lua: luajit tests/test_model.lua
- Dependências Python: pip install -r requirements-dev.txt
- Comparador: python -m unittest discover -s tests -p "test_compare.py"
- Diferença de imagens: python tools/compare_screenshots.py --reference original.png --actual copia.png --output-dir comparison_output

O GitHub Actions realiza verificação sintática, testes do modelo, testes do comparador e **abre cinco telas no LÖVE com captura** (título, galeria, novo canvas, editor, camadas). Capturas automatizadas não comprovam correspondência com o software original.

## Pesquisa e qualidade

- docs/REFERENCIAS_WINDOWS.md — fontes públicas e limitações.
- docs/MAPEAMENTO_VISUAL.md — observações da interface, origem por elemento e lacunas.
- docs/INVENTARIO_14_1_4.md — inventário.
- docs/VALIDACAO.md — procedimento de verificação e critérios de aceitação.

**Avisos:** não incorporar imagens ou arquivos proprietários do ibisPaint ao projeto; não afirmar porcentagens não verificadas; não usar telas Android para preencher lacunas Windows; manter os arquivos Lua editáveis. O projeto não é afiliado à ibis inc.
