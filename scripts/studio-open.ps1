# Minigame Hub — Roblox Studio'da place ac (Windows)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$PlacePath = Join-Path $Root "build\MinigameHub.rbxlx"

if (-not (Test-Path $PlacePath)) {
    Write-Host "Place dosyasi yok; rojo build calistiriliyor..." -ForegroundColor Yellow
    if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) {
        Write-Host "HATA: rojo bulunamadi. Once: aftman install" -ForegroundColor Red
        exit 1
    }
    New-Item -ItemType Directory -Force -Path (Join-Path $Root "build") | Out-Null
    rojo build -o $PlacePath
}

Write-Host "Aciliyor: $PlacePath" -ForegroundColor Green
Start-Process $PlacePath

Write-Host ""
Write-Host "Canli gelistirme icin ayrica: .\scripts\dev.ps1  -> Studio'da Rojo Connect (localhost:34872)" -ForegroundColor Cyan
