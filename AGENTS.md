# Hunt A Creature — instruções de trabalho

Jogo Roblox de longo prazo. Feedback recente do desenvolvedor prevalece sobre propostas antigas; documentos de produto são revisáveis.

## Contexto obrigatório

- **Cofre Obsidian:** `C:\Users\melg_\OneDrive\Documents\Hunt A Creature\Hunt A Creature`.
- **GitHub canônico do cofre:** https://github.com/MiguelAraujodeAlmeida/HuntaCreature-Obsidian
- **GitHub canônico do código:** https://github.com/MiguelAraujodeAlmeida/HuntACreature
- **Na primeira leitura de cada chat/IA/dispositivo:** ler README.md, AGENTS.md e o grupo `bootstrap` de `context-manifest.json`. Antes de alterar o projeto, identificar a tarefa e carregar somente os grupos de `domains` necessários: `ui_ux` para interface/arte, `gameplay` para mecânicas, `engineering` para arquitetura/persistência/Studio, `validation` para playtest e `decisions` para regra duradoura. Não carregar todos os domínios por padrão nem substituir a base por resumo de chat.
- Em outra máquina, localizar o clone real desse repositório. Não assumir este caminho Windows nem criar um cofre paralelo silenciosamente. Se não houver acesso, informar a lacuna.
- Nas continuações da mesma sessão, verificar revisão/hashes e ler alterações/domínios afetados. Histórico/modelos/relatórios são consulta complementar, não especificação vigente.

## Antes de editar o jogo

1. Consultar Estado Atual, Backlog, decisões e regras do domínio já lidos no conjunto vigente.
2. Atualizar o checkout pelo Git e trabalhar a partir do commit atual de `main`. O Git é a referência operacional dos fontes versionados.
3. Usar o Studio para aplicar e salvar alterações no lugar quando a tarefa exigir. Não executar comparações integrais ou rotineiras Studio ↔ disco; só investigar divergência concreta reportada pelo desenvolvedor ou falha de aplicação.
4. Preservar reversibilidade. Código, lugar salvo, aplicação no Studio e publicação são estados distintos.

## Ao implementar

- Manter servidor autoritativo para captura, recursos, inventário e progressão; validar entradas do cliente.
- Separar parâmetros, regras, input e apresentação. Alterar o domínio necessário, sem expandir monólitos.
- Preservar diversão, clareza, recompensa e PC/celular. Check técnico não aprova experiência.
- Fazer revisão/verificações leves. **Não iniciar Play, emulação, benchmarks ou QA extensivo sem pedido explícito.** Desenvolvedor testa manualmente.
- **Não usar agentes auxiliares sem pedido explícito.**
- Menus seguem a especificação portável `01_Produto/Design UI UX.md` do cofre e `studio/MENU_STANDARD.md`, com MenuTheme/MenuKit e componentes existentes. Registrar exceções; manter documentação e implementação alinhadas.

## Encerramento e memória — obrigatório em toda solicitação

- Atualizar a nota dona das regras alteradas, Estado Atual e Backlog; remover contradições e duplicações, não acumular versões concorrentes.
- Registrar a solicitação em `00_Inicio/Historico de Contexto.md`, com revisão, resultado, evidência, autoria/ambiente conhecidos e pendências. Decisão duradoura recebe ADR curta em Decisoes Vigentes.
- Seguir `03_Engenharia/Fluxo de Desenvolvimento.md`: atualizar manifesto, executar `python tools/check_context.py --refresh` e depois sem flag na raiz do cofre, revisar diff, commitar e sincronizar com GitHub; confirmar SHA remoto ou informar sincronização pendente. Não usar force push nem descartar trabalho de outra máquina.
- Se alterou jogo, salvar/verificar o lugar no Studio quando aplicável e registrar o commit enviado. Documentação/commit não substituem salvamento integral. Se alterou só documentação, não iniciar Studio por rotina.
- Manter o cofre sempre atual, enxuto e suficiente para continuidade independente do chat/dispositivo. Essa manutenção é parte da entrega, não opcional.

Fontes técnicas locais: `studio/README.md`, `studio/STYLE_GUIDE.md`, `studio/MENU_STANDARD.md`. O repositório do cofre não armazena o jogo completo.
