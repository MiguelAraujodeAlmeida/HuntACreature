# Playtest — base, configurações, coleção e inglês

Entrega de 19/10/2026. Executar no lugar [Testing] Hunt a Creature (102310424634629). Os checks técnicos isolados passaram; nenhum item abaixo é considerado aprovado por isso.

## 1. Entrada e preservação

- [ ] Entrar com o perfil existente: ouro, XP, força, upgrades, criaturas e ferramentas continuam presentes.
- [ ] Menus, placas, avisos, balcões, laço e consumíveis aparecem em inglês. Nenhum aviso impede a entrada.
- [ ] HUD mantém recursos legíveis e navegação sem sobreposição com a barra nativa.
- [ ] Abrir/fechar Creatures, Index e Settings; conferir animação de abertura, foco, clique e fechamento.

## 2. Base viva

- [ ] Equipar 1 e depois várias criaturas: elas surgem soltas, sem pedestais individuais.
- [ ] Observar por alguns instantes: andam, mudam de direção e fazem pausas; não voltam à posição inicial a cada pagamento.
- [ ] Observar bordas, totem, posto de treino e outras criaturas: não escapam da base nem empurram o avatar.
- [ ] Caminhar pelo espaço das criaturas: elas param/replanejam e retomam o passeio quando o caminho é liberado.
- [ ] Desequipar: o modelo sai da base, a criatura volta à bolsa e a renda se ajusta sem duplicação.
- [ ] Ouro e XP continuam pagos a cada segundo, com o rendimento 5× já solicitado.

## 3. Settings

- [ ] Base creatures OFF oculta criaturas de todas as bases apenas para você; a renda continua.
- [ ] Equipar outra criatura enquanto a opção está OFF: o novo modelo também fica oculto.
- [ ] Reativar: modelos reaparecem no estado atual, sem criar cópias.
- [ ] Sound OFF silencia cliques, captura, renda e sons do personagem. Testar sons que surgem depois de desligar.
- [ ] Sound ON restaura o áudio; repetir OFF/ON não reduz o volume permanentemente.
- [ ] Configurações continuam após morrer/renascer e após sair/entrar novamente. Reconexão testa o DataStore real.
- [ ] Se houver um segundo jogador, confirmar que suas configurações não alteram som/visibilidade dele.

## 4. Favoritos e venda

- [ ] Marcar/desmarcar a estrela em Creatures; o filtro ★ mostra os favoritos.
- [ ] Equipar/desequipar um favorito: a marca é preservada.
- [ ] No Creature Market, favorito mostra Protected e não pode ser vendido.
- [ ] Desfavoritar e vender com confirmação: somente o indivíduo escolhido sai; ouro é creditado uma vez.
- [ ] Favorito continua após reconectar; venda continua restrita à proximidade do balcão.

## 5. Loja e Index

- [ ] Hunting Shop: Tools lista Bait, Trap e Calming Potion; Lassos lista Training Lasso.
- [ ] Tools mostram duração/recarga, estoque e quantidade possuída. Lasso mostra alcance/carga e Owned.
- [ ] Comprar uma ferramenta: preço, estoque, cota e quantidade mudam corretamente. Sem ouro/estoque não há compra.
- [ ] Abrir Index: grade com retrato 3D, progresso, raridade e ficha. Filtros All / Normal / Gold funcionam.
- [ ] Descoberta não obtida mostra silhueta e ???. Capturar a variante registra a descoberta correspondente.
- [ ] Vender/desequipar não apaga descobertas; Owned acompanha a posse atual.
- [ ] Perfis antigos preservam descoberta da espécie em All. Variantes antigas já vendidas não são inventadas retroativamente.

## 6. Captura, treino e telas

- [ ] Jogador com força 0 consegue capturar Lumito. Outros limites poderão ser definidos por espécie no catálogo.
- [ ] Training Lasso continua equipando/arremessando pelo mouse e pela hotbar nativa.
- [ ] Treinar/upgrade nas placas e saída do treino continuam funcionando; força aumenta normalmente.
- [ ] Em tela menor e, quando disponível, celular: filtros, estrelas, ON/OFF, cards, rolagem e fechar têm alvos clicáveis e texto legível.
- [ ] Avaliar se os movimentos, retratos, brilhos, pressão/retorno e sons melhoram clareza e satisfação sem poluição.

Para reportar: seção/item, resultado esperado, resultado observado, passos, resolução/dispositivo e print/vídeo quando ajudar.
