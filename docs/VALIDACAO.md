# Relatorio de verificacao — base inicial

**Referencia:** ibisPaint for Windows 14.1.4 (28 October 2026).

## Testes executados

- **Lua 5.1 / LuaJIT:** syntax checks of all source files and state regression tests. [Workflow: Lua syntax and state tests](https://github.com/SrTristeSad/Ibis-Lua/actions/runs/41466216035).
- **LÖVE real sob Linux + Xvfb:** 7 scenes renderizadas com saida PNG em 1280x800: `title`, `gallery`, `newCanvas`, `editor`, `brush`, `layer`, `color`. [Workflow: screenshot smoke captures](https://github.com/SrTristeSad/Ibis-Lua/actions/runs/41466215965).

Os screenshots estao nos artifacts do workflow de capturas acima.

## Resultados

- Os fluxos de desenho da interface carregaram em ambiente virtualizado com LÖVE.
- A interface inicial recebeu correcao apos comparacao visual interna das capturas: icones dos tres botoes da tela inicial, nomes da barra lateral e controles da barra inferior do editor.
- **Nao foi testado em Windows neste ciclo.**
- **Nao houve homologacao visual 1:1** em comparacao a capturas da mesma versao, DPI e resolucao.
- Teste visual automatizado validou renderizacao inicial e gravacao de PNG, nao a fidelidade pixel a pixel.
- As outras janelas e telas ainda nao foram verificadas.

## Pendencias de validacao

1. Capturar a versao original Windows 14.1.4 em 1280x800 com DPI conhecido.
2. Comparar geometrias, tipografia, cores e icones por sobreposicao e diferenca de pixels.
3. Validar cliques, scroll, janelas flutuantes e atalhos no Windows real.
4. Completar inventario de telas secundarias, janela de conta, filtros, animacao, materiais e demais menus.
5. Substituir icones vetoriais provisórios por reconstrucoes fundamentadas em referencias autorizadas.

Nenhuma porcentagem de conclusao e atribuida neste relatorio.

## Iteracao de icones — 02/11/2026

- Adicionado `src/iconset.lua` com desenhos vetoriais proprios para as ferramentas,
  controles superiores e comandos de camadas; nao sao sprites extraidos do programa.
- Barra inferior separada em controles de tamanho/opacidade e barra de navegacao;
  botoes superiores com pictogramas no lugar de textos.
- Seletor de ferramentas em duas colunas e painel de camadas com faixa preta de icones.
- Painel Color com roda de matiz, losango HSB, paleta e controles HSB/RGB.
- Amostras de pinceis horizontais redesenhadas e ajustadas para o catalogo.
- Capturas do LÖVE (8 estados): https://github.com/SrTristeSad/Ibis-Lua/actions/runs/41467956187

**Importante:** os simbolos sao aproximacoes vetoriais baseadas em capturas oficiais,
e nao podem ser declarados identicos sem comparacao em resolucao equivalente.
A execucao real no Windows permanece pendente.
