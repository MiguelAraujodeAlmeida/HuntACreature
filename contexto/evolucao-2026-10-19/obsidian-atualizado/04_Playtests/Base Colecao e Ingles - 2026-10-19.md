# Base viva, configurações, coleção e inglês — 19/10/2026

Status: implementado no Studio em Edit, aguardando playtest humano.

## Mudanças

1. BaseRoamingService mantém criaturas equipadas livres dentro da base, com pausas, mudança de direção, separação e desvio do totem/posto/avatares. Modelos ancorados sem colisão física. Atualização de renda não reinicia posições. Pedestais LugarN invisíveis/inertes; slot permanece como dado de capacidade.
2. SettingsPage e LocalPreferences: Sound e Base creatures. Preferências persistidas no perfil; ocultação local de todas as bases não altera renda. Som inclui sons de personagem e sons adicionados depois.
3. UI: retratos 3D dos modelos reais, entrada animada dos painéis, símbolos de livro/engrenagem, seleção e hover dos cards. Direção glossy e Fredoka One preservadas; sem declarar aprovação artística.
4. Texto visível nativo em inglês: HUD, menus, placas, mundo, avisos e ferramentas. StarterPack contém Training Lasso. IDs de saves permanecem estáveis (Dourado, Bolsa, etc.). Idioma/configuração de publicação no Creator Dashboard não foi alterado por esta entrega.
5. Hunting Shop com abas Tools e Lassos. Catálogo existente: três consumíveis e um laço; nenhum equipamento fictício foi anunciado.
6. GameplayConfig.Species.*.MinimumStrength; Lumito = 0. Servidor valida início e confirmação da captura. Mira fica vermelha se o requisito não for atendido.
7. Index com grade, retratos/silhuetas, fichas, raridade, progresso e variantes All/Normal/Gold. Histórico de descoberta separado da posse. Migração recupera variantes dos exemplares possuídos; não inventa histórico de variantes já vendidas.
8. Favoritos por indivíduo, filtro e proteção de venda no servidor e na interface. Equipar/desequipar preserva o favorito; para vender é necessário desfavoritar.

## Referência

Pesquisa do Index de Steal a Brainrot em documentação comunitária: [Index — wiki](https://stealabrainrot.wiki/wiki/index/) e [Index — Fandom](https://stealabrainrot.fandom.com/wiki/Index). Adaptação: coleção visual, silhuetas, variantes e progresso. Não foram importados bônus econômicos nem assets da referência; não houve inspeção ao vivo do jogo.

## Organização

- shared/GameplayConfig: limites, preferências padrão, nomes visíveis e parâmetros do passeio.
- server/ProfileData: migração aditiva, favoritos, preferências e descobertas de variantes.
- server/BaseRoamingService: apresentação móvel da base.
- server/CatalogPresentation: modelos reutilizados pelos retratos.
- client/CreaturePortrait, NavGlyph, SettingsPage, LocalPreferences: apresentação e preferências.
- CreaturePage, ShopPage e IndexPage permanecem separados.
- Captura, renda, compra e venda permanecem autoritativas no servidor.

## Evidência e limites

- 42 fontes iniciais iguais entre Studio/disco antes de alterar; 48 fontes finais de runtime.
- 33 verificações isoladas em Edit passaram: favoritos/venda, migração, limites de força, descoberta permanente, geração/passeio/remoção na base, montagem dos menus e preferências incluindo novos objetos.
- Compilação dos 48 fontes sem erro. Nenhum Play, benchmark, teste de DataStore real ou agente auxiliar.
- Aprovação de diversão, fluidez, estética, mobile e persistência real pendente.
- Movimento é uma solução limitada ao piso atual da base, não navegação geral em mapas arbitrários. Catálogo continua apenas Lumito, tamanhos e Gold.
- Backup local: contexto/evolucao-2026-10-19/antes.zip. Objetos anteriores: ServerStorage.HACBeforeEvolution20261019.
- Aplicação em Edit e verificação de fontes não comprovam salvamento completo do lugar em .rbxl/nuvem.

Próxima ação: [[Playtest Base e Colecao - 2026-10-19]]. Decisão: [[ADR-004 - Base viva, idioma e colecao]].
