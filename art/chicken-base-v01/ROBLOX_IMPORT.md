# Chicken Base v01 — integração no Studio

Fonte aprovada: `Chicken_Base_v01.blend` e `Chicken_Base_v01.fbx`. O código do jogo espera `ReplicatedStorage.HACChickenTemplate`, com 25 MeshParts nomeados como no FBX, `Root` e `Corpo` invisíveis.

O importador 3D do Studio converteu esta exportação Blender em uma malha **100 vezes maior**. Após importar o FBX, a cópia de runtime foi normalizada para 1 unidade Blender = 1 stud, frente `-Z`, chão em `Y=0` e raiz 1,35 studs acima do chão. As peças receberam `ColorRole` explícito; a variante Gold reutiliza os mesmos papéis de cor. Os MeshIds são ativos Roblox publicados na conta que importou o FBX e ficam referenciados no template do lugar.

Para reconstruir em outra cópia do lugar: importar o FBX, escolher o criador que possui o lugar, preservar as 25 peças e executar `studio/tools/PrepareChickenTemplate.luau` pelo MCP em Edit. Revisar o template e salvar o lugar manualmente. Não executar o preparador se o template atual contiver edições de arte não transferidas ao FBX.

Economia e dificuldade da Chicken são provisoriamente herdadas do Lumito, enquanto `Ponto4` da ilha de teste fica reservado para ela. A animação está em `studio/server/ChickenAnimator.luau` e não altera os meshes de origem.
