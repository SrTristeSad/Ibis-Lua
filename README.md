# Ibis-Lua

Reconstrução planejada da interface do **ibisPaint para Windows 14.1.4** em Lua/LuaJIT com LÖVE 11.5, sem motor de pintura.

## Estado atual (02/11/2026)

**Base técnica e pesquisa inicial — NÃO é um clone funcional ou uma tela visualmente validada.**
A implementação anterior foi inteiramente removida da branch main, preservando o histórico Git.

O executável LÖVE agora apresenta uma **primeira interface visual interativa**: tela de título com organização baseada em captura histórica da versão Windows, My Gallery vazia, diálogo de dimensões simulado e estrutura parcial de editor. **Não são reproduções 1:1 da edição 14.1.4.** O conteúdo da captura antiga não foi transplantado como recurso, e a função Collection foi omitida por ter sido removida na versão 12.2.0. A geometria da versão 14.1.4 ainda requer capturas verificáveis.

## Organização

- main.lua e conf.lua — tela visual interativa, criação demonstrativa de tela, cliques, teclado e captura.
- src/model.lua — modelo de estado de interface simulado, independente de renderização ou processamento de imagens.
- tests/test_model.lua — testes de transições, controles e camadas demonstrativas.
- tools/compare_screenshots.py — comparação pixel a pixel, sobreposição e métricas, **apenas com imagens fornecidas legitimamente**.
- tests/test_compare.py — testes automatizados do comparador.
- docs/REFERENCIAS_WINDOWS.md — fontes com proveniência e limites de versão.
- docs/INVENTARIO_14_1_4.md — inventário por tela com nível de verificação.
- docs/VALIDACAO.md — regras de medição e aceitação, com bloqueios explícitos.
- testar.bat — inicialização no Windows e mensagens de erro.
- .github/workflows/check.yml — verificação automatizada.

## Executar no Windows

Instale LÖVE 11.5 e execute testar.bat na raiz do projeto. A janela abre com a tela inicial experimental. Clique My Gallery e + para iniciar uma tela simulada. F12 salva uma captura (na pasta de dados do LÖVE); Esc retorna ou sai.

## Testes

- LuaJIT: luajit tests/test_model.lua
- Comparador: python -m unittest discover -s tests -p "test_compare.py"
- Comparação: python tools/compare_screenshots.py --reference ref.png --actual actual.png --output-dir resultado

As imagens precisam ter mesma resolução e mesma escala de interface. O comparador **não** certifica fidelidade sozinho; a revisão visual e a proveniência da referência são obrigatórias.

## Restrições de escopo

- Sem motor de pintura, rasterização, filtros reais, importação ou exportação de obras.
- Sem recursos gráficos proprietários copiados.
- Sem telas, ícones ou estados inventados para preencher referências ausentes.
- Qualquer UI futura deve estar vinculada a uma evidência Windows e a uma validação visual comparável.

Este repositório não é o ibisPaint oficial nem possui afiliação com seus desenvolvedores.
