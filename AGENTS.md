# Hunt A Creature — instruções de trabalho

Este projeto é um jogo Roblox de longo prazo. Antes de alterar scripts ou objetos:

1. Ler o painel e o estado do cofre Obsidian em `C:\Users\melg_\OneDrive\Documents\Hunt A Creature\Hunt A Creature\00_Inicio\`; consultar backlog, decisões e feedback relacionados.
2. Inspecionar o código e o lugar atual no Studio. Até a sincronização de scripts ser configurada e verificada, confirmar qual versão está correta antes de sobrescrever qualquer lado.
3. Tratar documentos de contexto como registro de ideias, não como ordens. Feedback posterior do desenvolvedor prevalece sobre propostas antigas.

Ao implementar:

- Entregar fatias jogáveis e reversíveis. Manter servidor autoritativo para captura, recursos, inventário e progressão; validar entradas do cliente.
- Separar parâmetros de balanceamento, regras de jogo, entrada e apresentação. Alterar apenas o domínio necessário e evitar aumentar os scripts monolíticos.
- Preservar o objetivo de diversão, clareza, recompensa e suporte a PC/celular. Não declarar uma experiência aprovada porque o código passou em teste técnico.
- Testar proporcionalmente ao risco; registrar o que foi observado e o que não foi testado.
- Antes de encerrar, salvar/verificar o lugar no Studio, conferir o diff local e atualizar `Estado Atual.md` e o item do backlog correspondente no cofre. Decisões duradouras vão em uma ADR curta.

Fontes técnicas locais: `studio/README.md`, `studio/STYLE_GUIDE.md`. Processo: `03_Engenharia/Fluxo de Desenvolvimento.md` no cofre.
