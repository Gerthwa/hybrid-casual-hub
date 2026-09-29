@echo off
chcp 65001 >nul
cd /d "%~dp0.."

if not exist "build\MinigameHub.rbxlx" (
    where rojo >nul 2>&1
    if errorlevel 1 (
        echo rojo yok - once BASLA.bat veya aftman kurulumu
        pause
        exit /b 1
    )
    if not exist build mkdir build
    rojo build -o build\MinigameHub.rbxlx
)

start "" "build\MinigameHub.rbxlx"
echo Place Studio'da acildi. Canli kod icin BASLA.bat calisir durumda olsun.
