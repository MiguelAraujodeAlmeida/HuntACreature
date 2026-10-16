# Hunt A Creature — linguagem visual v3 (botões)

Referência de energia: interface nas bordas, contraste forte, formas grandes e mundo de brinquedo como na imagem enviada de *Steal an Egg*. A identidade própria usa **corda, laço, expedição e mutações**.

## Regras

- **Fonte:** Fredoka One nas legendas dos botões, branca com contorno azul profundo. Gotham Bold para leitura e Black para números/títulos do HUD existente. Valores em `shared/VisualStyle.luau`; evitar escolhas isoladas em cada botão.
- **Paleta:** tinta escura translúcida, branco quente, corda dourada e acentos de aventura em turquesa, coral e verde. Cor forte indica ação ou recompensa, não moldura para toda informação.
- **Ícones:** moeda espiral, estrela de experiência, laço de força e bolsa de explorador são assets próprios em `assets/`. O HUD mostra os recursos com ícone, número e legenda, sem caixas coloridas.
- **Controles:** a bolsa é a ação lateral persistente. O botão de lançamento aparece somente no toque. A barra de carga ocupa o centro inferior quando está ativa. A disputa de captura é uma faixa compacta com alvo, zona, progresso e botão de puxar.
- **Botões v3:** referência glossy enviada em 16/10/2026. Bisel duplo, face em degradê, sombra inferior e reflexos. Ciano para navegação, dourado para ação com o laço, coral para fechar. Nos tiles, ícone grande e legenda sobre placa escura. Bolsa 112 × 116 px; lançar 94 × 98 px; ambos 84 × 88 px no modo compacto. Fechar mantém área de 44 × 44 px.
- **Interação:** foco aumenta o desenho e inclina o ícone; pressionar comprime e abaixa; soltar retorna com elasticidade curta. Reflexo e estrela respondem ao foco/ativação. Sem animação infinita. O alvo de input mantém tamanho fixo. `client/GlossyButton.luau` concentra o desenho e os efeitos; `Style.Button` concentra fonte, cores e movimento. Não colocar captura, inventário ou economia nesse componente.
- **Textos:** não manter tutoriais ou status permanentes sobre a cena. Avisos são curtos e temporários; o fluxo detalhado fica fora do HUD.
- **Mundo:** superfícies simples, modulares e saturadas, com poucos materiais repetidos. Evitar textura fotográfica isolada. O mapa completo será tratado em uma etapa posterior.
- **Criaturas:** silhuetas claras, formas grandes e expressões legíveis à distância. Variações raras usam luz/cor extra, mas mantêm a família visual de origem.
- **Recompensa:** antecipação (carga), impacto (acerto), corda visível na disputa, resolução e confirmação com estrelas no HUD e faíscas no mundo. Intensidade cresce com a raridade.

## Limite desta entrega

O sistema visual é aplicado ao HUD, à captura e à sinalização principal. O cenário completo e os modelos finais de criaturas ainda dependem das etapas específicas de arte do plano.
