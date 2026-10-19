---
tipo: playtest
status: historico
atualizado: 2026-10-19
---

# Feedback consolidado

## Direção atual — 19/10

Pedido direto: criaturas soltas na base; Settings com som/visibilidade; HUD mais dinâmico; inglês nativo; Tools/Lassos; força mínima (Lumito 0); Index inspirado em Steal a Brainrot; favoritos impedindo venda. Implementação/evidência em [[Base Colecao e Ingles - 2026-10-19]]. Ainda sem aprovação humana. Esta solicitação supera o adiamento anterior de configurações.

## Bloqueio de interações reportado — 18/10

Placas vazias/não clicáveis; treino, venda e outros acessos ausentes no teste humano. Investigação e correção em [[Correcao de Interacoes - 2026-10-18]]. A entrega anterior não está aprovada; aguardar reteste em [[Checklist das Ultimas Atualizacoes]].

## Direção mais recente — menus, placas e inventário (18/10)

- Remover redundância: upgrades em placas clicáveis da base/treino, sem menu alternativo.
- Um botão lateral Criaturas para gerenciamento; substituir troca direta por equipar/desequipar.
- Venda em loja física, sem botão de venda no gerenciamento remoto.
- Renda por segundo; resposta explícita à pergunta de balanceamento: **acelerar em 5×**.
- Apenas ferramentas possuídas na barra; usar gerenciamento/reordenação nativos.
- Menos guias/tutoriais/textos repetidos nos menus, mantendo decisões compreensíveis.
- Continuação implementada em [[Menus Placas e Inventario - 2026-10-18]], aguardando novo parecer. As seções abaixo são relatos históricos e não a especificação atual.

## Após a entrega da base — 18/10/2026

- Depois da investigação da desconexão por acesso às APIs do Studio, o desenvolvedor informou “agora está funcional”. Bloqueio de entrada resolvido pelo relato; persistência após reconectar e restante da experiência não foram aprovados por essa frase.
- Loja e upgrades não correspondem à experiência desejada. Pedido de pesquisa de Grow a Garden e Steal an Egg antes de reformular.
- Reafirmou melhorias individuais de base, treino, bolsa, multiplicador da evolução da força e velocidade. Os níveis já são separados nos fontes; a forma de apresentação ainda precisa corresponder a essa intenção.
- Index deve ter botão próprio no HUD.
- Ampliou a pesquisa para todos os sistemas correspondentes do projeto nas três referências e confirmou Steal a Brainrot como o terceiro jogo.
- Resultado em [[Pesquisa Comparativa de Sistemas - 2026-10-18]]. Esta rodada não mudou gameplay nem realizou testes pesados.

## Primeiro teste humano do Lumito

- Comportamento inicial ficou melhor do que o desenvolvedor esperava; não é aprovação final de todos os sistemas.
- Acerto do laço instável e minigame nem sempre inicia: prioridade de correção por prejudicar muito o jogo.
- Movimento visual ainda mal polido, atribuído ao modelo/animação provisórios; refinamento adiado.
- Passeio normal deve ter pausas e retomadas variáveis, com comportamento menos previsível.
- Resposta implementada em [[Correcao Laco e Passeio - 2026-10-17]]; aguarda novo teste manual.

## Correções e escopo reafirmado — após HUD/áudio

- Não colocar botão de som em cada painel; deixá-lo para futura aba de configurações.
- Preferência permanente: o desenvolvedor executa testes pesados/manual, poupando créditos. Assistente faz verificações leves e fornece lista de testes, sem QA extensivo autônomo.
- Variedade de criaturas, tamanho, mutações e comportamento próprio já fazem parte do escopo; upgrades de base, treino, bolsa, multiplicador da força no treino e velocidade também são intenção existente, mas ainda é cedo para implementá-los.
- Foco escolhido: Lumito comum como cobaia; andar lentamente, evitar colisões/bugs, entrar em pânico ao enxergar o jogador, correr até cansar e andar mais devagar. Implementado, aguardando [[Playtest Lumito - 2026-10-17]].

Este registro resume o feedback direto do desenvolvedor. Não atribuir a ele aprovação da revisão mais recente sem novo teste.

## Feedback de HUD/áudio — 17/10/2026

- HUD quebrava dependendo do tamanho de tela; precisa ser dinâmico entre dispositivos.
- Texturas não foram consideradas feias, mas estão muito longe do objetivo. Trabalho adiado por decisão do desenvolvedor.
- UX não está aceitável nem para o protótipo muito inicial; pedido de ideias para torná-lo divertido, dinâmico e com vontade de repetir, a partir das referências anteriores.
- Som foi considerado muito ruim; precisa dar satisfação e reforçar as ações/recompensas.
- Resposta implementada: HUD responsivo e primeira paleta por ação, em [[QA HUD e Audio - 2026-10-17]]. Ideias em [[Propostas de UX]]. Ainda sem parecer humano posterior.

## Primeiro protótipo

- HUD, UX e modelos pareciam genéricos e pouco amigáveis; necessidade de uma linguagem visual consistente.
- Minigame duro, pouco fluido e sem energia.
- Captura não deveria começar por proximidade + tecla E; o laço deve ser lançado para onde o jogador escolher, com força carregada ao segurar.
- Treino distante da ideia final: avatar imobilizado, laçando automaticamente manequim aprimorável, em vez de esteira.
- Hub e ilha de caça devem ser áreas separadas por teletransporte. Mapa maior, modular, divertido, com aparência de brinquedo/peças.
- Criaturas precisam andar/reagir com física estável.
- Progressão, capturas e vitórias devem provocar recompensa visual e sonora forte, sem ficar monótonas.

## Após a primeira implementação dos itens 1, 2, 3 e 5

- O HUD ainda parecia “AI slop”: caixas coloridas, fonte desagradável, poucos ícones originais, título e tutoriais persistentes, sobreposições. Recursos no canto podiam existir como ícones/números sem caixas.
- O minigame estava mais fluido, mas curto, parado e sem sensação de disputa/conquista; o painel grande atrapalhava.
- O laço estava impreciso e inconsistente. Requisito: mira exata no mouse, sem desvio de gravidade, distância limitada por tipo de laço e tempos de carga distintos.
- A barra de força deveria ser longa, central e acima da barra de ferramentas.

## Segunda revisão implementada

O registro de código informa fonte Gotham, ícones próprios, HUD reduzido, disputa compacta, laço reto com mira e carga revistas. **Ainda sem parecer do desenvolvedor após playtest.** Criar uma nova nota com [[Modelo - Playtest]] quando houver teste, incluindo capturas de tela e observações sobre diversão/clareza.

## Decisões que superam contexto antigo

Treino no manequim substitui esteira; teletransporte substitui ponte; UI sem tutorial permanente; recompensa expressiva é prioridade recorrente. Ver [[ADR-002 - Treino no manequim]] e [[Direcao Visual e UX]].
