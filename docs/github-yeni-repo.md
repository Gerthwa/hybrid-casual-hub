# GitHub’a yeni repo olarak taşıma

Bu reponun tamamını **Burak Kutnu** hesabındaki yeni bir GitHub deposuna taşıyabilirsin. Cloud Agent token’ı gerekmez; işlem **senin Windows PC’nde** yapılır.

## Ön koşullar

- [Git for Windows](https://git-scm.com/download/win) kurulu
- Bu klasör zaten bir git deposu (`main` dalında tam proje: Rojo, Wally, tycoon, boss, `scripts\BASLA.bat`, vb.)
- GitHub’da **boş** bir repo oluşturmuş ol (README, .gitignore veya lisans **ekleme** — “Create empty repository”)

Önerilen repo adı: **`hybrid-casual-hub`** (veya `minigame-hub`)

---

## A — Önerilen: PowerShell script

1. GitHub → **New repository** → isim ver → **boş** oluştur
2. Repo sayfasından **HTTPS** veya **SSH** URL’ini kopyala  
   Örnek: `https://github.com/bkutnu11/hybrid-casual-hub.git`
3. Proje **kök** klasöründe PowerShell aç:

```powershell
cd C:\Projects\hybrid-casual-hub   # senin klon/yol
.\scripts\github-bagla.ps1 -RepoUrl "https://github.com/KULLANICI/hybrid-casual-hub.git"
```

İlk hub sürümü için etiket de göndermek istersen:

```powershell
.\scripts\github-bagla.ps1 -RepoUrl "https://github.com/KULLANICI/hybrid-casual-hub.git" -PushTag
```

Script şunları yapar:

- `git` kurulumunu kontrol eder
- `default.project.json` ile doğru klasörde olduğunu doğrular
- Uzak adı `github` olarak ekler (veya `origin` yoksa `origin` yapar; `origin` başka bir URL’e gidiyorsa `github` kullanır ve ona push eder)
- `main` dalını push eder
- `-PushTag` verildiyse `v0.1.0-hub` etiketini oluşturup gönderir

İlk HTTPS push’ta GitHub **kimlik doğrulama** isteyebilir (Personal Access Token veya `gh auth login`). SSH kullanıyorsan anahtarın GitHub’a ekli olmalı.

---

## B — Manuel git komutları

Proje kökünde:

```powershell
git remote -v
```

**Cursor/cloud `origin` varsa** ve GitHub’a taşımak istiyorsan (eski origin’i saklamak için):

```powershell
git remote add github https://github.com/KULLANICI/hybrid-casual-hub.git
git push -u github main
git tag -a v0.1.0-hub -m "Hybrid-casual hub ilk GitHub sürümü"
git push github v0.1.0-hub
```

**Sadece GitHub kullanacaksan** (`origin` yok veya değiştirmek istiyorsan):

```powershell
git remote remove origin    # sadece eski origin’i kaldırmak istiyorsan
git remote add origin https://github.com/KULLANICI/hybrid-casual-hub.git
git push -u origin main
```

---

## Sonraki adım: Local Agent

Repo GitHub’da hazır olduktan sonra PC’de klonlayıp Local Agent ile çalış:

```powershell
git clone https://github.com/KULLANICI/hybrid-casual-hub.git
cd hybrid-casual-hub
```

Detay: Project Context içindeki [Local Agent kurulum](cursor.agent://project/context/docs/local-agent-kurulum.md) belgesi.
