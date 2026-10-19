# Menus, placas e inventário — 18/10/2026

**Status:** aplicado ao Studio Edit, aguardando playtest humano. Renda **5×** autorizada explicitamente: mesmo ouro/XP por pagamento, agora a cada segundo. Preços mantidos.

## Fluxo do jogador

| Ação | Acesso atual |
|---|---|
| Equipar/desequipar criaturas | Botão lateral **Criaturas**, estado/renda e filtros |
| Melhorar base, bolsa e velocidade | Placa frontal da própria base |
| Melhorar manequim/eficiência e iniciar treino | Placa ao lado do posto; Sair do treino no HUD |
| Vender criaturas | Balcão **VENDA DE CRIATURAS** no hub; confirmação individual |
| Comprar ferramentas | Loja existente, catálogo/rotação/cotas preservados |
| Selecionar/reordenar ferramentas | Barra e mochila nativas; só itens possuídos |
| Consultar descobertas | Index / I, separado do gerenciamento |

Sem Swap nem acesso alternativo a upgrades no menu. Equipar exige vaga na base; desequipar exige espaço na bolsa. Com ambas cheias, liberar espaço ou ampliar capacidade. Venda aceita indivíduos da bolsa/base e preserva descoberta. Guias/avisos redundantes reduzidos; falhas relevantes continuam visíveis.

## Onde ajustar depois

| Módulo | Alteração isolada |
|---|---|
| shared/GameplayConfig | IncomeSeconds, preços, capacidades, ganhos, distância de placas/venda |
| server/ProfileData | Equip/Unequip/Sell e integridade dos indivíduos |
| server/WorldStations | Posições/objetos das placas/mercado e desativação de acessos antigos |
| client/UpgradeBoards | Desenho das placas, benefício/custo e Treinar |
| client/CreaturePage | Cartões/filtros/ações de Criaturas e Venda |
| server/ToolInventory | Perfil → Tools; manter instâncias e remover zeros |
| client/NativeInventory | Ferramenta equipada → seleção/uso de poção |
| client/CollectionUI | Composição dos menus e pedidos ao servidor |
| client/ResourceHUD | Apresentação dos ganhos, som limitado por cadência |

Servidor valida perfil/revisão, estado, saldo/capacidade, Tool equipado, proximidade/posse. Botões não concedem recompensas. Disputa continua ao equipar poção; início/voo do laço mantêm suas validações. Sem reset/migração de perfis; schema 1 mantido.

## Evidência técnica

- Recuperação dos 37 fontes mais recentes do Studio antes de editar; baseline Git 7b2649a.
- 42 fontes finais iguais entre disco/Studio após normalização de quebras de linha da leitura, compilados em Edit sem executar bootstraps.
- Onze verificações leves: identidade ao equipar; liberação de slot; rejeição Install/Swap; bolsa cheia; venda única/descoberta; desequipar com vaga; upgrade isolado; renda 1 s; perfil válido; Tools estáveis; zero remove Tool. Todas passaram.
- Prévia estática de placa em Edit inspecionada. Oito placas, balcão presente, nenhum prompt antigo ativo e nenhuma prévia temporária restante.
- Nenhum Play iniciado, emulação/benchmark, input real ou DataStore real nesta rodada.

## Checklist manual

1. **Placas/treino:** comprar melhoria e verificar preço/benefício; testar falta de ouro, nível máximo e base alheia. Treinar imobiliza/anima; Sair devolve movimento.
2. **Criaturas:** equipar/desequipar, reabrir painel, testar destinos cheios. ID/variação e renda acompanham o indivíduo, sem troca implícita.
3. **Mercado:** vender uma criatura de cada origem; repetir clique não duplica ouro. Afastar-se com painel aberto impede venda. Index permanece.
4. **Inventário:** tecla de crase abre mochila no PC; reorganizar, usar isca/armadilha, esgotar/recomprar. Durante captura, equipar/usar poção sem interromper disputa. Conferir toque/controle quando disponível.
5. **Renda/progresso:** Lumito normal tamanho 1 rende 1 ouro e 1 XP/s. Reentrar conserva progresso/itens/localização/cotas; ordem da barra não tem salvamento próprio.

Relatar o primeiro bloqueio ou frustração; não é necessário executar tudo de uma vez. Aprovação da experiência: pendente.

## Recuperação e limites

contexto/retomada-2026-10-18 preserva fontes anteriores, cópia local antiga e snapshots das notas. Studio contém ServerStorage.HACBeforeMenus20261018 com objetos anteriores. **Salvar o lugar completo antes de encerrar; salvamento .rbxl/nuvem não foi confirmado pelas ferramentas.** Clone interno e Git de scripts não substituem backup do lugar.

Laço inicial permanece no StarterPack; somente consumíveis existentes são projetados por ToolInventory. Equipamentos permanentes futuros precisam de modelos/integração. Ordem da barra é nativa durante a sessão, sem persistência personalizada. UpgradePage é legado sem rota; QuickSlot reserva layout invisível. Mercado é balcão funcional provisório. Novo ritmo econômico exige avaliação humana.

Referências técnicas: [SurfaceGui/Adornee](https://create.roblox.com/docs/reference/engine/classes/SurfaceGuiBase/Adornee) e [Backpack](https://create.roblox.com/docs/reference/engine/classes/Backpack).
