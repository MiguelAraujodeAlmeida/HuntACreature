# Checklist completo — últimas atualizações

Versão: correção de interações de 18/10/2026, após menus/placas/inventário. **Todos os itens abaixo aguardam teste humano.** Marcar apenas o que foi observado; usar N/A quando o dispositivo/segundo jogador não estiver disponível.

## Preparação

- [ ] **P01 — Nova sessão:** salvar o lugar e iniciar um novo Play. Resultado: carregar seu perfil, receber sua base e ver recursos/menus preenchidos. A sessão anterior foi encerrada para aplicar as correções.
- [ ] **P02 — Registrar condições:** anotar dispositivo, saldo, força, níveis e quantidade de criaturas/ferramentas. Resultado: conseguir distinguir ganho de renda de descontos e recompensas.
- [ ] **P03 — Erros:** manter Output acessível. Resultado: nenhum erro vermelho de scripts HAC nem espera infinita de objetos ao entrar/abrir menus. Se falhar, copiar a mensagem completa.

## 1. Placas e melhorias

- [ ] **B01 — Descoberta:** aproximar-se da base que tem seu nome. Resultado: placa frontal mostra Base, Bolsa e Velocidade, com nível, benefício e preço; placa do manequim mostra Manequim, Eficiência e TREINAR.
- [ ] **B02 — Frente/verso:** olhar cada placa dos dois lados. Resultado: texto legível e botões nas duas faces, sem uma face totalmente preta.
- [ ] **B03 — Proximidade:** aproximar até ficar ao lado da placa. Resultado: ações disponíveis; um clique no preço faz a solicitação, sem apertar E nem abrir outro menu de upgrade.
- [ ] **B04 — Benefícios:** comprar um nível de cada categoria com ouro suficiente. Resultado: apenas aquela categoria sobe; ouro desconta o preço exibido; próximo preço/benefício atualiza; base/bolsa aumentam capacidade, velocidade muda deslocamento, treino/eficiência aumentam ganho.
- [ ] **B05 — Limites:** tentar compra sem ouro e em categoria no máximo. Resultado: nenhum débito/nível indevido; máximo indicado. Não repetir notificação continuamente sem clicar.
- [ ] **B06 — Clique repetido:** dar clique duplo rápido. Resultado: sem cobrança duplicada do mesmo nível; compras posteriores deliberadas mostram o novo nível/preço.
- [ ] **B07 — Distância e estado:** afastar-se um pouco, abrir menu ou entrar em captura. Resultado: placa não vira vazia nas proximidades; botões indisponíveis não executam ação. Fora do alcance visual a interface pode desaparecer normalmente.
- [ ] **B08 — Posse:** visitar outra base. Resultado: não comprar melhorias dela nem da sua remotamente. Interfaces de melhoria personalizadas aparecem na sua base.
- [ ] **B09 — Reentrada:** sair/reentrar e voltar à base. Resultado: placas reaparecem preenchidas sem exigir reset; níveis preservados.

## 2. Treino no manequim

- [ ] **T01 — Iniciar:** na placa ao lado do seu manequim clicar TREINAR. Resultado: personagem vai ao posto, fica imóvel e anima o laço automaticamente; força começa a subir.
- [ ] **T02 — Bloqueios:** tentar andar, saltar, lançar laço e usar ferramenta durante treino. Resultado: não sair acidentalmente nem consumir itens; nenhuma outra atividade simultânea.
- [ ] **T03 — Ganho:** acompanhar pelo menos três ciclos. Resultado: ganho a cada ~2 s, conforme Manequim × Eficiência; comparação antes/depois de upgrade revela benefício.
- [ ] **T04 — Sair:** clicar Sair do treino. Resultado: ganho para, personagem recupera movimento/velocidade comprada e consegue caçar/abrir menus.
- [ ] **T05 — Repetir:** treinar, sair e iniciar novamente. Resultado: sem ganho duplicado, animação acumulada ou controles presos.
- [ ] **T06 — Reset:** resetar personagem durante treino. Resultado: respawn móvel, sem ganho residual; placa permite novo treino. Não perde upgrades.

## 3. Criaturas: equipar e desequipar

- [ ] **C01 — Acesso único:** clicar Criaturas na lateral, fechar pelo X e reabrir. Resultado: tela abre com dados, filtros Todas/Equipadas/Na bolsa e capacidades; sem aba redundante de upgrades, Swap ou Vender.
- [ ] **C02 — Equipar:** com vaga na base, equipar uma criatura da bolsa. Resultado: mesmo exemplar aparece na base, ocupa um slot e começa a render; bolsa libera um espaço.
- [ ] **C03 — Desequipar:** com vaga na bolsa, desequipar a criatura. Resultado: retorna à bolsa, some da base e deixa de produzir. Nome/tamanho/mutação permanecem iguais.
- [ ] **C04 — Capacidades:** tentar equipar com base cheia e desequipar com bolsa cheia. Resultado: bloqueio compreensível, sem troca implícita, perda, duplicação ou mudança parcial. Liberar espaço/ampliar capacidade permite repetir.
- [ ] **C05 — Estabilidade:** manter tela aberta enquanto recebe renda; rolar e trocar filtro. Resultado: cartões não piscam/reordenam a cada segundo nem roubam a rolagem/foco.
- [ ] **C06 — Repetição:** clicar rapidamente numa ação e reabrir o menu. Resultado: uma localização válida por indivíduo, contagens coerentes e nenhum exemplar duplicado.

