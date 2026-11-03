# Integração do Ibis-Rebuild-Windows ao visual Ibis-Lua

## Objetivo e fontes

**Front-end principal:** [SrTristeSad/Ibis-Lua](https://github.com/SrTristeSad/Ibis-Lua), com a galeria, o canvas, o dock, os painéis flutuantes, os controles e os ícones Lucide já estabelecidos.

**Motor de raster usado:** [SrTristeSad/Ibis-Rebuild-Windows](https://github.com/SrTristeSad/Ibis-Rebuild-Windows/tree/migration/lua-only-engine), branch `migration/lua-only-engine`, PR #66 ainda em Draft, revisada no commit `739f82ccc88085e3699d1fd4fcecf1c1cd08d05f`.

Esta é uma integração **progressiva**, não uma cópia indiscriminada da aplicação visual antiga do Rebuild. Os projetos originais não foram substituídos. A interface visual continua sendo a do Ibis-Lua; não migramos os controles e menus que duplicariam seus componentes.

## Código reutilizado

Cópia dos módulos LuaJIT do rasterizador para `src/engine/`:

| Arquivo | Blob SHA original |
| --- | --- |
| `raster_lua.lua` | `a3376deb8edcb64fc34c8cfc41084c654b602821` |
| `raster_stroke.lua` | `db92845adac7497e93494f11207280fcc2acb64d` |
| `raster_tools.lua` | `7548f2ec0878e5884c9e2365e75a4d856bcc4017` |
| `raster_experimental.lua` | `fe9f78da07c961d8b6181231867a8a7787de6e6e` |

Os imports entre os quatro arquivos foram prefixados com `src.engine.`. O rasterizador continua **100% LuaJIT**, usando FFI somente para memória RGBA, sem carregar DLLs de pintura e sem arquivos proprietários do ibisPaint.

A integração é feita por `src/raster_bridge.lua`. O modelo `src/model.lua` continua responsável por estado dos botões e propriedades da interface. A ponte armazena buffers reais por ID de camada, usa o motor original para o traço, guarda snapshots limitados para undo/redo e compõe os pixels no modo **Normal**.

## Fluxo de desenho

1. O `main.lua` do Ibis-Lua mantém as transformações do canvas, inclusive zoom, rotação e pan.
2. Para Pincel/Borracha, mouse down/move/up converte coordenadas de janela para pixels do documento e envia o traço ao motor LuaJIT.
3. `Raster.accumulatedStroke` impede acúmulo artificial de opacidade ao repetir a ponta durante o mesmo gesto.
4. A textura RGBA é enviada ao LÖVE via `ImageData:getFFIPointer` e `Image:replacePixels`, usando a mesma técnica empregada no projeto Rebuild.
5. O dock original do Ibis-Lua oferece Desfazer/Refazer de pinceladas; Ctrl+Z e Ctrl+Shift+Z também atuam nesse histórico. Mudanças de visibilidade, opacidade e Alpha Lock da interface afetam a composição e o raster.

## Limites explícitos desta primeira etapa

- Dimensões raster reais: **1..2048** pixels por eixo. A interface visual ainda oferece tamanhos maiores, mas a pintura não é habilitada neles. Não cortar imagens silenciosamente.
- A espessura visual do Ibis-Lua pode exceder o limite do motor; no raster, é limitada a **256 px**.
- Composição real **Normal**; opções Multiply/Screen/Overlay continuam estados de UI, sem algoritmo equivalente.
- Histórico é **somente de pinceladas** e fica em memória, até 12 ações e 48 MiB.
- Ainda não foram conectados o armazenamento de projetos RBD2, galeria persistente, exportação/importação, balde, seleção por máscara, filtros, transformação, Windows Ink e demais funcionalidades avançadas do Rebuild.
- O modo `Solo` visual e a alteração de propriedades de camadas são preservados. O modo Solo atua na visibilidade usada pelo compositor quando renderizado.
- O layout e os arquivos de ícones do Ibis-Lua permanecem como estavam. O conteúdo de exemplo nas capturas dos estados anteriores permanece demonstrativo.

**Não afirmar que todas as funcionalidades do Rebuild já foram migradas.** A ponte funcional aqui descrita é a base para transferir os próximos subsistemas mantendo a interface escolhida pelo criador.

## Testes

- `luajit tests/test_raster_bridge.lua`: escrita real de pixels RGBA, borracha, undo/redo, camadas, opacidade, visibilidade, Alpha Lock e limites.
- `PAINT_LUA_RASTER_E2E=1 love .`: eventos de mouse reais no canvas e cliques de Undo/Redo no dock visual; teste do fluxo de borracha.
- `PAINT_LUA_SMOKE=1 PAINT_LUA_SCREEN=raster_painted love .`: captura `raster_painted.png` na CI.
- Workflows do GitHub continuam testando sintaxe LuaJIT, os módulos visuais, 35+ estados de screenshot e regressões de navegação.

Esses testes demonstram comportamento do nosso código, **não** semelhança pixel-a-pixel com o ibisPaint Windows original.

## Próximos incrementos de migração

Manter a mesma ponte e isolar novos subsistemas, na ordem técnica sugerida: persistência RBD2 e galeria; ferramenta Balde e Conta-gotas; integração do histórico estrutural de camadas; seleção por máscara; Windows Ink e estilos de pincel. Cada módulo precisa de testes de integração com a UI, antes de substituir controles simulados.

A PR desta integração deve permanecer em **Draft**, sem merge automático para `main`.
