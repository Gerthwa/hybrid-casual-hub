# Hybrid-Casual Hub — Windows geliştirme sunucusu (Rojo)
# Kullanım: PowerShell'de proje kökünden:  .\scripts\dev.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

function Require-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Host "HATA: '$name' bulunamadi. Once Aftman kurun: https://github.com/LPGhatguy/aftman" -ForegroundColor Red
        exit 1
    }
}

Require-Command "aftman"
Require-Command "wally"
Require-Command "rojo"

Write-Host ">> aftman install" -ForegroundColor Cyan
aftman install

Write-Host ">> wally install" -ForegroundColor Cyan
wally install

Write-Host ""
Write-Host "Rojo sunucusu baslatiliyor. Studio: Plugins -> Rojo -> Connect -> localhost:34872" -ForegroundColor Green
Write-Host "Durdurmak icin Ctrl+C" -ForegroundColor DarkGray
Write-Host ""

rojo serve
