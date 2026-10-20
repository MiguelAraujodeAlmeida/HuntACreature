# Hunt A Creature — fontes do protótipo

Atualizado em 19/10/2026. Lugar **[Testing] Hunt a Creature**, placeId **102310424634629**. Última entrega: [menus e reset global](MENUS_RESET_2026-10-19.md). [Checklist do playtest](CHECKLIST_MENUS_RESET_2026-10-19.md). [Padrão de menus](MENU_STANDARD.md).

## Estado

- 53 fontes de runtime conferidos/compilados. Sincronização manual; sem Script Sync/Rojo verificado.
- Base viva, Settings, favoritos protegidos, inglês nativo, Tools/Lassos e Index visual por variantes implementados.
- Captura, treino, inventário, renda por segundo e placas da revisão anterior preservados.
- Menus ativos refeitos com MenuTheme/MenuKit, galerias, detalhes e arte de equipamentos. 21 verificações isoladas passaram nesta rodada; prévias visuais em Edit inspecionadas. Nenhum Play iniciado; experiência e persistência real pendentes.
- Reset global por geração fixa `20261019_menu_reset_01` em PersistenceConfig. Todas as contas começam novas nesta versão; progresso posterior persiste. Dados antigos preservados; nenhuma publicação feita.

## Organização

| Local | Destino no Studio | Responsabilidade |
|---|---|---|
| shared/ | ReplicatedStorage.HACShared | Configuração, geometria compartilhada, estilo e catálogos |
| server/ | ServerScriptService.HACServer | Captura, IA, perfil/persistência, recursos, ferramentas e mundo |
| client/ | StarterPlayer.StarterPlayerScripts.HACClient | Entrada, HUD, menus, placas e seleção de ferramentas |
| HuntACreature.server.luau | ServerScriptService.HuntACreature | Integração e validação de acesso |
| HuntACreature.client.luau | StarterPlayer.StarterPlayerScripts.HuntACreatureClient | Inicialização e snapshots |

Parâmetros: GameplayConfig, CaptureConfig, VisualStyle e MenuTheme em shared/; CreatureProfiles e PersistenceConfig em server/. Guia de arte: [STYLE_GUIDE.md](STYLE_GUIDE.md).

UpgradePage é legado sem rota ativa. QuickSlot reserva espaço invisível para compatibilidade de layout; os slots visíveis pertencem ao Backpack nativo. O único laço implementado continua no StarterPack. Não ampliar código morto para criar novos acessos duplicados.

## Processo e reversibilidade

1. Na primeira leitura, absorver todo o conjunto vigente do manifesto do cofre `C:/Users/melg_/OneDrive/Documents/Hunt A Creature/Hunt A Creature`, conforme AGENTS.md. Nas continuações, consultar alterações e domínios afetados.
2. Comparar fontes atuais do Studio/disco antes de editar. Preservar a versão mais recente de cada domínio.
3. Separar configuração, regras autoritativas, input e apresentação; revisão/verificações leves, sem Play ou QA pesado autônomo.
4. Aplicar em Edit, conferir igualdade/diff, atualizar cofre e registrar commit. Desenvolvedor testa a experiência.

Backup anterior em `../contexto/retomada-2026-10-18/`: export dos 37 fontes, cópia dos arquivos locais antigos e notas do cofre. Clone anterior dos objetos em `ServerStorage.HACBeforeMenus20261018`. Fontes/clone interno não substituem lugar salvo; **salvamento completo .rbxl/nuvem não confirmado**.

BuildWorld.luau e archive/ contêm histórico. Não executar o construtor antigo sobre o cenário atual. Mapa, Tools e propriedades não estão integralmente representados no Git.

## Domínios novos

BaseRoamingService move visuais equipados sem tocar em renda. CatalogPresentation exporta retratos a partir dos modelos; CreaturePortrait os apresenta. SettingsPage e LocalPreferences isolam preferências. GameplayConfig guarda MinimumStrength (Lumito 0), Settings e BaseRoaming. ProfileData persiste favorito/settings/variantDiscoveries por migração aditiva sem reset de schema/IDs.

Backup atual: contexto/evolucao-2026-10-19/antes.zip e ServerStorage.HACBeforeEvolution20261019. Objetos alterados em Edit: nomes visíveis, Training Lasso, pedestais ocultos/inertes, catálogo de retratos. Salvamento completo do lugar continua não confirmado.

## Limites

Lumito é a amostra (tamanhos e Dourado), não catálogo final. Ponte permanece provisória; teletransporte/mapa amplo, arte/modelos finais estão adiados. Economia acelerada mantém preços anteriores. Persistência existe, mas teste real de reconexão/cotas não foi confirmado nesta rodada. Ordem da barra nativa não possui persistência personalizada.

## Entrega de menus

MenuTheme define tokens; MenuKit estrutura e feedback; CreatureCards/CreaturePortrait compõem retratos; ToolPortrait cria arte decorativa dos consumíveis. CollectionUI coordena dados e navegação. Novas telas seguem MENU_STANDARD.md. Backup anterior da rodada em contexto/menus-2026-10-19/antes.zip; mapa dos 53 fontes em map-final.json no mesmo diretório. Salvamento completo do lugar continua não confirmado.

## Contexto portável

Repositório canônico: https://github.com/MiguelAraujodeAlmeida/HuntaCreature-Obsidian. O manifesto define a leitura vigente; Histórico de Contexto registra solicitações entre IAs/dispositivos. Atualizar e sincronizar o cofre em toda entrega conforme AGENTS.md. O clone de contexto não substitui este código nem o lugar salvo.
