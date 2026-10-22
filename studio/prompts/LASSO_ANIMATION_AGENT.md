# Prompt — animação de preparação do laço

Implemente uma animação de preparação e soltura do Training Lasso no Hunt A Creature, usando o MCP do Roblox Studio. O objetivo é que o avatar pareça um cowboy preparando um arremesso: o gesto do corpo e da mão precisa explicar o movimento da corda. A versão anterior foi rejeitada por não levantar o braço de forma convincente. Não considere a versão atual visualmente aprovada.

## Contexto e arquivos

Leia o AGENTS.md do checkout e o bootstrap do context-manifest.json do cofre. Nesta máquina o cofre está em `C:\Users\melg_\OneDrive\Documents\Hunt A Creature\Hunt A Creature`; em outra máquina localize o clone real de https://github.com/MiguelAraujodeAlmeida/HuntaCreature-Obsidian. Depois leia somente os domínios necessários para animação/apresentação, engenharia e validação. Código: https://github.com/MiguelAraujodeAlmeida/HuntACreature.

Inspecione `studio/client/LassoChargePresentation.luau` e `studio/shared/LassoChargeStyle.luau`. Consulte `CaptureController`, `LassoFeedback`, `CaptureService`, `CaptureConfig` e `LassoVisuals` apenas nas integrações relevantes. Trabalhe sobre o Git atual e preserve alterações locais de outras tarefas. Não faça comparação integral Studio/disco.

## Resultado visual desejado

- Ao segurar o botão de arremesso, o avatar ergue o braço direito de forma clara. Cotovelo para fora, flexionado; mão ao lado e ligeiramente acima da cabeça. A silhueta deve ser legível de frente, lado e por trás. Não basta mover a corda com o braço caído.
- O ombro estabiliza o braço. Cotovelo acompanha discretamente; pulso e mão fazem círculos pequenos e fluidos. A mão esquerda pode se aproximar da cintura, sugerindo controle da corda restante. Evite braços torcidos ou atravessando cabeça/tronco.
- O laço aberto acompanha a mão num plano inclinado, aproximadamente 30–45 graus. Passa pela região acima da cabeça e pela lateral. Deve parecer corda boleada, com pequena deformação e atraso, não uma auréola flutuante nem uma argola rígida girando no próprio eixo.
- A entrada levanta o braço e abre o laço suavemente. Durante os 1,4 segundos de carga do Training Lasso, o ritmo acelera; após MAX, permanece estável até soltar. Use os valores reais de configuração por ferramenta.
- Na soltura, o braço avança e o cotovelo se estende num gesto curto de arremesso, seguido de recuperação suave. A apresentação não pode atrasar o comando de lançamento nem alterar sua direção. Evite deixar corda de carga e projétil visualmente duplicados.
- No cancelamento, recolha a apresentação e devolva os membros à animação normal sem estalo.
- Estética cartunesca Roblox, gesto expressivo e controlado. Rastro dourado curto e um destaque ao chegar a MAX são suficientes. Efeitos devem reforçar o gesto, sem esconder o alvo ou tentar compensar uma pose ruim.

## Restrições de implementação

- Preserve mira exata, alcance, carga, trajetória, captura e validação autoritativa. Esta tarefa é apresentação. Não bloqueie movimento/salto e não anime câmera ou pernas.
- Suporte ao rig efetivamente usado: o personagem observado usa AnimationConstraint. Preserve compatibilidade com Motor6D e fallback quando faltarem articulações. Verifique eixos e frames das articulações; não suponha que o mesmo Euler funciona diretamente em todos os rigs.
- A pose precisa coexistir com Animator, idle, caminhada e animação da Tool. Não multiplique indefinidamente offsets por quadro. Restaure corretamente o estado ao cancelar, morrer, trocar ferramenta, respawnar ou destruir o controlador.
- Separe pose, desenho da corda e parâmetros por laço. Mantenha ajustes de altura, flexão, ritmo e intensidade fáceis de alterar sem tocar na captura.
- Preserve início imediato local e apresentação remota pelos estados aceitos pelo servidor, sem remotes por quadro. Registre explicitamente eventuais diferenças entre a soltura local e a vista por outros jogadores.
- Cosméticos sem colisão, toque ou participação em raycasts. Limpe objetos, conexões e modificações temporárias. Não crie/publice assets pagos ou animações sem discutir a necessidade.

## Processo e entrega

Primeiro diagnostique por que a pose anterior não parecia um cowboy: eixos, rig, interferência do Animator, altura real da mão e vínculo entre mão/corda. Faça a correção focada, aplique em Studio Edit e compile. Não inicie Play, emulação ou testes extensivos sem pedido. Se Studio estiver em Play, peça para encerrar. Nunca acione o salvamento do lugar pelo acesso ao computador; lembre o desenvolvedor de salvar.

Entregue arquivos alterados, explicação breve, verificações realizadas e limitações. Compilar não comprova qualidade visual. Forneça checklist manual: observar braço/mão de três ângulos; carga parcial/MAX e carga mantida; andar/pular; soltar em diferentes direções; cancelar; trocar ferramenta; morrer/respawnar; PC/celular e dois jogadores. O resultado só recebe aprovação visual após feedback humano.

Atualize a documentação dona das regras, Estado Atual, Backlog e Histórico de Contexto no cofre; atualize manifesto, valide com check_context.py e sincronize Git conforme AGENTS.md. Diferencie código versionado, aplicação no Studio, salvamento humano e publicação.
