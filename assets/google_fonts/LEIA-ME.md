# Fontes empacotadas (sem CDN)

A CSP do Nginx (`font-src 'self'`, `connect-src 'self'`) bloqueia o download das fontes do Google em tempo de
execução. Coloque aqui os arquivos `.ttf` (baixados de https://fonts.google.com) com os nomes que o pacote
`google_fonts` procura, por exemplo:

- `RobotoSlab-Regular.ttf`, `RobotoSlab-Medium.ttf`, `RobotoSlab-SemiBold.ttf`, `RobotoSlab-Bold.ttf`
- `RobotoFlex-Regular.ttf`, `RobotoFlex-Medium.ttf`

No build de release o backoffice desliga o download (`GoogleFonts.config.allowRuntimeFetching = false`) e usa
estes arquivos. No dev, se faltarem, o pacote baixa do Google normalmente.
