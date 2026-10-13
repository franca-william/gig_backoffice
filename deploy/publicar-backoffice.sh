#!/usr/bin/env bash
# E29 — gera o build web do backoffice e publica no servidor (Nginx serve /var/www/gig-backoffice).
# Uso: ./deploy/publicar-backoffice.sh usuario@servidor
#  - --no-web-resources-cdn: CanvasKit vai junto no build (a CSP só libera 'self', nada de gstatic.com).
#  - GIG_MODO=api: usa a API no mesmo endereço (/api/...), sem GIG_API.
set -euo pipefail
DESTINO="${1:?Informe usuario@servidor}"
cd "$(dirname "$0")/.."

flutter build web --release --no-web-resources-cdn --dart-define=GIG_MODO=api
rsync -avz --delete build/web/ "$DESTINO:/var/www/gig-backoffice/"
echo "Publicado. Confira https://backoffice.gig.app.br"
