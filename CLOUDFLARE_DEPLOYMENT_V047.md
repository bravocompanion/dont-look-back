# v0.47 — Godot Web + Cloudflare Pages deployment

The repository now contains an automated GitHub Actions pipeline at:

`.github/workflows/deploy-cloudflare-pages.yml`

It runs on every push to `main` and can also be started manually with `workflow_dispatch`.

## What the workflow does

1. Checks out the repository.
2. Downloads Godot 4.7.2 stable for Linux.
3. Downloads and installs the matching Godot Web export templates.
4. Exports the `Web` preset from `export_presets.cfg` as a release build.
5. Extracts the Web package into `build/web`.
6. Uploads the Web build as a GitHub Actions artifact for 14 days.
7. Rejects deployment if any individual generated file exceeds Cloudflare Pages' 25 MiB asset limit.
8. Checks whether Cloudflare credentials exist.
9. Creates the Pages project if it does not already exist.
10. Deploys `build/web` to Cloudflare Pages.

The default Pages project name is `dont-look-back`.

You can override it with the GitHub Actions repository variable:

`CLOUDFLARE_PAGES_PROJECT`

## Required GitHub Actions secrets

The Cloudflare deployment step remains disabled until both repository secrets exist:

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`

In GitHub:

`Repository -> Settings -> Secrets and variables -> Actions -> New repository secret`

### CLOUDFLARE_API_TOKEN

Create a scoped Cloudflare API token for the account that will own the Pages project. It needs permission to write/manage Cloudflare Pages for that account. Do not commit the token to this repository.

### CLOUDFLARE_ACCOUNT_ID

Use the Cloudflare Account ID for the account that will own the Pages project. Store it as a GitHub Actions secret.

## First deployment

Once both secrets exist, either push a new commit to `main` or run the workflow manually from GitHub Actions.

The workflow will create the Pages project when needed with production branch `main`, then run a Wrangler Pages deployment.

The expected Pages hostname is normally based on the project name, for example:

`dont-look-back.pages.dev`

Cloudflare may add disambiguation if that project hostname is already taken.

## Important Web multiplayer limitation

The current native multiplayer implementation uses `ENetMultiplayerPeer` and UDP port 24877. A browser build cannot use that raw ENet/UDP transport.

Therefore v0.47 Cloudflare publishing should first be treated as a browser/single-player validation build. Public browser co-op requires a later transport pass using WebSocket or WebRTC while preserving host/server authority for gameplay state.

Native desktop/mobile builds keep the existing ENet multiplayer behavior.

## Cloudflare Pages file limit

Cloudflare Pages currently limits each individual static asset to 25 MiB. Godot Web exports can hit this limit with `.wasm` or `.pck` files as the game grows.

The CI pipeline checks the generated build before deployment and prints the exact oversized files instead of allowing Wrangler to fail without context.

If a generated asset grows above the limit, likely options are:

- reduce/compress imported textures and audio;
- remove unused production assets from the Web export;
- split optional downloadable data where practical;
- move large static content to Cloudflare R2 and load it separately;
- use another hosting provider whose per-file limits fit the final Web build.

## Build reproducibility

The Web CI is pinned to Godot 4.7.2 stable and matching export templates. If the local editor uses a different Godot release, validate the project locally before changing the pinned CI version.

The Web preset is single-threaded (`variant/thread_support=false`) for wider browser and static-host compatibility and does not require cross-origin-isolation headers.
