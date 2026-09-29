# Hybrid-Casual Minigame Hub (Roblox)

Quick mobile-ad-style minigames with long-term progression (tycoon, pets, rebirths). This repo uses **Rojo 7**, **Wally**, and **ProfileService** for a modular Luau architecture.

## Toolchain

| Tool | Role |
|------|------|
| [Aftman](https://github.com/LPGhatguy/aftman) | Pins `rojo` + `wally` |
| [Rojo](https://rojo.space/) | Syncs `src/` into Studio |
| [Wally](https://wally.run/) | Server packages (ProfileService) |

**Windows (önerilen):**

```powershell
aftman add rojo-rbx/rojo@7.7.0
aftman add UpliftGames/wally@0.3.2
aftman install
wally install
.\scripts\dev.ps1
```

Studio: **Plugins → Rojo → Connect** → `localhost:34872` → **Play**.

Detaylı Türkçe adımlar: [Rojo kurulum rehberi](cursor.agent://project/context/docs/rojo-setup.md).

**VS Code / Cursor:** recommended extensions — **Rojo**, **Luau LSP**, **Selene** (`.vscode/extensions.json`).

Enable **Game Settings → Security → Allow HTTP Requests** only if you add HTTP later. For local play, use **File → Publish to Roblox** (or Studio API access) so **DataStores** work; unpublished local files may not persist ProfileService data.

## Layout

```
default.project.json
wally.toml
src/
  Server/          → ServerScriptService.Server
    Services/
      DataService.lua       # ProfileService persistence (Coins, Gems, Rebirths)
      MinigameManager.lua   # Lobby → arena, 30s timer, coin reward
      RemotesService.lua
  Client/          → StarterPlayerScripts.Client
    Controllers/
      GameController.lua    # HUD: coins + timer
    UI/
      Hud.lua
  Shared/          → ReplicatedStorage.Shared
    GameConfig.lua
    Remotes.lua
    Types.lua
assets/Workspace/Hub/   # LobbySpawn + ArenaSpawn
ServerPackages/         # wally install (ProfileService)
```

## Core loop (MVP)

1. Player data loads via **DataService** (ProfileService).
2. **MinigameManager** teleports to lobby, counts down, moves to arena for **30s**, grants **50 coins**, returns to lobby, repeats.
3. **GameController** updates on-screen coins and timer from remotes.

Tweak values in `src/Shared/GameConfig.lua`.
