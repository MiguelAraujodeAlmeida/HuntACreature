---
tipo: decisao
status: vigente_revisavel
atualizado: 2026-10-19
---
# ADR-006 - Reset por geracao de saves

## Contexto

Pedido explícito: reiniciar progresso salvo de todas as contas para testes. Não houve pedido de eliminação física irrecuperável dos dados anteriores.

## Decisão

PersistenceConfig seleciona geração constante `20261019_menu_reset_01`, separada entre Studio e servidores publicados:
- Studio: `HAC_Profiles_Studio_20261019_menu_reset_01`.
- Publicado: `HAC_Profiles_20261019_menu_reset_01`.

ProfileService mantém lease/validação/autosave e carrega Data.New quando a chave não existe nessa geração. Toda conta começa novamente ao entrar na versão atualizada. A geração não muda por execução, data ou erro de leitura. Progresso obtido depois do reset persiste.

Stores anteriores `HAC_Profiles_Studio_v1` e `HAC_Profiles_v1` permanecem separados para recuperação. Schema/IDs não mudaram. Esta decisão substitui apenas a escolha de DataStore da ADR-004; demais regras permanecem.

## Consequências

Reset não exige enumerar/deletar contas. Dados antigos não foram apagados fisicamente. Recuperação exige selecionar conscientemente o store antigo, considerando progresso novo e sessões ativas.

Mudança aplicada no Studio, não publicada. Servidores antigos seguem sua geração até atualização. Dois usuários + reconexão são aceite humano obrigatório; teste isolado não confirma DataStore real.

[[Playtest Menus e Reset - 2026-10-19]].
