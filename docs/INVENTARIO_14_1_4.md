# Inventário inicial — versão Windows 14.1.4

Legenda:
- **Confirmado 14.1.4** = comunicado específico da versão comprova a existência/alteração.
- **Evidência Windows sem versão** = captura real ou material de promoção da edição PC, ainda não validado na build alvo.
- **Pendente** = requer captura integral, estados e medidas antes de implementação.

| Interface/estado | Evidência disponível | Status visual 14.1.4 |
| --- | --- | --- |
| Tela inicial / título | R2 (promo), R5 (histórico) | Pendente |
| My Gallery e gerenciamento | R1 (sincronização), R6 (imagem antiga) | Parcial: alteração textual confirmada; geometria pendente |
| Novo Canvas / dimensões | R6 (terceiro) | Pendente |
| Editor e barras | R2, R3 | Evidência Windows sem versão; medidas pendentes |
| Pincel e opções | R3 | Evidência Windows sem versão; medidas/ícones pendentes |
| Borracha | R3 | Evidência Windows sem versão |
| Cor / seletor / paleta | R3 | Evidência Windows sem versão |
| Camadas e blending | R4, R6 | Pendente |
| Transformação / seleção | R3, R4 | Pendente |
| Preenchimento / filtros | R3, R4 | Pendente |
| Texto / formas / réguas | R3, R4 | Pendente |
| Materiais | R3 | Evidência Windows sem versão |
| Vetor | R3, R4 | Pendente |
| Animação / áudio / modo vídeo | R1 | Funcionalidades confirmadas, UI pendente |
| Configurações gerais / login | R1 | Alteração confirmada, geometria pendente |
| Menus contextuais e submenus | Sem série integral de capturas | Pendente |
| Pop-ups e botões de check | R1 | Alguns novos botões confirmados; localização pendente |
| Hover, disabled, loading | R1 (mudanças gerais) | Pendente |
| Iconografia ferramenta por ferramenta | R3 (visão parcial) | Pendente |

## Escopo do modelo Lua

O modelo puro em src/model.lua implementa **simulação de estado**, não renderização ou comprovação de comportamento oficial. Inclui navegação conceitual título -> galeria -> diálogo novo canvas -> editor, escolha de pincel/borracha, painéis básicos, cores, espessura e camadas demonstrativas. Os testes comprovam apenas o funcionamento deste modelo.

## Regra de passagem para UI

Nenhuma tela passa a 'concluída' enquanto não forem registrados:
versão exata; origem e licença das capturas; resolução; escala DPI; idioma; normal/hover/selecionado/disabled; medidas; captura renderizada pelo LÖVE; overlay/diff; desvios conhecidos.
