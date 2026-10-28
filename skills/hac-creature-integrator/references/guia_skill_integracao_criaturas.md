# Guia de integração de criaturas — Hunt A Creature

Especificação revisável da skill `hac-creature-integrator`. Escopo: receber um modelo existente e entregar uma espécie funcional para teste, com apresentação própria. Não é uma skill de criação de arte conceitual. A direção atual do Obsidian e o feedback do desenvolvedor prevalecem.

## 1. Entrada e identidade

Entrada: nome do modelo 3D e descrição opcional. Localizar a versão em arquivos de arte ou no Studio, inspecionar geometria, aparência e hierarquia. Perguntar apenas se houver candidatos ambíguos; não escolher silenciosamente uma versão diferente da pretendida.

Cada modelo representa uma espécie nova por padrão, inclusive modelos ornamentados. Usar o nome sem sufixos técnicos como nome público inicial; perguntar a raridade se ausente, apresentando as categorias vigentes. A aparência não determina raridade. Manter ID estável separado do nome exibido, UI em inglês e saves existentes. Se o ID/modelo já estiver cadastrado, reconhecer a integração anterior; esclarecer substituição quando necessário, sem duplicar nem sobrescrever outra espécie.

A descrição humana prevalece sobre inferências de personalidade. Antes de implementar, comunicar arquétipo de locomoção, personalidade e dois gestos próprios. Não transformar essa comunicação em uma nova aprovação obrigatória. Enquanto faltar raridade, preparar modelo/animação isoladamente e manter o cadastro jogável pendente.

## 2. Perfil provisório e aparecimento

Economia e distribuição definitiva serão pensadas depois. Usar um perfil provisório centralizado que leia os valores atuais do Lumito para renda, venda, XP de captura/pesquisa, força mínima e dificuldade. Não espalhar números copiados por espécie. Preservar os modificadores globais de tamanho e Gold. A raridade informada não altera esses números automaticamente.

Registrar a referência provisória por espécie, permitindo substituí-la posteriormente por valores próprios. Não pressupor que todos os parâmetros já existem no catálogo: dificuldade hoje também é calculada pela fábrica. Centralizar somente o necessário durante a integração, preservando o comportamento atual do Lumito.

Reservar um ponto do conjunto existente na ilha de teste para a nova espécie, mantendo o limite total de população. Reutilizar sua reserva em execuções posteriores; selecionar um ponto ainda não reservado em ordem estável e identificá-lo pela espécie. Preservar reservas de outras espécies e os demais pontos. Se não houver ponto livre, perguntar qual pode ser reassociado; não aumentar população nem remover outra reserva silenciosamente. O respawn deve respeitar a reserva. Ilha, frequência e balanceamento definitivos permanecem pendentes explícitos.

## 3. Preparação do modelo

- Preservar arte, proporções e materiais aprovados. Comparar importação com as vistas da fonte; não trocar por aproximação de peças sem decisão do desenvolvedor.
- Converter e verificar eixos Blender/Roblox, tamanho em studs, frente, apoio no chão e pivôs. Metadados FBX não são garantia de atributos Roblox: mapear e conferir `ColorRole`, grupos e `FootSide`.
- Preferir um rig anatômico com clipes autorais quando a malha permitir: `Motor6D` para peças rígidas, `Bone` para malha skinned. Preparar cópia articulável sem mudar a aparência; perguntar se isso exigir redesenho relevante. Preservar o original como retorno seguro até a aprovação visual da nova atuação.
- Separar raiz autoritativa, volume de captura e geometria cosmética. Dimensionar captura pelo corpo; ornamentos orbitais não aumentam automaticamente o alvo. Animações não deslocam a raiz de gameplay.
- Mapear explicitamente cabeça, tronco, membros, cauda, olhos, asas e ornamentos aplicáveis. Peças desconhecidas permanecem estáticas e são reportadas, nunca atribuídas automaticamente à cabeça.
- Conferir cada detalhe contra a articulação correta em várias poses: ornamentos da cabeça seguem a cabeça, detalhes de pés seguem o pé respectivo; não basta que a peça esteja conectada. Medir solas contra o piso em repouso e durante os clipes, inclusive nos tamanhos extremos.
- Respeitar papéis de cor por espécie na variante Gold e escala contínua vigente; evitar recolorir tudo como Main. Não alterar regras globais de mutação.