## 4. Mercado de venda

- [ ] **V01 — Encontrar/abrir:** ir ao balcão VENDA DE CRIATURAS no hub. Resultado: aparece Vender nas proximidades; usar E ou clicar no aviso abre a tela. No celular, tocar no aviso. O tampo não deve ocultar a interação conforme o ângulo da câmera.
- [ ] **V02 — Cancelar:** selecionar venda e fechar sem confirmar. Resultado: criatura e ouro inalterados.
- [ ] **V03 — Bolsa:** confirmar venda de uma criatura da bolsa. Resultado: receber exatamente o preço informado uma vez; indivíduo removido e espaço liberado.
- [ ] **V04 — Base:** confirmar venda de uma equipada. Resultado: modelo/slot e renda atualizam; preço creditado uma vez; outros indivíduos intactos.
- [ ] **V05 — Distância:** abrir mercado, afastar-se bastante e tentar confirmar. Resultado: servidor recusa, não vende nem credita ouro; voltar permite nova tentativa.
- [ ] **V06 — Repetição/Index:** repetir rapidamente confirmação e consultar Index. Resultado: nenhuma venda dupla; descoberta permanece mesmo após vender o último exemplar da espécie.
- [ ] **V07 — Vazio/filtros:** abrir sem criaturas ou com um filtro sem resultado. Resultado: estado vazio legível, sem ações inválidas ou erro de script.

## 5. Loja de ferramentas e rotação

- [ ] **L01 — Abrir:** no balcão LOJA DE CAÇA, usar Comprar por tecla/clique/toque. Resultado: catálogo, saldo, disponibilidade e tempo de reposição; compra e venda são balcões distintos.
- [ ] **L02 — Comprar:** comprar um consumível disponível. Resultado: descontar preço uma vez, aumentar quantidade e reduzir sua cota; Tool aparece/atualiza na mochila.
- [ ] **L03 — Restrições:** testar sem ouro, sem estoque, limite de quantidade e laço inicial já adquirido. Resultado: sem débito nem concessão indevida; motivo compreensível.
- [ ] **L04 — Afastamento:** abrir loja e afastar-se antes de comprar. Resultado: compra recusada até retornar.
- [ ] **L05 — Reposição:** se disponível, observar mudança da janela de 5 minutos com menu aberto. Resultado: atualizar ofertas/contador; pedido antigo não compra com preço/estoque incorretos.
- [ ] **L06 — Cota pessoal:** comprar e reconectar na mesma janela. Resultado: cota utilizada continua descontada. Com segundo jogador/servidor, compra de outra pessoa não reduz sua cota; mesmas ofertas globais.

## 6. Barra e mochila nativas

- [ ] **I01 — Posse:** comparar quantidade exibida com ferramentas da barra/mochila. Resultado: apenas itens possuídos; consumíveis zerados ausentes. Itens iniciais com quantidade positiva devem aparecer.
- [ ] **I02 — Organização:** abrir mochila com a tecla de crase/backquote no PC e arrastar ferramentas entre mochila/slots. Resultado: escolher posições; teclas numéricas acionam a posição atual, não um tipo fixo.
- [ ] **I03 — Atualizações:** reorganizar e aguardar renda/comprar mais unidades de um item existente. Resultado: quantidade atualiza sem recriar/reembaralhar seus Tools durante a sessão.
- [ ] **I04 — Zerar/recomprar:** consumir última unidade e recomprar. Resultado: Tool desaparece ao zerar e volta ao adquirir. Não permanece slot falso de item inexistente.
- [ ] **I05 — Respawn:** resetar personagem. Resultado: laço e quantidades possuídas disponíveis, sem duplicação; seleção e uso continuam funcionando. Ordem personalizada não possui persistência própria entre sessões.

## 7. Ferramentas e captura

