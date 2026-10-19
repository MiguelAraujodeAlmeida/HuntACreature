# Hunt A Creature — direção visual atual

Atualizado em 18/10/2026. Referência vigente: arte glossy enviada pelo desenvolvedor, ícones de brinquedo com volume, painéis escuros e contornos luminosos ciano/dourado. A direção é revisável e ainda depende de parecer humano.

## Componentes

- **Fonte:** Fredoka One para texto e títulos, centralizada em shared/VisualStyle.luau. Texto branco com contorno escuro e números legíveis.
- **Arte:** skins e ícones v4 independentes, referenciados em VisualStyle. Preservar proporção; tamanhos/layout vêm de HUDLayout. Ouro dourado, XP roxo, força ciano; navegação glossy ciano.
- **Interação:** GlossyButton concentra foco, pressão, retorno, brilho e seleção; área de input estável. UIEffects/AudioFeedback concentram feedback, sem economia no componente.
- **HUD:** recursos compactos no canto inferior esquerdo no desktop; Criaturas/Index na lateral; carga longa central inferior quando ativa. Disputa compacta. Layout considera área segura/toque; validação manual necessária.
- **Inventário:** CoreGui.Backpack do Roblox. Não duplicar slots, atalhos numéricos ou ferramentas inexistentes numa segunda barra.
- **Placas:** fundo físico escuro, benefício verde, nível branco, custo em botão vermelho; Treinar verde. UpgradeBoards apresenta, WorldStations posiciona, GameplayConfig define preços/benefícios.
- **Menus:** nome, estado, capacidade, valor/renda e ação relevante. Criaturas: Equipar/Desequipar; Venda: preço/confirmação. Evitar guias longos, botões repetidos e avisos do que já está visível.

## Mundo e recompensa

Mundo cartunizado modular, saturado e coerente. Amostras de studs/madeira/piso em WorldStyle não são arte final aprovada. Evitar textura fotográfica isolada. Criaturas com silhueta clara e expressão; raridade/mutação reforça a família visual.

Feedback acompanha antecipação, impacto, progresso e resolução. Efeitos expressivos sem cobrir a mira ou impedir decisão. Renda por segundo não exige som a cada pagamento; AudioConfig também aplica cooldown. Sem mute em cada painel; configurações são escopo futuro.

## Aprovação

Compilar e inspecionar prévia não aprova estética, som ou interação. Receber feedback sobre a fatia antes de escalar telas/modelos. Sem título permanente, tutorial constante ou painel grande de captura. Documentar decisões no cofre e alterar componentes compartilhados.
