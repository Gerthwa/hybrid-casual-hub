# Minigame Hub (Roblox)

Reklam tarzı minigame koleksiyonu hub projesi. Kaynak kod Rojo ile Roblox Studio’ya senkronize edilir.

## Gereksinimler

- [Roblox Studio](https://create.roblox.com/)
- [Aftman](https://github.com/LPGhatguy/aftman) (önerilen) veya elle kurulmuş Rojo CLI

## Kurulum (CLI)

```bash
# Aftman yoksa: https://github.com/LPGhatguy/aftman#installation
# İlk kez: aftman trust rojo-rbx/rojo   (veya: aftman add rojo-rbx/rojo@7.7.0)
aftman install
rojo --version
```

Windows ve Studio eklentisi adımları için proje notlarındaki [Rojo kurulum rehberi](cursor.agent://project/context/docs/rojo-setup.md).

## Geliştirme

```bash
rojo serve
```

Studio’da Rojo eklentisinden **Connect** ile `localhost:34872` (varsayılan port) adresine bağlanın.

## Proje yapısı

| Yol | Studio |
|-----|--------|
| `src/server` | `ServerScriptService.Server` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared` | `ReplicatedStorage.Shared` |
