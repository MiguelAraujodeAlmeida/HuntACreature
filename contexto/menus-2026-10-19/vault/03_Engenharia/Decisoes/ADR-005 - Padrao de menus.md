---
tipo: decisao
status: vigente_revisavel
atualizado: 2026-10-19
---
# ADR-005 - Padrao de menus

## Contexto

O desenvolvedor rejeitou menus compostos só por texto e componentes genéricos. Enviou referências de Index, Shop e Settings, pediu refazer todos os menus fora de padrão e manter cuidado visual em novas telas.

## Decisão

MenuTheme centraliza tokens; MenuKit fornece janela, superfícies, grades, estados e ações. CreatureCards/CreaturePortrait reutilizam modelos reais; ToolPortrait separa arte decorativa de equipamentos. CollectionUI coordena snapshots/navegação. Páginas compõem, servidor decide regras.

Família: cabeçalho colorido, corpo escuro com studs, Fredoka branca contornada, X vermelho, retratos em destaque, botões glossy. Movimento responde a abrir/focar/pressionar/selecionar, sem poluição constante. Desktop divide galeria/detalhes; largura reduzida empilha.

Contrato técnico: `studio/MENU_STANDARD.md`. Novas telas reutilizam componentes e registram eventuais exceções. Não reativar UpgradePage legado ou duplicar acesso a upgrades nas janelas.

## Consequências

Mudanças visuais podem ser feitas por domínio, sem tocar em saldo/captura. Referências orientam composição, não autorizam copiar assets nem inventar catálogo/recompensas. Padrão e valores continuam revisáveis. Prévia não substitui aprovação humana.

Entrega/evidência: [[Menus e Reset Global - 2026-10-19]].
