# GitHub'a main (ve istege bagli v0.1.0-hub etiketi) push eder.
# Kullanim (repo kokunden): .\scripts\github-bagla.ps1 -RepoUrl "https://github.com/user/repo.git"
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoUrl,

    [switch]$PushTag
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$TagName = "v0.1.0-hub"

function Test-RepoUrl([string]$url) {
    if ($url -match '^(https://github\.com/[\w\.\-]+/[\w\.\-]+(\.git)?|git@github\.com:[\w\.\-]+/[\w\.\-]+(\.git)?)$') {
        return $true
    }
    return $false
}

if (-not (Test-Path (Join-Path $Root "default.project.json"))) {
    Write-Host "HATA: default.project.json yok. Script'i repo KOKUNDEN calistir." -ForegroundColor Red
    exit 1
}

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    Write-Host "HATA: 'git' bulunamadi. Git for Windows kur: https://git-scm.com/download/win" -ForegroundColor Red
    exit 1
}

$RepoUrl = $RepoUrl.Trim()
if (-not (Test-RepoUrl $RepoUrl)) {
    Write-Host "HATA: RepoUrl gecersiz. Ornek:" -ForegroundColor Red
    Write-Host '  https://github.com/kullanici/hybrid-casual-hub.git' -ForegroundColor Yellow
    Write-Host '  git@github.com:kullanici/hybrid-casual-hub.git' -ForegroundColor Yellow
    exit 1
}

$branch = (& git rev-parse --abbrev-ref HEAD 2>&1)
if ($branch -ne "main") {
    Write-Host "UYARI: Aktif dal '$branch' (main degil). Yine de main push edilecek." -ForegroundColor Yellow
}

$remotes = & git remote 2>&1
$pushRemote = $null

if ($remotes -contains "origin") {
    $originUrl = (& git remote get-url origin 2>&1)
    if ($originUrl -match "github\.com") {
        Write-Host ">> origin zaten GitHub: $originUrl" -ForegroundColor Cyan
        & git remote set-url origin $RepoUrl
        $pushRemote = "origin"
    } else {
        Write-Host ">> origin Cursor/cloud ($originUrl); GitHub icin 'github' remote kullaniliyor." -ForegroundColor Cyan
        if ($remotes -contains "github") {
            & git remote set-url github $RepoUrl
        } else {
            & git remote add github $RepoUrl
        }
        $pushRemote = "github"
    }
} else {
    & git remote add origin $RepoUrl
    $pushRemote = "origin"
}

Write-Host ">> git push -u $pushRemote main" -ForegroundColor Green
& git push -u $pushRemote main
if ($LASTEXITCODE -ne 0) {
    Write-Host "HATA: push basarisiz. GitHub kimlik dogrulama ve bos repo kontrol et." -ForegroundColor Red
    exit $LASTEXITCODE
}

if ($PushTag) {
    $tagExists = & git rev-parse -q --verify "refs/tags/$TagName" 2>$null
    if (-not $tagExists) {
        Write-Host ">> git tag $TagName" -ForegroundColor Green
        & git tag -a $TagName -m "Hybrid-casual hub ilk GitHub surumu"
    } else {
        Write-Host ">> Etiket $TagName zaten var, push ediliyor." -ForegroundColor DarkGray
    }
    & git push $pushRemote $TagName
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host ""
Write-Host "Tamam. GitHub: $RepoUrl (remote: $pushRemote)" -ForegroundColor Green
Write-Host "Sonraki adim: PC'de git clone ile bu URL'den cek, Local Agent ac." -ForegroundColor DarkGray
