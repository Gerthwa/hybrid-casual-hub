# Hybrid Minigame Hub — Agent instructions

## Execution environment (important)

**Prefer the Local Agent on Burak’s Windows PC** for this repository.

- Local agent can run `rojo serve`, read `scripts/BASLA.bat`, and reason about Roblox Studio + Rojo plugin workflow.
- **Do not assume Cloud Agent** can open Studio, run Windows batch files on the user’s machine, or connect to `127.0.0.1:34872` on the user’s PC.

When the user asks to “run” or “show” the game, give **concrete Windows steps** or run shell commands **in the local workspace** if the agent is local — never claim remote control of the user’s Studio.

## Toolchain

| Tool | Install |
|------|---------|
| Aftman | `aftman add rojo-rbx/rojo@7.7.0` + `aftman add UpliftGames/wally@0.3.2` → `aftman install` |
| Wally | `wally install` (repo root) |
| Dev server | `.\scripts\BASLA.bat` or `.\scripts\dev.ps1` — keep window open |
| Studio | Connect Rojo: Host `127.0.0.1`, Port `34872` |
| Skill | `.cursor/skills/rojo-studio/SKILL.md` |

## Architecture reminders

- Rojo map: `src/Server`, `src/Client`, `src/Shared`; `default.project.json` at repo root.
- Boss swarm: server math only; no per-soldier `.Touched`.
- Tycoon: purchases validated on server via `TycoonConfig` + `DataService` (ProfileService).
- Extend remotes in `Shared/Remotes.lua` + `RemotesService`.

## Language

User-facing docs and explanations for Burak: **Turkish** unless he writes in English.