## 4. Atuação e qualidade

Criar uma criatura reconhecível pelo movimento. O Lumito é referência de integração, não molde de anatomia ou personalidade para todas as espécies.

| Situação | Resultado exigido |
|---|---|
| Locomoção | Passadas, saltitos ou flutuação coerentes com anatomia e velocidade real; acelerar, frear e virar suavemente |
| Repouso | Movimento sutil e pelo menos dois gestos próprios em intervalos variados, sem ciclos sincronizados entre indivíduos |
| Alerta/fuga | Postura e intensidade legíveis, disparadas por estados reais |
| Cansaço | Ritmo e postura distintos, com recuperação gradual |
| Disputa de captura | Resistência corporal e reação ao laço sem mover a posição autoritativa |
| Base | Passeio adequado ao espaço, gestos tranquilos e reação breve à proximidade, com intervalo entre saudações |
| Movimento secundário | Cauda, orelhas, asas e ornamentos seguem o corpo sem atravessar ou se desprender |

Quadrúpedes não reutilizam uma passada bípede. Contato de pés deve ser plausível, sem deslizamento evidente. Inferir gestos pela espécie: farejar/inclinar cabeça, observar/sacudir cauda, ou outros mais adequados ao conceito. São exemplos, não animações obrigatórias universais.

Flutuar significa pairar sobre terreno navegável com altura ajustável e oscilação visual moderada. Não implica voo livre, travessia de obstáculos ou captura aérea nova. Perguntar quando a descrição exigir essas mecânicas.

Misturar transições e calcular poses a partir do repouso, sem acúmulo de transformação. Não reiniciar abruptamente ciclos a cada mudança de velocidade. Para criaturas terrestres que correm, usar o puff de contato compartilhado do Lumito nos passos reais: textura/flipbook e emissão curta, ajustando apenas intensidade e posição anatômica. Não emitir fumaça parada, no ar ou em criaturas flutuantes. A frequência da passada deve acompanhar a distância percorrida e a escala, não apenas a velocidade desejada pela IA. Respeitar som e visibilidade configurados. Limpar efeitos/conexões ao remover a criatura e evitar trabalho visual desnecessário em criaturas ocultas/distantes.

Versionar construtor do rig, fontes de cada clipe e parâmetros de transição. Um `AnimationController`/`Animator` com IDs publicados é apropriado quando os assets estão disponíveis ao lugar. Se ainda não houver publicação, o reprodutor em runtime deve ler as fontes versionadas e aplicar poses às juntas; hashes de `RegisterKeyframeSequence` servem apenas à prévia no Studio. Não entregar uma espécie que só anima durante o teste local. O servidor continua dono de `Root`, navegação, colisão e estado; clientes apresentam poses, olhar e piscada. Clipes são próprios da espécie e não reutilizam mecanicamente o ciclo do Lumito.

Corrigir problemas visuais observáveis antes da entrega. A existência de movimento não comprova personalidade, diversão ou polimento; registrar limitações e exigir playtest humano para aprovar a experiência.

## 5. Integração na estrutura atual

Mapa de investigação, conferido em 23/10/2026; inspecionar os arquivos relevantes atuais antes de editar, sem comparação integral Studio/disco:

