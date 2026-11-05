@echo off
chcp 65001 > nul
title SportSpot - Trình Quản Lý Môi Trường Phát Triển (Dev Launcher)
color 0B

:MENU
cls
echo ================================================================
echo       SPORTSPOT - TRÌNH ĐIỀU KHIỂN SERVER (DEV LAUNCHER)
echo ================================================================
echo.
echo   [1] Khoi dong ca Backend va Frontend
echo       - Backend  : http://localhost:5000 (Swagger API)
echo       - Frontend : http://localhost:3000 (Flutter Web / Edge)
echo.
echo   [2] Khoi dong lai toan bo Server (Restart)
echo.
echo   [3] Dung va dong tat ca cua so Server (Stop BE ^& FE)
echo.
echo   [0] Thoat (Exit)
echo.
echo ================================================================
set /p opt="> Vui long chon chuc nang (0-3): "

if "%opt%"=="1" goto START_SERVERS
if "%opt%"=="2" goto RESTART_SERVERS
if "%opt%"=="3" goto STOP_SERVERS
if "%opt%"=="0" goto EXIT_PROG

echo.
echo [!] Lua chon khong hop le. Vui long chon lai!
timeout /t 2 > nul
goto MENU

:START_SERVERS
cls
echo ================================================================
echo           DANG KHOI DONG BACKEND VA FRONTEND...
echo ================================================================
echo.
call :DO_STOP_SILENT
call :DO_START
echo.
echo ================================================================
echo [V] DA KHOI DONG THANH CONG CAC CUA SO SERVER!
echo.
echo  * Backend Swagger : http://localhost:5000
echo  * Frontend App    : http://localhost:3000
echo ================================================================
echo.
echo Nhan phim bat ky de quay lai menu...
pause > nul
goto MENU

:STOP_SERVERS
cls
echo ================================================================
echo            DANG DUNG VA DONG CAC CUA SO SERVER...
echo ================================================================
echo.
echo [*] Dang tat tiến trình va dong cua so Backend ^& Frontend...
call :DO_STOP_SILENT
echo.
echo [V] Da dung server va dong toan bo cua so thanh cong!
echo.
echo Nhan phim bat ky de quay lai menu...
pause > nul
goto MENU

:RESTART_SERVERS
cls
echo ================================================================
echo                 DANG KHOI DONG LAI TOAN BO SERVER...
echo ================================================================
echo.
echo [*] Buoc 1: Dung va dong cac cua so server dang chay...
call :DO_STOP_SILENT
timeout /t 1 > nul
echo.
echo [*] Buoc 2: Khoi dong lai Backend va Frontend...
call :DO_START
echo.
echo [V] Da khoi dong lai toan bo server thanh cong!
echo.
echo Nhan phim bat ky de quay lai menu...
pause > nul
goto MENU

:: ================================================================
:: SUBROUTINES: DO_START & DO_STOP_SILENT
:: ================================================================
:DO_START
echo [*] Dang khoi dong Backend .NET 8 (Port 5000)...
start "SportSpot Backend (Port 5000)" cmd /c "set SPORTSPOT_SERVER=BE && cd /d "%~dp0backend\SportSpot.API" && title SportSpot Backend (Port 5000) && dotnet run --no-launch-profile --urls http://0.0.0.0:5000 & exit 0"

echo [*] Cho Backend on dinh trong 3 giay...
timeout /t 3 > nul

echo [*] Dang khoi dong Frontend Flutter (Port 3000 tren Edge)...
start "SportSpot Frontend (Port 3000)" cmd /c "set SPORTSPOT_SERVER=FE && cd /d "%~dp0frontend" && title SportSpot Frontend (Port 3000) && call flutter run -d edge --web-port 3000 & exit 0"
exit /b 0

:DO_STOP_SILENT
:: 1. Tim cac cua so cmd.exe cua Backend & Frontend, tat tien trinh con (/T) de cmd tu thoat voi exit code 0 (dong luon tab/cua so), sau do ep dong cmd neu con sot
powershell -NoProfile -ExecutionPolicy Bypass -Command "$parents = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'cmd.exe' -and ($_.CommandLine -match 'SPORTSPOT_SERVER|SportSpot\.API|web-port 3000') }; foreach ($p in $parents) { Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $p.ProcessId } | ForEach-Object { taskkill /F /T /PID $_.ProcessId 2>$null | Out-Null } }; Start-Sleep -Milliseconds 400; foreach ($p in $parents) { taskkill /F /T /PID $p.ProcessId 2>$null | Out-Null }" > nul 2>&1

:: 2. Quet them theo Window Title va ten file thuc thi
taskkill /FI "WINDOWTITLE eq SportSpot Backend*" /F /T > nul 2>&1
taskkill /FI "WINDOWTITLE eq SportSpot Frontend*" /F /T > nul 2>&1
taskkill /IM SportSpot.API.exe /F /T > nul 2>&1

:: 3. Giai phong triet de cong 5000 va 3000 (kem /T de dong ca cua so con)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":5000" ^| findstr "LISTENING"') do (
    if not "%%a"=="0" taskkill /F /T /PID %%a > nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING"') do (
    if not "%%a"=="0" taskkill /F /T /PID %%a > nul 2>&1
)
exit /b 0

:EXIT_PROG
exit
