# Hunt A Creature — fontes do protótipo

Atualizado em 18/10/2026. Lugar **[Testing] Hunt a Creature**, placeId **102310424634629**. Última entrega: [menus, placas e inventário](MENUS_INVENTARIO_2026-10-18.md), aplicada em Edit e aguardando teste humano.

Correção posterior de interações aplicada: placas com descoberta tardia e duas faces; prompts do mercado/loja sem oclusão pelo balcão. [Checklist completo para reteste](CHECKLIST_ULTIMAS_ATUALIZACOES.md).

## Estado

- 37 fontes atuais recuperados do Studio após continuidade em outro dispositivo; baseline Git `7b2649a`.
- 42 fontes finais locais/Studio conferidos e compilados. Sincronização é **manual**, sem Script Sync/Rojo verificado.
- Jogo inclui captura, IA inicial do Lumito, perfil persistente, ferramentas, treino no manequim, cinco categorias de melhorias, Index e loja com cota individual.
- Revisão atual: upgrades por placas físicas, Criaturas com Equipar/Desequipar, mercado de venda, inventário nativo e renda por segundo (5×).
- Nenhum Play iniciado pelo assistente nesta revisão; experiência e persistência real aguardam validação específica do desenvolvedor.

## Organização

| Local | Destino no Studio | Responsabilidade |
|---|---|---|
| shared/ | ReplicatedStorage.HACShared | Configuração, geometria compartilhada, estilo e catálogos |
| server/ | ServerScriptService.HACServer | Captura, IA, perfil/persistência, recursos, ferramentas e mundo |
| client/ | StarterPlayer.StarterPlayerScripts.HACClient | Entrada, HUD, menus, placas e seleção de ferramentas |
| HuntACreature.server.luau | ServerScriptService.HuntACreature | Integração e validação de acesso |
| HuntACreature.client.luau | StarterPlayer.StarterPlayerScripts.HuntACreatureClient | Inicialização e snapshots |

Parâmetros: GameplayConfig, CaptureConfig, CreatureProfiles e VisualStyle em shared/. Guia de arte: [STYLE_GUIDE.md](STYLE_GUIDE.md).

UpgradePage é legado sem rota ativa. QuickSlot reserva espaço invisível para compatibilidade de layout; os slots visíveis pertencem ao Backpack nativo. O único laço implementado continua no StarterPack. Não ampliar código morto para criar novos acessos duplicados.

## Processo e reversibilidade

1. Ler Estado Atual/backlog no cofre `C:/Users/melg_/OneDrive/Documents/Hunt A Creature/Hunt A Creature`.
2. Comparar fontes atuais do Studio/disco antes de editar. Preservar a versão mais recente de cada domínio.
3. Separar configuração, regras autoritativas, input e apresentação; revisão/verificações leves, sem Play ou QA pesado autônomo.
4. Aplicar em Edit, conferir igualdade/diff, atualizar cofre e registrar commit. Desenvolvedor testa a experiência.

Backup anterior em `../contexto/retomada-2026-10-18/`: export dos 37 fontes, cópia dos arquivos locais antigos e notas do cofre. Clone anterior dos objetos em `ServerStorage.HACBeforeMenus20261018`. Fontes/clone interno não substituem lugar salvo; **salvamento completo .rbxl/nuvem não confirmado**.

BuildWorld.luau e archive/ contêm histórico. Não executar o construtor antigo sobre o cenário atual. Mapa, Tools e propriedades não estão integralmente representados no Git.

## Limites

Lumito é a amostra (tamanhos e Dourado), não catálogo final. Ponte permanece provisória; teletransporte/mapa amplo, arte/modelos finais e configurações de áudio estão adiados. Economia acelerada mantém preços anteriores. Persistência existe, mas teste real de reconexão/cotas não foi confirmado nesta rodada. Ordem da barra nativa não possui persistência personalizada.
