# Hybrid-Casual Hub — Windows geliştirme sunucusu (Rojo)
# Kullanım: PowerShell'de proje kökünden:  .\scripts\dev.ps1
# ONEMLI: Bu pencereyi KAPATMA — rojo serve burada calisir.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$Port = 34872

function Require-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Host "HATA: '$name' bulunamadi." -ForegroundColor Red
        Write-Host "  aftman add rojo-rbx/rojo@7.7.0" 
        Write-Host "  aftman install" 
        Write-Host "PowerShell'i yeniden acip tekrar dene." -ForegroundColor Yellow
        exit 1
    }
}

if (-not (Test-Path (Join-Path $Root "default.project.json"))) {
    Write-Host "HATA: default.project.json yok. Komutu repo KOKUNDEN calistir." -ForegroundColor Red
    exit 1
}

Require-Command "aftman"
Require-Command "wally"
Require-Command "rojo"

Write-Host ">> aftman install" -ForegroundColor Cyan
aftman install

Write-Host ">> wally install" -ForegroundColor Cyan
wally install

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Rojo sunucusu basliyor (port $Port)" -ForegroundColor Green
Write-Host " Bu PowerShell penceresini ACIK BIRAK." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Studio:" -ForegroundColor Cyan
Write-Host "  Plugins -> Rojo -> Connect"
Write-Host "  Host: 127.0.0.1"
Write-Host "  Port: $Port"
Write-Host ""
Write-Host "Baglanamazsan: .\scripts\verify-rojo.ps1" -ForegroundColor DarkGray
Write-Host "Durdurmak: Ctrl+C" -ForegroundColor DarkGray
Write-Host ""

# Acik adres; bazi Windows kurulumlarinda localhost sorunlu olabilir
rojo serve --port $Port
