# GiG Backoffice (E29)

Área da equipe do GiG em **Flutter Web**: login com a mesma conta do app (só quem tem `usuario.backoffice = true`),
dashboard (vazio por enquanto) e o menu **Sugestões** para responder as sugestões dos usuários (E28).

## Rodar
```bash
flutter pub get

# Sem backend (mocks): login equipe@gig.app / 123456
flutter run -d chrome --web-port 5173

# Com o gig-back local (perfil dev libera CORS para localhost:5173 e grava o cookie sem Secure)
flutter run -d chrome --web-port 5173 --dart-define=GIG_API=http://localhost:8080
```
Liberar o acesso de alguém (só direto no banco):
```sql
UPDATE usuario SET backoffice = true WHERE login = 'pessoa@gig.app';
```

## Sessão (segurança)
- Refresh token **só no cookie** `gig_bo_sessao` (`HttpOnly; Secure; SameSite=Strict; Path=/api/backoffice/sessao`, 8 h).
- Access token (15 min) **só em memória**. Nada em `localStorage`/`sessionStorage`.
- Toda chamada leva `X-GiG-Backoffice: 1`; renovar/sair exigem também o `Origin` do backoffice.
- Recarregar a página renova pelo cookie; 401 no meio do uso renova uma vez e repete; se falhar, volta ao login.

## Testes
```bash
flutter analyze
flutter test
```
No Windows: `_e29_checks.bat` (saídas em `_e29_analyze.txt` / `_e29_test.txt`).

## Publicar
Servidor Linux com Nginx (ver `deploy/nginx/backoffice.conf`) + Let's Encrypt:
```bash
./deploy/publicar-backoffice.sh usuario@servidor
```
Antes do primeiro build de produção, coloque as fontes em `assets/google_fonts/` (ver o LEIA-ME de lá).

## Estrutura
- `lib/core` — tema, marca e componentes copiados do app (`gig_app`). Se começarem a divergir, extrair um pacote `gig_ui`.
- `lib/data` — modelos, `BackofficeApi`, repositórios (API e mocks).
- `lib/app` — DI (get_it), sessão (MobX sem codegen), rotas (go_router).
- `lib/features` — `auth`, `shell` (menu), `dashboard`, `sugestoes`.
