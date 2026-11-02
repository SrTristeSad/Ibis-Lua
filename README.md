# Ibis-Lua — casca visual em Lua

Protótipo **exclusivamente de interface** para Windows, desenvolvido em **Lua + LÖVE 11.5**, usando como alvo visual o ibisPaint X Android 14.1.2. Não é um editor de imagens e **não contém motor de pintura**.

## Executar

1. Instale [LÖVE 11.5](https://love2d.org/).
2. **Windows:** dê dois cliques em `testar.bat` na raiz do repositório. O script encontra `love.exe` na pasta do projeto, em instalações comuns do Windows ou no `PATH` e abre a casca visual. Se não encontrar, informa como instalar. Opcionalmente, defina a variável de ambiente `LOVE_EXE` com o caminho completo do executável.
3. Alternativa pelo terminal: `love .` (ou arraste a pasta do projeto sobre `love.exe`).
4. Selecione **Minha Galeria**, clique em **+**, escolha uma dimensão e confirme. Isso cria apenas uma tela demonstrativa em memória.

**Observação:** `testar.bat` abre a interface para inspeção manual; não executa os testes Lua automaticamente e não adiciona motor de desenho.

## O que funciona visualmente

- Entrada com identidade visual, galeria e diálogo para nova tela.
- Editor cinza com papel central, 15 ferramentas na lateral (esquerda, direita ou popup), seis botões superiores, dois sliders e nove comandos na barra inferior.
- Seletor de ferramentas (1, 2 ou 3 colunas), painel de pincéis, janela de cores HSB/paleta, janela de camadas, menu de mesclagem e configurações.
- Cliques, seleção, visibilidade/duplicação/exclusão visual de camadas e navegação entre as telas.
- Zoom via roda do mouse, deslocamento da folha com botão direito, `Esc` para voltar, `Tab` para tela cheia, `T` ferramentas, `L` camadas, `C` cores, `B` pincel, `E` borracha.

## Teste visual e capturas

Execute `testar.bat` no Windows. Na tela inicial, abra **Minha Galeria**, crie uma tela com **+** e use a barra inferior para abrir as janelas de pincéis, cor e camadas.

Pressione **F12** em qualquer tela para gerar uma captura PNG da interface renderizada. O arquivo é gravado na pasta de salvamento do LÖVE, geralmente `%APPDATA%\LOVE\ibis-lua-visual-shell` no Windows. O caminho completo também aparece no console.

A comparação com a versão Android 14.1.2 deve ser feita com capturas da mesma tela e proporção. Os testes do GitHub verificam sintaxe, geometria, interações e a validade de algumas chamadas gráficas simuladas, **mas não atestam equivalência pixel a pixel nem substituem um teste em LÖVE real**.

### Ajustes de interface 14.x

- Biblioteca de pincéis com barra vertical de categorias, amostras de traço, pesquisa e rolagem; o catálogo é demonstrativo, sem engine.
- Janela de cores com roda HSB, losango central, barras HSB/RGB, paletas e histórico demonstrativo.
- Janela Nova tela com dimensões e tamanhos predefinidos; camadas e galeria continuam estados temporários.
- Teste de regressão `tests/test_visual_flow.lua` incluído no GitHub Actions.

## Fora de escopo

Sem rasterizador, motor de pincéis, pintura, filtros reais, exportação, arquivos `.ipv`, vídeo de timelapse, contas online ou salvamento de obras. Estados da interface são **temporários** e não devem ser confundidos com resultados editáveis.

## Referências da interface

- [03. Barra de Ferramentas e Seleção](https://ibispaint.com/lecture/index.jsp?lang=pt&no=04)
- [10. Janela de Cor](https://ibispaint.com/lecture/index.jsp?lang=pt&no=11)
- [Detalhes da Janela de Camadas](https://ibispaint.com/lecture/index.jsp?no=156)
- [20. Galeria](https://ibispaint.com/lecture/index.jsp?lang=pt&no=20)

**Precisão:** a estrutura visual e a ordem de ferramentas foram reconstruídas a partir das referências públicas. **A fidelidade pixel a pixel 1:1 à compilação Android 14.1.2 ainda não foi certificada**; isso exige confrontar cada tela com capturas exatas da versão-alvo na mesma proporção, resolução e densidade. Ícones e geometria são originais, sem redistribuir arquivos do APK. Projeto independente, sem vínculo com a ibis inc.

## Organização

- `main.lua`: estados visuais e navegação.
- `src/layout.lua`: geometria relativa, sem dependência do motor de desenho.
- `src/ui.lua`: controles e áreas interativas.
- `src/icons.lua`: ícones vetoriais independentes.
- `tests/test_layout.lua`: verificação de geometria e das listas de comandos.
