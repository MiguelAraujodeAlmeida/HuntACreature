---
tipo: estado
status: aguardando_playtest
atualizado: 2026-10-19
---
# Estado atual

## Entrega vigente

[[Menus e Reset Global - 2026-10-19]] aplicada em Edit ao lugar **[Testing] Hunt a Creature**, placeId **102310424634629**. Próximo teste: [[Playtest Menus e Reset - 2026-10-19]]. Implementação não significa aprovação de diversão, estética ou persistência.

- Creatures, Creature Market, Creature Index, Hunting Shop e Settings refeitos com cabeçalho colorido, studs, Fredoka, X vermelho e componentes glossy.
- Galeria/ficha selecionada, retratos 3D, variantes/silhuetas, favoritos e ações contextuais. Loja com ilustrações de equipamentos; Settings com chaves animadas.
- Padrão reutilizável em MenuTheme/MenuKit/CreatureCards/ToolPortrait e `studio/MENU_STANDARD.md`. [[ADR-005 - Padrao de menus]].
- Reset de todas as contas nesta versão por geração fixa **20261019_menu_reset_01**. Ouro/XP/força, coleção, melhorias e descobertas recomeçam; equipamento inicial mantido. Progresso posterior persiste. Dados antigos não foram apagados. [[ADR-006 - Reset por geracao de saves]].
- **Não publicado**: servidores antigos seguem sua versão até receberem atualização. Reconexão real após o reset ainda precisa de teste.

## Sistemas preservados

Criaturas equipadas passeiam na base; Settings controla som e visibilidade local sem suspender renda. Inglês na apresentação, IDs internos estáveis. Força mínima por espécie (Lumito 0), favorito impede venda no servidor.

Upgrades pelas placas da própria base; treino imóvel no manequim; Equip/Unequip sem troca implícita; venda só no mercado físico. Inventário nativo com Tools possuídos. Ouro/XP a cada segundo, rendimento 5× já solicitado. Laço com precisão/alcance, IA do Lumito, isca, armadilha e poção permanecem integrados.

## Evidência e limites

48 fontes comparados antes, 53 finais idênticos e compilados. 21 checks isolados passaram. Prévia visual em Edit inspecionada para Shop, Index, Settings e mercado; componentes comuns também usados em Creatures. Previews removidos, waypoint criado. Play existente foi encerrado antes de editar; nenhum Play/emulação/benchmark iniciado.

Sem teste de DataStore real, reconexão, cliques remotos, som ou toque nesta rodada. Catálogo só contém Lumito. A aparência e o ritmo dependem do parecer do desenvolvedor.

Backup de fontes/cofre: `contexto/menus-2026-10-19/antes.zip`. Mapeamento: `map-final.json` no mesmo diretório. **Salvamento completo .rbxl/nuvem não confirmado**; código e cofre salvos não substituem cópia integral do lugar.

## Próxima ação

Executar [[Playtest Menus e Reset - 2026-10-19]], primeiro duas contas zeradas e reconexão com progresso novo; depois seleção, venda/favorito, compra e configurações. Regressão de placas/treino/captura conforme [[Playtest Base e Colecao - 2026-10-19]].

Mapa amplo/teletransporte, arte/modelos finais e catálogo maior continuam fora desta fatia. Documentos são mutáveis; feedback posterior prevalece.

Código: C:/Users/melg_/OneDrive/Documents/ChatGPT/Hunt A Creature/studio.
Sem sync automático verificado; comparar Studio/disco antes de editar. Play/QA pesado e agentes auxiliares só por pedido explícito.
