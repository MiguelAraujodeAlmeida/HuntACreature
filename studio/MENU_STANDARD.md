# Menu Standard — Hunt A Creature

Atualizado em 19/10/2026. Padrão vigente e revisável; feedback do desenvolvedor prevalece. Referências: três screenshots de Index, Shop e Settings enviadas nesta rodada. Usar hierarquia e acabamento, sem copiar produtos, recompensas ou catálogo de outros jogos.

Especificação portável: `01_Produto/Design UI UX.md` no [cofre canônico](https://github.com/MiguelAraujodeAlmeida/HuntaCreature-Obsidian). Este guia descreve a aplicação técnica; mudanças no padrão devem atualizar ambos na mesma entrega, sem regras divergentes.

## Componentes obrigatórios

| Camada | Fonte | Responsabilidade |
|---|---|---|
| Tokens | shared/MenuTheme.luau | Acento por página, raridade, espaçamento, cabeçalho, limite de janela e breakpoint |
| Arte e fonte | shared/VisualStyle.luau | Fredoka One, ícones glossy existentes, branco com contorno escuro |
| Estrutura | client/MenuKit.luau | Window, Surface, Scroller, Layout, Detail, Grid, Badge, Stat, Action, Selectable, Empty |
| Retratos | CreatureCards + CreaturePortrait | Tile/ficha reutilizáveis, modelo real, silhueta desconhecida, raridade e variante |
| Equipamentos | ToolPortrait | Arte 3D decorativa de isca/armadilha/poção; imagem existente do laço |
| Input/estado | CollectionUI e módulos de página | Seleção, foco, rolagem, snapshots e envio de ações |
| Regras | ProfileData, ProfileService e servidor | Posse, preço, capacidade, favoritos, progresso e direitos de acesso |

Não criar novas telas copiando o antigo `UI:Card(título, parágrafo)`. Esse construtor foi retirado das páginas ativas. UpgradePage é legado sem rota e depende do construtor antigo; não o reativar. Placas físicas e disputa compacta têm composição própria, não são janelas de coleção.

## Gramática visual

- Janela escura texturizada, contorno escuro, cabeçalho de cor por função, título grande, X vermelho no canto superior direito.
- Studs usam a textura já existente; uma ImageLabel em Tile por superfície, sem milhares de Frames decorativos.
- Ciano: criaturas/index. Roxo: Hunter Rank. Verde: equipamentos. Dourado: mercado/valor/variante Gold. Azul claro: preferências.
- Texto em inglês. Manter IDs internos estáveis. Títulos e números dominam; descrições curtas e de baixo contraste, sem instruções contínuas.
- Criatura/item vem antes de sua ficha textual. Não trocar imagens por emoji ou blocos de texto.
- Uma ação principal por seleção. Confirmar venda e oferecer cancelamento; favorito bloqueia venda. Compra indisponível exibe o motivo real.
- Estados obrigatórios: carregando, vazio, selecionado, indisponível, confirmação (quando destrutivo), atualização de dados.
- Não adicionar produtos, timers artificiais, percentuais, recompensas de coleção ou itens futuros só para preencher espaços.
- Hunter Rank mostra o rank atual, XP restante e percentual até o próximo, além dos benefícios do próximo marco. Não expor custo total em XP, lista completa dos ranks nem rotular o último rank atualmente configurado como máximo. Exibir silhuetas apenas para equipamento real com `RequiredHunterRank`; missões ficam marcadas como futuras até existir sistema próprio.

## Layout e interação

- MenuTheme define cabeçalho de 78 px, margem 16 px, intervalo 12 px. Janelas usam o espaço seguro disponível e rolagem.
- A partir de 740 px, galeria à esquerda e detalhe independente à direita. Abaixo disso, o detalhe selecionado fica na rolagem principal, acima da galeria.
- Grid recebe largura útil e largura mínima de cartão; não escalar a tela inteira até o texto ficar ilegível.
- GlossyButton via Kit.Action concentra brilho, pressão, retorno e som. Área de input estável.
- Botões de navegação principais usam o mesmo `GlossyButton` com ícone original e placa curta; controles auxiliares da topbar podem usar a variante circular compacta, preservando o mesmo feedback de foco/clique.
- Selectable anima a borda existente e o enquadramento do retrato; evitar UIStrokes duplicados.
- Settings usa chave grande ON/OFF com resposta animada. A animação indica intenção; snapshot do servidor confirma. Timeout volta ao estado conhecido.
- Foco tem FocusKey estável por ação/indivíduo. Dados passivos de renda não devem destruir cartões.
- Cancelar tweens e conexões ao destruir os componentes. Não criar loops de partículas/sons para cada célula.

## Receita de uma página

1. Adicionar configuração da página em MenuTheme.
2. Criar um módulo de página com Render(ui); registrar somente a rota necessária em CollectionUI.
3. Definir ui.pageTitle. Usar ui:Tabs para navegação e Kit.Surface/CreatureCards para a composição.
4. Se houver galeria, chamar Kit.Detail(ui) **antes** de Kit.Grid para calcular a largura útil.
5. Enviar intenções por ui:Send; nunca alterar saldo, inventário, favoritos ou descobertas localmente.
6. Usar ui.valueRefreshers para valores voláteis. Reconstruir apenas quando o conteúdo mudar.
7. Conferir estado vazio/cheio, texto longo, confirmação, perda de seleção e estreitamento. Play/emulação ficam com o desenvolvedor, salvo pedido explícito.
8. Registrar o que foi observado e o que ainda não foi testado. A implementação não é aprovação artística.

## Mudanças futuras

Ajustes de estilo devem começar em MenuTheme/MenuKit; composições específicas ficam nas páginas. Ajustes de retratos em CreatureCards/CreaturePortrait; preços e progressão em GameplayConfig/ProfileData. Alterar um domínio não deve exigir redesenhar os demais.
