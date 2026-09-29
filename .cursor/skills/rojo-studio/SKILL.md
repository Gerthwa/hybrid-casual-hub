---
name: rojo-studio
description: Roblox Studio + Rojo senkronu, bu Hybrid-casual hub reposu ve Windows (Burak) yerel geliştirme akışı. Rojo eklentisi, rojo serve, place açma ve sık hatalar için kullan.
---

# Rojo + Roblox Studio (Hybrid Minigame Hub)

Bu skill, **Cursor Agent**'ın bu repoda Roblox/Rojo görevlerinde izleyeceği standart akıştır. Geliştirme **kullanıcının Windows PC'sinde** Studio + `rojo serve` ile yapılır; agent Studio'yu uzaktan açamaz.

## Ön koşullar (Burak — bir kez)

1. **Rojo Studio eklentisi** kurulu (Plugins → Rojo veya Creator Store).
2. **Aftman + Rojo CLI** PATH'te (`aftman install`, `rojo --version` → 7.7.0).
3. **Wally** (`wally install` proje kökünde).
4. Cursor'da önerilen eklentiler: `.vscode/extensions.json` (Rojo, Luau LSP).

Detaylı Türkçe rehber: proje Context `docs/rojo-setup.md`.

## Her oturum — canlı senkron (önerilen)

PowerShell, proje kökü:

```powershell
.\scripts\dev.ps1
```

Studio:

1. **File → Open** ile mevcut place veya yeni Baseplate.
2. **Plugins → Rojo → Connect** → Host `127.0.0.1`, Port `34872` (`dev.ps1` penceresi açık kalmalı).
3. **Play** — `src/` değişiklikleri kaydedince Studio otomatik güncellenir.

Agent kod değiştirdiğinde kullanıcıya hatırlat: `rojo serve` açık kalsın, Studio bağlı olsun.

## Hızlı önizleme — tek dosya (Rojo kapalı)

Repoda önceden üretilmiş place:

```powershell
.\scripts\studio-open.ps1
```

veya `build\MinigameHub.rbxlx` dosyasına çift tık (Roblox Studio ile açılır).

Place dosyası anlık görüntüdür; **aktif geliştirme için `rojo serve` + Connect kullan.**

Place'i yeniden üretmek:

```powershell
rojo build -o build/MinigameHub.rbxlx
```

## Repo haritası (Rojo)

| Kaynak | Studio |
|--------|--------|
| `src/Server` | ServerScriptService.Server |
| `src/Client` | StarterPlayerScripts.Client |
| `src/Shared` | ReplicatedStorage.Shared |
| `assets/Workspace/Hub` | Workspace.Hub |
| `assets/ReplicatedStorage/TycoonPrefabs` | ReplicatedStorage.TycoonPrefabs |

## Play test kontrol listesi

- Output: `[HybridCasualHub] Server initialized` / `Client initialized`
- Hub: Tycoon plot, Runner finish line, SwarmBoss
- DataStore: place **yayınlanmış** experience olmalı (ProfileService coin)

## Agent kuralları

- Asker/boss için yüzlerce `.Touched` kullanma; sunucu matematik + istemci VFX.
- Tycoon satın alma: maliyet yalnızca sunucuda `TycoonConfig` + `DataService`.
- Yeni Remote: `Shared/Remotes.lua` + `RemotesService` + istemci/sunucu dinleyici.

## Sık sorunlar

| Belirti | Çözüm |
|---------|--------|
| Cursor'da "Rojo skill" yok | Repoyu aç; skill `.cursor/skills/rojo-studio/` — projeyi yeniden yükle veya Agent'a "rojo-studio skill kullan" de |
| Connect başarısız | `rojo serve` çalışıyor mu, firewall 34872 |
| Script yok | Connect sonrası proje kökünü doğru seç |
| Eklenti görünmüyor | Studio yeniden başlat, `%LOCALAPPDATA%\Roblox\Plugins` |
