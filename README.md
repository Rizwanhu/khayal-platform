# khayal_platform

Khayal mobile app (Flutter). Backend target: **Supabase** (keys loaded from env, never hard-coded).

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- Dart SDK (bundled with Flutter)

## First-time setup

1. Clone the repo and enter this directory.
2. **Create your local env file** (not committed to git):

   ```bash
   cp .env.example .env
   ```

3. Edit `.env` and set real values from your Supabase project (see table below).
4. Install dependencies and run:

   ```bash
   flutter pub get
   flutter run
   ```

The app loads `.env` at startup via `flutter_dotenv`. Access values in code through `lib/core/app_env.dart` (or `dotenv` directly).

## Environment variables

| Variable | Required | Where to get it |
|----------|----------|-----------------|
| `SUPABASE_URL` | Yes (when using Supabase) | [Supabase Dashboard](https://supabase.com/dashboard) → your project → **Project Settings** → **API** → **Project URL** |
| `SUPABASE_ANON_KEY` | Yes (when using Supabase) | Same page → **Project API keys** → `anon` `public` |
| `SUPABASE_SERVICE_ROLE_KEY` | **No** for the mobile app | Server/CI only. **Never** embed in the client; it bypasses Row Level Security. |

Add more keys to `.env.example` as the app grows (push, OTP providers, etc.), then copy into `.env`.

### Files

- **`.env.example`** — committed template; safe to share; replace placeholders with descriptions only.
- **`.env`** — your real keys; **gitignored**; never commit.

## CI (GitHub Actions)

- Workflows copy `.env.example` → `.env` so `flutter analyze` / `flutter test` always have an env file.
- When a job needs **real** credentials (e.g. integration tests), add [repository secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions): **Settings → Secrets and variables → Actions**.
- Suggested secret names (create when you need them): `SUPABASE_URL`, `SUPABASE_ANON_KEY` (and only on the server side / special CI jobs: `SUPABASE_SERVICE_ROLE_KEY`).
- In the workflow, inject them only for the steps that need them, for example:

  ```yaml
  - name: Write .env for integration tests
    run: |
      echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" >> .env
      echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> .env
  ```

  (Use a dedicated workflow when you add those tests; keep the default CI on placeholders unless required.)

## If a secret was committed

1. **Rotate** the exposed key in Supabase (or the relevant provider) immediately.
2. Remove the secret from the latest commit; if it reached `main`, assume it was scraped—rotation is mandatory.
3. For history cleanup, use [GitHub guidance on removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) if needed.

## Getting started with Flutter

- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter documentation](https://docs.flutter.dev/)
