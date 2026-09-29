@echo off
chcp 65001 >nul
title Hybrid Minigame Hub - Rojo Sunucusu
cd /d "%~dp0.."

echo.
echo ========================================
echo   ROJO SUNUCUSU - Bu pencereyi KAPATMA
echo ========================================
echo.
echo Studio baglantisi:
echo   Plugins -^> Rojo -^> Connect
echo   Host: 127.0.0.1
echo   Port: 34872
echo.

where rojo >nul 2>&1
if errorlevel 1 (
    echo [HATA] rojo bulunamadi. Once PowerShell'de:
    echo   aftman add rojo-rbx/rojo@7.7.0
    echo   aftman install
    echo Sonra bu dosyayi tekrar calistir.
    pause
    exit /b 1
)

if not exist "default.project.json" (
    echo [HATA] default.project.json yok. Repo kok klasorunu acik tut.
    pause
    exit /b 1
)

call wally install 2>nul
rojo serve --port 34872
pause
