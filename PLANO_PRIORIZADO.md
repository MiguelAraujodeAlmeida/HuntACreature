# Hunt A Creature — prioridades após o primeiro teste

Este plano registra o feedback do primeiro protótipo. As estimativas são de trabalho ativo para uma primeira versão testável de cada item, sem contar revisões de direção artística, gerações de IA que precisem ser refeitas ou publicação. **Nenhum item abaixo está aprovado como especificação final de números ou arte.**

## Estado após a primeira implementação

- **#1, segunda revisão:** Gotham, paleta mais contida e ícones próprios para ouro, XP, força e bolsa; sem molduras coloridas nos recursos.
- **#2, segunda revisão:** disputa compacta horizontal, corda visível no mundo, duração maior, sequência de acertos e recompensa visual.
- **#3, segunda revisão:** removidos título, guia e instruções permanentes; recursos e ações reposicionados para PC e celular horizontal.
- **#5, segunda revisão:** mira do mouse corrigida, lançamento reto sem gravidade, barra central e parâmetros de alcance/tempo separados por tipo de laço.
- **#4:** não iniciado, conforme pedido; a ponte continua temporariamente.

Esses itens estão **prontos para teste**, não aprovados como versão final. Os arquivos e controles estão descritos em [studio/README.md](studio/README.md).

## Princípios permanentes

- **Identidade própria:** o laço, a caça e as mutações devem dar ao jogo uma silhueta e uma interação reconhecíveis. A imagem de *Steal an Egg* serve como referência de legibilidade, energia e distribuição dos controles; seus elementos específicos não precisam ser reproduzidos.
- **Um sistema visual:** uma família tipográfica, uma paleta, regras de contorno/sombra, materiais e proporções repetidas para cenário, interface e criaturas. Exceções visuais devem sinalizar raridade ou evento.
- **Recompensa visível e sonora:** cada ação importante deve ter antecipação, impacto, confirmação e recompensa. Aumentar a intensidade em capturas raras e marcos de progressão, sem ocultar o controle do jogador.
- **Primeiro PC e celular:** alvos de toque confortáveis, interface nas áreas seguras da tela e fluxo de captura igualmente compreensível nos dois dispositivos.

## Ordem recomendada

| # | Entrega | Prioridade | Dificuldade | Estimativa | Critério de teste |
|---|---|---|---|---|---|
| 1 | Guia visual curto: tipografia, paleta, contornos, botões, materiais modulares, silhueta e escala de criaturas; amostra de uma base e um Lumito | Crítica | Baixa–média | 3–6 h | Uma tela e um pequeno trecho 3D parecem parte do mesmo jogo e podem orientar novos assets. |
| 2 | Minigame mais fluido: movimento interpolado, resposta ao comando, velocidade e dificuldade recalibradas, feedback de acerto/erro | Crítica | Média | 4–8 h | Captura comum é clara, responsiva e não parece travar em PC ou celular. |
| 3 | HUD e UX de primeira passada: recursos nas bordas, ações contextuais, destaque de captura/base, botões grandes, tela limpa durante a caça | Crítica | Média | 1–2 dias | Jogador novo entende o que fazer e lê as informações sem cobrir o alvo ou duplicar o texto do mundo. |
| 4 | Hub e Ilha de Caça como áreas separadas, com teletransporte de ida e volta e chegada legível | Alta | Média | 4–8 h | Não há ponte; o jogador localiza a saída, chega em local seguro e consegue retornar. |
| 5 | Lançamento livre do laço: mira, barra de força ao segurar, soltura, trajetória/projétil e acerto validados pelo servidor; o minigame só inicia após acertar | Crítica | Alta | 2–4 dias | O jogador escolhe onde lançar; força altera o alcance; erro não inicia captura; PC e celular funcionam. |
| 6 | Criaturas vivas: patrulha, pausas, reação ao jogador/laço, limites de área, física estável e colisão simples | Crítica | Média–alta | 1–3 dias | Criaturas se deslocam sem sair da ilha, atravessar objetos ou empurrar jogadores de modo estranho. |
| 7 | Primeira camada de recompensa: animação do laço, impacto, partículas, som, contador de recursos e celebração proporcional à raridade | Alta e contínua | Média | 1–2 dias iniciais | Captura comum é satisfatória; dourada tem celebração marcante; feedback não encobre o próximo comando. |
| 8 | Treino do laço no manequim: substituir esteira, prender o avatar ao ponto durante o treino, animar o ciclo automaticamente, saída clara e melhorias compradas com ouro | Alta | Alta | 2–4 dias | Jogador não se move/caça durante o treino; animação e ganho param ao sair; upgrade altera o ganho. |
| 9 | Ampliar as duas áreas e redesenhar sua navegação: zonas de caça, pontos de interesse, caminhos e espaços para bases/expansões | Alta | Média–alta | 2–4 dias | Mapa oferece exploração e orientação sem longas travessias vazias. |
| 10 | Trocar materiais e cenografia atuais por visual modular lúdico, inspirado em brinquedos/peças, com cores alegres e poucos materiais consistentes | Alta | Média | 2–4 dias | Chão, paredes, rochas, árvores e bases compartilham escala de detalhe e iluminação coerentes. |
| 11 | Pipeline de criaturas e modelos com IA: conceito, geração 3D, escolha e ajuste, textura, peças para animação, colisão simplificada e teste de desempenho; produzir primeiro um modelo de referência | Alta | Alta/variável | 2–5 dias para o primeiro modelo aprovado | O primeiro modelo define qualidade, proporções e processo repetível para novas espécies/mutações. |
| 12 | Revisão de onboarding e acessibilidade: dicas contextuais, hierarquia de botões, confirmação de ações, escala da interface e QA em múltiplas telas | Alta | Média | 1–2 dias | Um jogador sem explicação externa consegue equipar, mirar, capturar, voltar, instalar e treinar. |

## Dependências importantes

- O guia visual (#1) orienta HUD (#3), cenário (#10) e modelos (#11).
- O minigame (#2) pode ser melhorado isoladamente; o lançamento livre (#5) muda a maneira de iniciá-lo.
- A movimentação das criaturas (#6) deve ser testada junto ao acerto do laço (#5).
- O mapa ampliado (#9) deve preservar a divisão e os pontos de chegada do teletransporte (#4).
- Recompensas (#7) entram em cada implementação; não devem ser deixadas para uma única fase final.

## Referência visual fornecida

Na imagem de *Steal an Egg*, os controles principais ficam nas laterais; moedas/progresso ficam na parte inferior; textos usam alto contraste e contorno; o terreno tem padrão modular de peças e cores saturadas; os efeitos dão destaque aos elementos valiosos. Para Hunt A Creature, usar essa **clareza e energia** com motivos próprios de laço, expedição, criaturas e mutações.

## Caminho 3D sem Blender como ferramenta principal

1. Criar imagens de conceito com frente, lado e costas, respeitando o guia visual.
2. Gerar uma malha ou modelo procedural no Studio/Roblox MCP; selecionar o resultado pela silhueta antes de insistir na textura.
3. Ajustar proporções e peças no Studio. Para criaturas animadas, manter partes separáveis (corpo, cabeça, patas, cauda etc.) quando necessário.
4. Gerar/aplicar materiais e texturas com paleta e nível de detalhe consistentes. Usar um colisor simples separado da malha visual.
5. Testar em tamanho real no jogo: animação, colisão, distância de leitura e desempenho. Repetir até o primeiro modelo servir de padrão.

IA acelera a criação inicial, mas seleção, ajustes e teste no Studio continuam essenciais para atingir a consistência de um jogo grande.
