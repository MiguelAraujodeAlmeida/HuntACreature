---
tipo: decisao
status: vigente_revisavel
atualizado: 2026-10-19
---
# ADR-004 - Base viva, idioma e colecao

## Contexto

Pedido direto do desenvolvedor em 19/10: criaturas soltas na base; configurações de visibilidade/som; HUD melhor; inglês nativo; Tools/Lassos; força mínima; Index semelhante à referência; favoritos protegidos.

## Decisão

- Base possui capacidade lógica por slot, mas a posição visual é livre. Movimento em módulo separado; publicar renda não reposiciona modelos.
- Som e visibilidade são preferências do jogador, persistidas. Ocultar atua somente na apresentação local de todas as bases, sem mudar economia.
- Texto nativo do jogo em inglês; documentação de desenvolvimento pode continuar em português. IDs históricos dos saves não são traduzidos.
- Favorito é propriedade do indivíduo. Venda é proibida enquanto favorito; equipar/desequipar mantém a marca.
- Descoberta permanente de espécie e variante é distinta de posse atual. Migração só infere variantes dos exemplares ainda possuídos.
- MinimumStrength é configuração por espécie e regra do servidor em início e prêmio da captura. Lumito = 0.
- Shop possui abas Tools e Lassos. Index adapta grade/silhuetas/variantes, sem copiar assets ou bônus da referência.

## Consequências

Migração aditiva mantém schema v1 e DataStores existentes. Passeio, UI, preferências e regras podem ser alterados independentemente. Novas espécies exigirão modelos/comportamentos próprios e valores revisados. Configuração de idioma no Creator Dashboard e persistência real precisam de validação na publicação/playtest.

Decisão revisável; aprovação de código não aprova a experiência.
