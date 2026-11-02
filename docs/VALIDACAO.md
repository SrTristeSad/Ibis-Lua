# Protocolo de validação visual

## O que foi executado nesta etapa

- Pesquisa em páginas oficiais e fotografias/screenshots do Windows com limites de versão registrados.
- Reconstrução do projeto técnico do zero, sem reciclar os desenhos, componentes e layouts antigos.
- Ferramenta nova para comparação de imagens e suite de testes sintéticos.
- Pipeline de CI para sintaxe e modelo Lua, testes Python e inicialização LÖVE/Xvfb.
- **Não** houve inspeção presencial do ibisPaint Windows 14.1.4 nem comparação de uma tela reconstruída contra uma captura real da versão.

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
