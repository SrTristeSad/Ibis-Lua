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
2. Para Pincel/Borracha, mouse down/move/up converte coordenadas de janela para pixels do documento e envia o traço ao motor LuaJIT. O Balde aplica flood-fill contíguo com tolerância inicial 0; o Conta-gotas amostra pixels opacos da composição visível.
3. `Raster.accumulatedStroke` impede acúmulo artificial de opacidade ao repetir a ponta durante o mesmo gesto.
4. A textura RGBA é enviada ao LÖVE via `ImageData:getFFIPointer` e `Image:replacePixels`, usando a mesma técnica empregada no projeto Rebuild.
5. O dock original do Ibis-Lua oferece Desfazer/Refazer de pinceladas; Ctrl+Z e Ctrl+Shift+Z também atuam nesse histórico. Mudanças de visibilidade, opacidade e Alpha Lock da interface afetam a composição e o raster.

## Limites explícitos desta primeira etapa

- Dimensões raster reais: **1..2048** pixels por eixo. A interface visual ainda oferece tamanhos maiores, mas a pintura não é habilitada neles. Não cortar imagens silenciosamente.
- A espessura visual do Ibis-Lua pode exceder o limite do motor; no raster, é limitada a **256 px**.
- Composição real **Normal**; opções Multiply/Screen/Overlay continuam estados de UI, sem algoritmo equivalente.
- Histórico cobre **pinceladas e preenchimentos** e fica em memória, até 12 ações e 48 MiB.
- RBD2 já salva e reabre obras raster; a **persistência completa da galeria visual** (pastas, movimento, ordem, miniaturas), exportação/importação, seleção por máscara, filtros, transformação, Windows Ink e demais funcionalidades avançadas do Rebuild ainda não foram conectados.
- O modo `Solo` visual e a alteração de propriedades de camadas são preservados. O modo Solo atua na visibilidade usada pelo compositor quando renderizado.
- O layout e os arquivos de ícones do Ibis-Lua permanecem como estavam. O conteúdo de exemplo nas capturas dos estados anteriores permanece demonstrativo.

**Não afirmar que todas as funcionalidades do Rebuild já foram migradas.** A ponte funcional aqui descrita é a base para transferir os próximos subsistemas mantendo a interface escolhida pelo criador.

## Testes

- `luajit tests/test_raster_bridge.lua`: escrita real de pixels RGBA, borracha, balde, conta-gotas, undo/redo, camadas, opacidade, visibilidade, Alpha Lock e limites.
- `PAINT_LUA_RASTER_E2E=1 love .`: eventos de mouse reais no canvas e cliques de Undo/Redo no dock visual; teste do fluxo de borracha.
- `PAINT_LUA_SMOKE=1 PAINT_LUA_SCREEN=raster_painted love .`: captura `raster_painted.png` na CI.
- Workflows do GitHub continuam testando sintaxe LuaJIT, os módulos visuais, 35+ estados de screenshot e regressões de navegação.

Esses testes demonstram comportamento do nosso código, **não** semelhança pixel-a-pixel com o ibisPaint Windows original.

## A56 — Persistência RBD2 inicial, sem trocar o visual

Esta branch passou a reutilizar o **Store RBD2 original** do Rebuild,
em `src/engine/store.lua`, junto de seu codec JSON limitado e
metadados de retenção. O arquivo resultante usa o mesmo cabeçalho
`RBD2\\r\\n\\x1A\\n`, cabeçalho JSON e bytes RGBA por camada.
Não é JSON proprietário paralelo e não é formato `.ipv`.

O sistema de arquivos `src/engine/love_fs.lua` implementa a
interface necessária ao Store dentro do diretório de dados do LÖVE.
Seu `writeAtomic` grava primeiro num arquivo temporário e utiliza
rename atômico no Linux ou `MoveFileExW` no Windows, sem apagar a
versão anterior se a substituição falhar. Nenhuma pasta fora da área
de dados do aplicativo é gerenciada. Os dados residem sob
`<LOVE save directory>/rbd2-projects/projects/*.rbd`.

O adaptador `src/project_persistence.lua` converte os IDs numéricos
da UI para IDs persistentes de projeto e camada do Store. Salva
nome, dimensões, ordem, seleção, visibilidade, opacidade, Alpha Lock
e bytes RGBA. Abre projetos antigos RBD1 em memória sem alterar seu
arquivo até um salvamento posterior. Ao criar um projeto já pintado, usa a extensão `Store:createLayeredProject` para publicá-lo diretamente como RBD2 com **uma única escrita atômica**, sem gerar um RBD1 vazio intermediário. A validação prévia também rejeita projetos acima de oito camadas ou do orçamento de arquivo de 64 MiB. Rejeita salvar camadas com
blending não Normal, impedindo perda silenciosa de dados não suportados.

**Fluxo da UI:** um novo desenho no canvas de até 2048x2048 px é
salvo ao usar **Back to My Gallery**, `Ctrl+S` ou fechamento normal
com o editor aberto. Se ocorrer falha de I/O, o retorno à galeria ou
o encerramento são cancelados para preservar os pixels em memória.
Ao iniciar, os RBD2 existentes na raiz reaparecem como cartões
da galeria visual; ao clicar, recuperam a obra, suas camadas e pixels.

**Limites deliberados nesta fase:**
- Pastas, ordem, miniaturas e movimentos da galeria visual continuam
  demonstrativos e **não são persistidos** pelo modelo atual; projetos
  salvos reaparecem na raiz após reinício.
- Undo/redo permanece um histórico de sessão; não é persistido em RBD2.
- Projetos acima do limite do motor (2048 por eixo) seguem
  visuais, sem salvamento de pixels reais.
- O Store original limita a escrita individual a 64 MiB; arquivos
  acima desse tamanho causam erro visível de salvamento, não
  truncamento silencioso.
- Não há importação/exportação do formato oficial do ibisPaint,
  sincronização em nuvem ou persistência de modo Solo/Clipping.
- O modelo visual ainda pode habilitar operações de mesclagem
  simuladas; o salvamento recusa modos diferentes de Normal.

**Verificação:** `PAINT_LUA_PERSISTENCE_E2E=write love .` seguido de
`PAINT_LUA_PERSISTENCE_E2E=read love .` em **processos separados**.
O teste confirma assinatura RBD2, reabertura a partir do cartão,
duas camadas pintadas, opacidade e Alpha Lock, além de execução dos
testes anteriores do projeto.

## Próximos incrementos de migração

Manter a mesma ponte e isolar novos subsistemas, na ordem técnica sugerida: persistência RBD2 e galeria; integração do histórico estrutural de camadas; seleção por máscara; Windows Ink e estilos de pincel. Cada módulo precisa de testes de integração com a UI, antes de substituir controles simulados.

A PR desta integração deve permanecer em **Draft**, sem merge automático para `main`.
