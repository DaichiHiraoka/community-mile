# Project handoff (prototype)

## Current status
- All work is under `prototype/`.
- MVP scope locked:
  - Roles: resident, organizer, merchant, admin.
  - Check-in: two-step (start + end). Points are granted on end check-in only.
  - Expiration: 6 months; admin can change dynamically; changes apply to existing points immediately.
  - Settlement: monthly.
- Tech stack locked:
  - Backend: Java (Spring Boot + JPA)
  - Web: TypeScript (Next.js) for admin + merchant
  - Mobile: Android native (Kotlin + Jetpack Compose)
  - DB: PostgreSQL

## Environment (WSL)
- WSL distro: Ubuntu-24.04 (WSL2).
- Nix installed: `nix 2.33.1`.
- Docker installed in WSL, but docker socket access requires group membership (see next steps).
- Note: WSL prints "Failed to translate ..." warnings due to Windows PATH injection; usually harmless.

## Dev environment files
- `prototype/flake.nix`
  - Builds dev images: `community-mile-api`, `community-mile-web`, `community-mile-android`
  - Provides `load-images` app and `devShell`
  - `allowUnfree` and `android_sdk.accept_license` enabled
- `prototype/infra/docker-compose.yml`
  - Services: `db` (Postgres), `api`, `admin-web`, `merchant-web`, `android-build`
  - Volumes: `db-data`, `gradle-cache`, `node-cache`
- `prototype/apps/` directories exist but are empty:
  - `apps/api`, `apps/admin-web`, `apps/merchant-web`, `apps/android-app`
- `prototype/flake.lock` was created by `nix run` and is currently untracked.

## Next steps
1. Enable Nix flakes globally (inside WSL) if not yet:
   - `echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf`
   - `sudo systemctl restart nix-daemon`
2. Stage flake files so Nix can read them:
   - `git add prototype/flake.nix prototype/flake.lock`
3. Fix Docker socket permissions:
   - `sudo usermod -aG docker $USER` then reopen WSL shell
4. Build/load dev images and start Compose:
   - `cd /mnt/c/Users/ok230195/Downloads/地域共生/prototype`
   - `nix --extra-experimental-features "nix-command flakes" run .#load-images`
   - `docker compose -f infra/docker-compose.yml up`
5. Initialize app scaffolds:
   - `apps/api`: Spring Boot (Gradle) + health endpoint
   - `apps/admin-web`: Next.js (TS)
   - `apps/merchant-web`: Next.js (TS)
   - `apps/android-app`: Kotlin/Compose skeleton (build in container; emulator on host)
6. Proceed with data model + API design based on `prototype/要件定義.md` and `システム構成図.md`.
