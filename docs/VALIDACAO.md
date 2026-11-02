# Protocolo de validação visual

## O que foi executado nesta etapa (incluindo a etapa de gestos e Solo)

- Pesquisa em páginas oficiais e fotografias/screenshots do Windows com limites de versão registrados.
- Reconstrução do projeto técnico do zero, sem reciclar os desenhos, componentes e layouts antigos.
- Ferramenta nova para comparação de imagens e suite de testes sintéticos.
- Pipeline de CI para sintaxe e modelo Lua, testes Python e inicialização LÖVE/Xvfb.
- Interface inicial experimental já substituiu o diagnóstico: título, My Gallery, novo canvas e estrutura de editor, com navegação visual. A referência geométrica é limitada e histórica; **não** houve inspeção do ibisPaint Windows 14.1.4 nem comparação pixel a pixel de uma tela reconstruída com uma captura real da versão.

## Procedimento obrigatório por tela

1. Capturar no ibisPaint oficial Windows **14.1.4** e registrar data, origem, idioma, resolução e escala.
2. Arquivar a referência conforme direitos de acesso/licença; no repositório, registrar somente metadados e URL autorizada.
3. Documentar geometria, cores, fontes, ícones e estados de interação.
4. Implementar em Lua e executar no LÖVE 11.5 na mesma resolução e escala.
5. Capturar a reconstrução; comparar: python tools/compare_screenshots.py --reference ref.png --actual actual.png --output-dir comparison_output
6. Revisar overlay.png, difference.png e metrics.json e identificar discrepâncias.
7. Repetir e registrar valores medidos (sem alegar 100% por inferência).
8. Separar testes de comportamento de testes de fidelidade, e exigir ambos.

## Critérios

- Teste de lógica **aprovado** não significa UI fiel.
- Teste de screenshot **executado** não significa equivalência.
- A métrica é apenas diagnóstico; capturas de versões diferentes não podem fundamentar aprovação.
- Não existe porcentagem de conclusão sem auditoria por tela e por estado.
- Não copiar e distribuir recursos protegidos da aplicação sem autorização.
- Nenhuma UI real da versão-alvo foi aprovada nesta etapa.

## Verificações adicionais da etapa de interação

- Executar `luajit tests/test_viewport.lua`: valida zoom ancorado, limites, rotação, pan e reset, sem motor de pintura.
- Executar `luajit tests/test_layer_solo.lua`: valida isolamento, troca de camada Solo, restauração das visibilidades anteriores e interação com adicionar camada.
- GitHub Actions gera nove screenshots: title, gallery, new_canvas, editor, layer, brush, color, zoom e solo.
- **Limite**: não foram medidos desvios em pixels contra screenshot do Windows 14.1.4; resultados de smoke não devem ser apresentados como prova de fidelidade.

## Integração de interface real no LÖVE

- `IBIS_LUA_E2E=1 love .` exercita callbacks de mouse e teclado sem acesso ao motor de pintura.
- Verifica galeria, popup New Canvas, incremento de largura, troca de foco, criação de tela com dimensões digitadas, abertura do painel Layer, alteração de visibilidade e zoom.
- Regressões nessa navegação agora devem derrubar o workflow de CI. Isso é um teste de comportamento, não de semelhança geométrica com o ibisPaint.

## View Menu — validação funcional (02/11/2026)

- Módulo testado: `luajit tests/test_view_state.lua`, cobrindo toggles, intervalos, cores demonstrativas, interpolação explícita e reset.
- Integração `IBIS_LUA_E2E=1 love .`: após criar canvas e abrir Layer, abre View Menu, alterna Grid e Reference Window, escolhe Pixelated, abre Grid Settings, incrementa Grid 1 Interval e testa Reset.
- Pipeline: 13 capturas de estados de UI, ainda em Linux/Xvfb; **não constituem provas de correspondência de pixels com o aplicativo Windows original**.

## Layer Window — testes e limites da etapa

- `luajit tests/test_layer_properties.lua`: operações de dados para opacidade, blending, clipping, alpha lock, lock, rename e modos de fundo; recusa valores inválidos.
- `IBIS_LUA_E2E=1 love .`: testes adicionais por clique real nos controles do painel de camada.
- GitHub Actions salva capturas de 16 estados, incluindo popup de modos de mesclagem e representação de fundo transparente.
- Nenhuma imagem original do Windows 14.1.4 foi comparada pixel a pixel. Aprovado em CI não significa layout equivalente ou efeitos reais implementados.

## Interação da janela Layer flutuante

- Teste E2E: pressiona a alça de tamanho no canto inferior direito, arrasta e solta; valida mudança real da largura e altura da janela.
- Captura adicional de janela deslocada e redimensionada: `layer_floating.png`.
- O workflow gera **17 screenshots**, não métricas de equivalência com o original.

## New Canvas — verificação por conteúdo e por resolução

- `luajit tests/test_canvas_presets.lua` valida os 13 presets transcritos da captura Windows, cópias defensivas, escalonamento por DPI e rejeição de dados inválidos.
- A suíte de cliques `IBIS_LUA_E2E=1 love .` verifica preset A4, DPI de 150 para 300, edição dos campos numéricos e criação do documento simulado.
- O CI executa também `IBIS_LUA_E2E=1 IBIS_LUA_E2E_RES=1600x900 love .` em Xvfb com resolução ajustada; isso verifica navegação e evita regressões em janelas largas, **não** fidelidade visual.
- O workflow gera **18 capturas** e inclui o estado `new_canvas_dpi`.
