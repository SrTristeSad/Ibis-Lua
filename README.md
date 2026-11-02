# Ibis-Lua

Reconstrução planejada da interface do **ibisPaint para Windows 14.1.4** em Lua/LuaJIT com LÖVE 11.5, sem motor de pintura.

## Estado atual (02/11/2026)

**Base técnica e pesquisa inicial — NÃO é um clone funcional ou uma tela visualmente validada.**
A implementação anterior foi inteiramente removida da branch main, preservando o histórico Git.

O executável LÖVE deste commit mostra apenas uma **tela de diagnóstico identificada**, não uma interface atribuída ao ibisPaint. Isso é intencional: ainda não existem capturas comprovadamente da versão Windows 14.1.4 com resolução e escala documentadas que permitam uma reconstrução 1:1.

## Organização

- main.lua e conf.lua — ponto de entrada LÖVE e captura de diagnóstico.
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

Instale LÖVE 11.5 e execute testar.bat na raiz do projeto. O diagnóstico abre em uma janela LÖVE, com F12 para salvar uma captura (na pasta de dados do LÖVE) e Esc para sair.

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