- `studio/shared/GameplayConfig.luau`: catálogo `Species`, valores, raridade, tamanho e Gold. O Index já percorre o catálogo.
- `studio/server/CreatureFactory.luau`: ainda seleciona Lumito no sorteio e usa template/paletas/colisão específicos. Generalizar os pontos necessários para seleção por espécie.
- `studio/server/CreatureProfiles.luau` e `CreatureBehaviorService.luau`: perfis e registro de comportamentos. Conferir passagem de ID de espécie versus ID de comportamento; não presumir que são iguais.
- `studio/server/LumitoBehavior.luau` seleciona o animador pelo `CreatureProfiles`; `LumitoRigBuilder`, `LumitoRigDriver`, `LumitoRigClips` e `LumitoRigPerformance` são o exemplo vigente de separação entre rig, estado e pose. São referência de estrutura, não de anatomia, gestos ou clipes para outra espécie. Localizar também a seleção de animador na base.
- A Chicken usa o mesmo contrato por `ChickenRigBuilder`, `ChickenRigDriver`, `ChickenRigClips` e `ChickenRigPerformance`, mas tem canais e oito clipes próprios. Ao mapear lados, conferir coordenadas reais do modelo importado: nomes `Wing_L`/`Wing_R` não provam o sinal do eixo X. Preservar `ChickenAnimator` anterior como retorno seguro até a avaliação humana.
- `studio/server/CatalogPresentation.luau` publica `HACCreaturePreviews`; `studio/client/CreaturePortrait.luau` consome retratos por espécie/variante. Regerar previews corretos, sem clones de Lumito disfarçados.

Separar template, perfil de comportamento, configuração de animação e perfil econômico. Reutilizar componentes compatíveis; não copiar o animador inteiro para cada criatura nem expandir monólitos. Não impor uma migração geral de arquitetura para adicionar uma espécie.

Percorrer o fluxo completo: catálogo → aparecimento/respawn → captura → bolsa → equipar/base → renda → desequipar → venda/favoritos → descobertas/persistência. Conferir Index, Creatures, Creature Market e recompensa de captura, incluindo retratos e silhuetas. Catálogo é fonte comum, não listas independentes por menu. Hunting Shop permanece loja de ferramentas/laços; não criar compra de criaturas.

Servidor mantém autoridade sobre recursos, captura, inventário e deslocamento relevante. Preservar IDs e dados existentes; nenhuma reinicialização de contas. Templates e assets publicados precisam estar acessíveis ao lugar; se a importação estiver bloqueada, informar o passo concreto pendente, sem alegar integração completa.

## 6. Verificação e entrega

No Studio Edit: validar template, escala, grupos, pivôs, atribuição de cada ornamento, solas, `Root`/hitbox, atributos, captura, registros, reserva de spawn, retratos e compilação. Inspecionar poses representativas em frente/perfil/3/4, usando cópias de revisão quando necessário. Não iniciar Play, emulação ou QA extenso automaticamente. Inspeção estática não comprova transições em execução.

Checklist humano por integração:

- Locomoção lenta/rápida, curvas, paradas, dois gestos e transições; contato dos pés ou altura de flutuação.
- Alerta, fuga, cansaço, captura parcial/sucesso/falha e respawn da espécie reservada.
- Bolsa cheia, equipar/desequipar, passeio na base, renda provisória, favoritos protegidos e venda.
- Index antes/depois da descoberta, retratos e recompensa corretos; tamanho mínimo/máximo e Gold.
- Reconexão e persistência, PC/celular, dois jogadores, som desligado e criaturas ocultas.
- Remoção/despawn sem efeitos ou conexões residuais; regressão do Lumito e das reservas existentes.

Entregar personalidade adotada, animações criadas, parâmetros provisórios, arquivos/assets e pendências. Distinguir implementado, verificado em Edit, pendente de playtest e aprovado pelo desenvolvedor. Não declarar diversão/polimento aprovados por compilação.

Aplicar via Studio MCP quando viável, registrar o commit aplicado e lembrar que o desenvolvedor salva o lugar manualmente. Atualizar notas donas, Estado Atual, Backlog e histórico do Obsidian, validar manifesto e sincronizar Git conforme AGENTS.md. Código versionado, aplicação, salvamento integral e publicação são estados distintos.

## 7. Manutenção da skill

Versão canônica em `skills/hac-creature-integrator/` no Git do jogo; instalação local aponta para ela. Este guia é a referência detalhada única. Carregar referências por necessidade, sem ler todo o cofre indiscriminadamente. Futuras decisões de economia, biomas ou captura atualizam este guia e as notas donas; não acumular especificações concorrentes.

Validar estrutura e referências sem integrar uma criatura como efeito colateral. A primeira utilização real exige solicitação de criatura e termina com revisão humana da experiência.
