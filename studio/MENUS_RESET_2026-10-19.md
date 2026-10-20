# Menus e reset global — 19/10/2026

## Entregue

- Cinco menus ativos refeitos: Creatures, Creature Market, Creature Index, Hunting Shop e Settings.
- Estrutura compartilhada com cabeçalho, studs, bordas, X vermelho, Fredoka One, estados e botões glossy.
- Galeria + detalhe selecionado no desktop; composição empilhada em largura reduzida.
- Criaturas: retrato, capacidade, renda, Equip/Unequip e favorito. Mercado: seleção, proteção de favorito, confirmação e cancelamento de venda.
- Index: variantes, raridade, progresso, silhuetas, ficha de renda/XP/força mínima. Apenas catálogo real (Lumito); sem recompensas inventadas.
- Loja: Tools/Lassos, arte de isca/armadilha/poção e laço, estoque e compra. Regras de saldo, proximidade, capacidade e cota preservadas.
- Settings: controles ON/OFF grandes para Sound/Base creatures, resposta animada com confirmação autoritativa.
- Padrão para futuras telas: MENU_STANDARD.md, MenuTheme, MenuKit, CreatureCards e ToolPortrait.

## Reset solicitado

PersistenceConfig.Generation = `20261019_menu_reset_01`.

| Ambiente | Novo DataStore | Anterior |
|---|---|---|
| Studio | HAC_Profiles_Studio_20261019_menu_reset_01 | HAC_Profiles_Studio_v1 |
| Servidores publicados | HAC_Profiles_20261019_menu_reset_01 | HAC_Profiles_v1 |

Toda conta que carregar **esta versão** começa no novo armazenamento, com ouro/XP/força, criaturas, melhorias e descobertas zerados. Laço e consumíveis iniciais são mantidos conforme Data.New; preferências começam ligadas.

A geração é constante: progresso obtido depois do reset persiste nas próximas entradas. Dados antigos não foram apagados fisicamente e podem ser recuperados deliberadamente. Falha de leitura continua impedindo entrada; não gera reset silencioso. Schema/IDs internos permanecem estáveis.

A implementação foi aplicada em Edit. **Não houve publicação**: servidores já publicados ou antigos continuam usando sua versão anterior até receberem a atualização. Nenhum DataStore real foi lido/escrito pelo assistente para testar o reset. Validar duas contas e reconexão.

## Verificação

- 48 fontes locais/Studio comparados antes das alterações; backup em contexto/menus-2026-10-19/antes.zip.
- 53 fontes finais idênticos e compilados (incluindo os dois bootstraps).
- 21 checks isolados em Edit passaram: namespace, perfil inicial, equipamentos, preferências, construção de cinco menus, proteção de favorito, variante desconhecida e composição estreita.
- Prévia visual nativa em Edit inspecionada: Shop, Index, Settings e Creature Market (mesmos componentes de Creatures). Dados fictícios somente na memória da prévia; removidos ao terminar.
- Correções da prévia: área de compra, tamanho das ilustrações/textura e borda de seleção única.
- A execução Play encontrada aberta foi encerrada antes de editar; nenhum Play foi iniciado, nenhuma emulação/benchmark foi executada.
- Não foram validados fluxo real de cliques remotos, toque, som, reconexão ou UX pelo jogador.
- Studio em Edit e prévias removidas; waypoint criado. Tentativa de “Baixar uma cópia” não confirmou arquivo completo. **Salvamento .rbxl/nuvem ainda não confirmado**; backup de fontes não substitui o lugar.

## Reversão

Os scripts anteriores estão no commit 4c381d9 e no ZIP. Para reverter apenas a aparência, restaurar páginas/CollectionUI e seus componentes sem alterar PersistenceConfig. Para recuperar saves anteriores, decidir explicitamente o DataStore de origem; não trocar geração durante sessão ativa nem descartar o progresso novo por acidente.

Roteiro humano: CHECKLIST_MENUS_RESET_2026-10-19.md.