- [ ] **F01 — Isca:** equipar e posicionar em chão válido da ilha. Resultado: uma unidade consumida, isca visível e Lumitos tranquilos próximos atraídos; recarga respeitada.
- [ ] **F02 — Armadilha:** posicionar e conduzir alvo até ela. Resultado: uma unidade consumida; arma após cerca de 1 s e desacelera alvo ao contato.
- [ ] **F03 — Posição inválida:** tentar posicionar longe, fora da ilha ou sobre outra ferramenta. Resultado: prévia/motivo claro e nenhuma unidade perdida. Posição válida não exige aviso textual constante.
- [ ] **F04 — Poção:** iniciar captura com laço, equipar poção e usar por clique/Usar poção. Resultado: disputa continua ao trocar de Tool; efeito aplicado e uma unidade consumida. Sem poção/fora da captura, não consumir.
- [ ] **F05 — Recarga:** repetir uso antes do fim do cooldown/efeito. Resultado: sem gasto extra; uso volta a funcionar depois.
- [ ] **F06 — Laço:** lançar em chão, céu e criatura dentro/fora do alcance. Resultado: voo na direção da mira, alcance limitado pela carga/laço, retorno em erro; não bloquear lançamento só porque não mira criatura.
- [ ] **F07 — Disputa:** capturar, perder e usar Soltar laço em tentativas distintas. Resultado: cada saída limpa corda/UI/estado, libera criatura quando apropriado e permite tentar de novo.
- [ ] **F08 — Interface e entrada:** clicar botões de placa/menu/loja com laço ou ferramenta equipada. Resultado: não lançar/consumir ferramenta por trás do clique de UI. Abrir mochila/menus não deixa carga presa.

## 8. Renda, saldo e persistência

- [ ] **E01 — Um exemplar:** equipar apenas Lumito normal tamanho 1, sem Dourado. Resultado: 1 ouro e 1 XP por pagamento, em intervalos de aproximadamente 1 s; não mais 5 s.
- [ ] **E02 — Soma:** equipar exemplares distintos. Resultado: ganho por segundo corresponde à soma exibida nos cartões. Desequipar/vender reduz o total; bolsa não rende.
- [ ] **E03 — Feedback:** observar ganhos por alguns ciclos. Resultado: valores/efeitos legíveis, sem som disparando a cada segundo nem aviso textual por pagamento.
- [ ] **E04 — Reconexão:** registrar ouro/XP/força, níveis, criaturas/localizações/variações, ferramentas e cotas; sair normalmente e reentrar. Resultado: progresso preservado, considerando renda recebida até a saída. Não usar modo temporário para validar persistência.
- [ ] **E05 — Operações simultâneas:** equipar/comprar enquanto renda entra. Resultado: sem saldo negativo, perda de renda, venda duplicada ou rejeição constante por revisão antiga.

## 9. HUD, dispositivos e multiplayer

- [ ] **U01 — Limpeza:** percorrer menus. Resultado: somente textos necessários, sem tutorial permanente, título fixo do jogo, botões duplicados ou informações sobrepostas.
- [ ] **U02 — Layout:** testar janela menor e, quando disponível, celular. Resultado: valores legíveis, rolagem alcança todos os cartões e fechar/confirmar permanecem acessíveis.
- [ ] **U03 — Toque/controle:** nos dispositivos disponíveis, testar seleção nativa de Tool, lançar, puxar, poção, fechar menu, treino e botões físicos. Resultado: ações acionáveis sem exigir mouse. Registrar qualquer ação inacessível pelo controle.
- [ ] **U04 — Foco:** alternar janela enquanto carrega/puxa e retornar. Resultado: comando não fica pressionado permanentemente; menus e ferramentas continuam respondendo.
- [ ] **U05 — Segundo jogador (opcional):** entrar com outro jogador. Resultado: cada um recebe base/perfil/cotas próprios; ninguém compra upgrades da base alheia ou gerencia/vende criatura de outro jogador.

## Relato de feedback

Para cada falha: **ID do teste → ação → observado → esperado → dispositivo → mensagem do Output/print**. Exemplo: “B01 — entrei, fui à minha base, as duas faces ficaram pretas por 10 s; esperava nível/preço; PC; sem erro no Output”.

Se um bloco falhar, registrar e continuar apenas testes independentes. Não é preciso esgotar ouro nem executar a lista inteira de uma vez. Primeiro: B01–B04, T01/T04, V01/V03, I02 e E01.

## O que o assistente verificou nesta correção

Inspeção da sessão que o desenvolvedor já havia aberto: placas físicas presentes, nenhuma SurfaceGui de upgrade no PlayerGui; prompts de loja/venda habilitados com linha de visão obrigatória. Código tinha uma única descoberta inicial de bases/peças/atributos. Sessão encerrada para aplicar correção, sem iniciar novo Play.

Cinco fontes alterados iguais no Studio/disco e compilados. Dezoito verificações isoladas em Edit passaram: chegada tardia, perfil anterior, duas faces, não duplicação, comandos simulados, bloqueios, remoção/recriação e limpeza. Sem gasto de perfil nem acesso ao DataStore nesses testes. Ativação por mouse/toque, ciclo completo, áudio e persistência real continuam pendentes acima.
