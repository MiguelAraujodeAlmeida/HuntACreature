# Hunt A Creature — protótipo jogável

O lugar aberto no Roblox Studio contém a segunda revisão dos itens **1, 2, 3 e 5** do [plano de prioridades](../PLANO_PRIORIZADO.md). O hub e a ilha ainda são ligados pela ponte: o teletransporte do item 4 ficou para outra etapa.

## Como testar

1. Salve o lugar no Roblox Studio e clique **Play**.
2. Equipe **Laço de treino** na barra padrão. Atravesse a ponte e encontre um Lumito.
3. **PC:** aponte com o cursor para onde deseja lançar, segure o botão esquerdo do mouse para carregar a força e solte. **Celular:** mire com a câmera e segure o botão **Lançar**. **Controle:** mire pelo centro da tela e use R2.
4. A força altera somente o alcance. Com carga máxima e alvo dentro do alcance, o centro do laço percorre uma linha reta até o ponto sob o cursor (ou a mira central no celular/controle), sem gravidade. Se faltar alcance, ele para antes. O minigame abre somente quando o ponto mirado pertence a uma criatura.
5. Durante a captura, segure **Espaço** no PC, **Puxar** no celular ou **A** no controle para mover a zona para a direita; solte para movê-la para a esquerda. Mantenha o marcador dentro da zona até completar a captura.
6. Volte ao hub e use **Instalar criaturas** no totem da sua base. Ouro e XP entram periodicamente. O treino atual ainda usa a esteira e será redesenhado no item 8.

## Organização para revisão

| Arquivo | Responsabilidade |
|---|---|
| `shared/VisualStyle.luau` | Fonte, cores e IDs dos ícones usados pelo HUD. |
| `shared/CaptureConfig.luau` | Ajustes por tipo de laço: tempo de carga, alcance e velocidade; também parâmetros do minigame. |
| `client/HUD.luau` | Construção da interface e apresentação dos estados/recompensas. |
| `client/GlossyButton.luau` | Componente de botão: acabamento, ícone, legenda, foco, pressão, seleção e reflexos; sem regras de jogo. |
| `client/CaptureController.luau` | Mouse, toque e controle; mira e comandos de captura. |
| `server/CaptureService.luau` | Validação da carga, projétil, acerto e simulação do minigame no servidor. |
| `HuntACreature.server.luau` | Criaturas, bases, economia, treino e integração com captura. |
| `HuntACreature.client.luau` | Inicialização dos módulos de interface e controle. |
| `BuildWorld.luau` | Construção do cenário com materiais e cores desta versão. |
| `STYLE_GUIDE.md` | Padrão visual para futuras alterações e modelos. |
| `assets/` | Ícones originais de recursos e bolsa, usados no HUD. |

Os módulos correspondentes estão inseridos no lugar em `ReplicatedStorage/HACShared`, `ServerScriptService/HACServer` e `StarterPlayer/StarterPlayerScripts/HACClient`. Os arquivos locais são a cópia editável do código. As fontes anteriores dos scripts principais e do primeiro HUD estão em `archive/`.

**Atenção ao cenário:** `BuildWorld.luau` reconstrói o mundo somente no modo **Edit** e substitui o cenário anterior do protótipo. Não o execute depois de construir manualmente algo que queira preservar.

## Limites atuais

- Uma espécie, com variante dourada; até três criaturas carregadas e três instaladas por base.
- Quatro bases simultâneas para testes multiplayer.
- Valores de dificuldade e economia ainda ajustáveis após testes de jogador.
- Sem persistência entre sessões, compras, trocas ou eventos.
- Captura concluída entra na bolsa imediatamente; transporte físico da criatura ainda não existe.
- A direção visual agora tem um padrão definido, mas modelos finais, mapa maior, criaturas móveis e efeitos de recompensa avançados são etapas posteriores.
