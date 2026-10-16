# Botões v3 — verificação em 16/10/2026

Referência: imagem glossy de botões enviada pelo desenvolvedor nesta sessão. Escopo: Bolsa, Lançar, Puxar e Fechar. Ícones existentes preservados; acabamento construído com UI nativa, editável. Nenhuma alteração nas regras do laço, minigame ou economia.

## Verificado no Studio

- Play em viewport de 1172 × 753; inspeção visual da Bolsa, Fechar e dos botões de ação.
- Mouse real via MCP: foco da Bolsa atingiu escala 1,055 e rotação do ícone −6°; pressão atingiu 0,94; clique abriu painel e Fechar o fechou.
- Pressionar, arrastar para fora e soltar restaurou escala 1. Seleção via GuiService ativou o foco visual e sua remoção restaurou o estado.
- Estados de captura/carga simulados em um HUD temporário: legenda “Puxando”, término de captura restaurando “Puxar”, carga 100% e reset. O HUD temporário foi descartado ao parar o Play.
- Bolsa/Lançar em 84 × 88 px: inspeção visual e TextFits verdadeiro. Isto verifica o componente compacto; não equivale a playtest de celular ou teste de todo o layout em diferentes proporções.
- Avisos FoundationProvider pertencem ao CorePackages do Roblox. Nenhum erro dos módulos alterados foi observado.
- Capturas MCP: GlossyButtons_01, GlossyButtons_Bag, GlossyButtons_Actions, GlossyButtons_Compact. As duas últimas mostram estados simulados, não uma captura de criatura real.

## Próximo playtest

Avaliar aparência e intensidade dos efeitos no jogo; no celular, conferir toque, posicionamento e legibilidade. Não houve teste físico de celular/controle nem validação subjetiva do desenvolvedor. Salvar o lugar pelo Studio; sincronização de scripts por MCP não confirma salvamento do arquivo/place.
