# Rojo baglanti sorunlarini teshis et (Windows) — proje kokunden calistir
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$Port = 34872
$ProjectFile = Join-Path $Root "default.project.json"

Write-Host "=== Rojo teshis (Hybrid Minigame Hub) ===" -ForegroundColor Cyan
Write-Host "Klasor: $Root"
Write-Host ""

if (-not (Test-Path $ProjectFile)) {
    Write-Host "[HATA] default.project.json burada yok. Yanlis klasorde olabilirsin." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] default.project.json bulundu" -ForegroundColor Green

$rojoCmd = Get-Command rojo -ErrorAction SilentlyContinue
if (-not $rojoCmd) {
    Write-Host "[HATA] 'rojo' PATH'te degil. Calistir:" -ForegroundColor Red
    Write-Host "  aftman add rojo-rbx/rojo@7.7.0" 
    Write-Host "  aftman install"
    Write-Host "  Sonra PowerShell'i KAPATIP yeniden ac (PATH guncellenir)."
    exit 1
}
Write-Host "[OK] rojo: $($rojoCmd.Source)" -ForegroundColor Green
Write-Host "     $($(& rojo --version 2>&1))"

$listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    Write-Host "[OK] Port $Port dinleniyor (Rojo muhtemelen acik)." -ForegroundColor Green
} else {
    Write-Host "[UYARI] Port $Port dinlenmiyor — Studio baglanamaz." -ForegroundColor Yellow
    Write-Host "        Cozum: Bu pencereyi acik birakip baska terminalde:" -ForegroundColor Yellow
    Write-Host "        .\scripts\dev.ps1" -ForegroundColor White
}

Write-Host ""
Write-Host "Studio Rojo Connect ayarlari:" -ForegroundColor Cyan
Write-Host "  Host: 127.0.0.1   (localhost calismazsa bunu dene)"
Write-Host "  Port: $Port"
Write-Host ""
Write-Host "Sira: 1) dev.ps1 calisir durumda  2) Studio  3) Connect  4) Play" -ForegroundColor DarkGray
