---
tipo: engenharia
status: observado
atualizado: 2026-10-19
---
# Arquitetura atual

## Estado observado

48 fontes de runtime conferidos com Studio em 19/10. Repositório local: `C:/Users/melg_/OneDrive/Documents/ChatGPT/Hunt A Creature`. Sem sync automático verificado. Recuperação e limites em [[Estado Atual]]. A [[Auditoria da Base Mecanica - 2026-10-17]] é histórica.

| Domínio | Módulos principais | Responsabilidade |
|---|---|---|
| Balanceamento | HACShared.GameplayConfig, CaptureConfig, CreatureProfiles | Definições, capacidades, preços, renda, alcance/carga, comportamentos |
| Dados | HACServer.ProfileData, ProfileService | Operações indivisíveis, revisão, serialização e posse de sessão/DataStore |
| Captura | HACServer.CaptureService, LassoCollision; HACShared.LassoAim | Validação da carga/mira, voo, colisão e disputa |
| Criaturas | CreatureFactory, CreatureBehaviorService, LumitoBehavior | Identidade/variação, modelos e IA limitada ao gramado |
| Ferramentas | HuntingTools, ToolInventory; cliente NativeInventory | Validar uso, projetar quantidades em Tools, seleção nativa |
| Mundo e treino | WorldPresentation, WorldStations, BaseRoamingService | Passeio independente da renda, treino, balcões e placas |
| Interfaces | HUD, CollectionUI, CreaturePage, ShopPage, IndexPage, SettingsPage, UpgradeBoards | Composição e ações contextuais, sem decidir recompensas |
| Estilo/feedback | VisualStyle, GlossyButton, HUDWidgets, ResourceHUD, CaptureHUD, UIEffects, AudioFeedback, NavGlyph, CreaturePortrait | Arte compartilhada, layout, efeitos e som |
| Integração | HuntACreature.server/client.luau | Ciclo, eventos, publicação de snapshots e validação de acesso |
| Preferências | LocalPreferences e ProfileData | Sound/BaseCreatures persistidos, efeitos apenas locais |
| Retratos | CatalogPresentation e CreaturePortrait | Modelos da criatura reaproveitados em ViewportFrame |

## Mapeamento

- `studio/shared/` → `ReplicatedStorage.HACShared`.
- `studio/server/` → `ServerScriptService.HACServer`.
- `studio/client/` → `StarterPlayer.StarterPlayerScripts.HACClient`.
- Bootstraps locais → `ServerScriptService.HuntACreature` e `StarterPlayer.StarterPlayerScripts.HuntACreatureClient`.
- Mapa, StarterPack e propriedades do lugar continuam no Studio. `BuildWorld.luau` local é histórico; não reconstruir a cena a partir dele.

## Contratos importantes

`CollectionAction` leva ação, ID e revisão; servidor valida perfil, tipos, cadência, estado, saldo/capacidade e contexto. Upgrade exige placa da própria base e proximidade; venda exige balcão; uso exige Tool realmente equipado. Equip/Unequip preservam o indivíduo e alteram somente localização/slot. Renda/treino não invalidam a revisão de ações.

Ferramentas positivas viram Tools uma vez; atualizações de renda não recriam objetos nem mudam a ordem da barra. Quantidade zero remove Tool. Laço inicial permanece em StarterPack. Não há persistência personalizada de ordem nem geração de futuros equipamentos permanentes além do laço existente.

UpgradeBoards descobre bases/peças/atributos progressivamente, sem bloquear eventos de menus. SurfaceGuis nas duas faces das placas ficam em PlayerGui, com Adornee na placa física, para receber input; distância/posse também são validadas no servidor. A aparência local não concede direitos de compra.

Favoritos e preferências entram por SetFavorite/SetSetting, com booleanos validados no servidor. Sell rejeita favorito. CaptureService e ProfileData validam MinimumStrength. Migração aditiva adiciona settings/variantDiscoveries; não renomeia IDs persistidos. Inglês afeta apresentação, Tool.Name e leaderstats.Gold com consumidores atualizados.

BaseRoamingService sincroniza pertencimento e mantém movimento independente; slots são capacidade lógica. LocalPreferences usa LocalTransparencyModifier e controle local de áudio. Ocultar nunca remove objetos no servidor nem altera renda.

## Limites e dívida conhecida

- `HuntACreature.server` ainda integra economia/treino/eventos; extrair domínio apenas quando houver trabalho concreto nele.
- `UpgradePage` permanece como módulo legado sem rota na interface; `QuickSlot` é apenas reserva invisível de layout. Não reativar acessos antigos por acidente.
- Nomes de objetos legados como `Esteira` permanecem para compatibilidade, embora a experiência seja manequim.
- IA usa modelos ancorados e varreduras/separação; não é navegação global em labirintos.
- Persistência existe, mas reconexão real/cotas entre servidores seguem pendentes de teste humano.
- Guia técnico e checklist: `studio/MENUS_INVENTARIO_2026-10-18.md`. [[ADR-001 - Fonte da verdade e sincronizacao]] rege alterações entre Studio/disco.
