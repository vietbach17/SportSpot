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
echo   [3] Dung tat ca Server (Stop Backend va Frontend)
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

:: 1. Kiem tra va khoi dong Backend tai cong 5000
echo [*] Dang khoi dong Backend .NET 8 (Port 5000)...
start "SportSpot Backend (Port 5000)" cmd /k "cd /d %~dp0backend\SportSpot.API && title SportSpot Backend (Port 5000) && dotnet run --urls http://localhost:5000"

echo [*] Cho Backend on dinh trong 3 giay...
timeout /t 3 > nul

:: 2. Khoi dong Frontend Flutter tai cong 3000
echo [*] Dang khoi dong Frontend Flutter (Port 3000 tren Edge)...
start "SportSpot Frontend (Port 3000)" cmd /k "cd /d %~dp0frontend && title SportSpot Frontend (Port 3000) && flutter run -d edge --web-port 3000"

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
echo                 DANG DUNG CAC TIEN TRINH SERVER...
echo ================================================================
echo.

echo [*] Dang tat cac cua so Backend va Frontend...
taskkill /FI "WINDOWTITLE eq SportSpot Backend*" /F /T > nul 2>&1
taskkill /FI "WINDOWTITLE eq SportSpot Frontend*" /F /T > nul 2>&1
taskkill /IM SportSpot.API.exe /F /T > nul 2>&1

:: Giai phong cac cong 5000 va 3000 neu con treo
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000') do (
    taskkill /F /PID %%a > nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :3000') do (
    taskkill /F /PID %%a > nul 2>&1
)

echo.
echo [V] Da dung toan bo cac server thanh cong!
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
echo [*] Buoc 1: Dung cac server dang chay...
taskkill /FI "WINDOWTITLE eq SportSpot Backend*" /F /T > nul 2>&1
taskkill /FI "WINDOWTITLE eq SportSpot Frontend*" /F /T > nul 2>&1
taskkill /IM SportSpot.API.exe /F /T > nul 2>&1

for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000') do (
    taskkill /F /PID %%a > nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :3000') do (
    taskkill /F /PID %%a > nul 2>&1
)

timeout /t 2 > nul

echo [*] Buoc 2: Bat lai Backend (Port 5000)...
start "SportSpot Backend (Port 5000)" cmd /k "cd /d %~dp0backend\SportSpot.API && title SportSpot Backend (Port 5000) && dotnet run --urls http://localhost:5000"

timeout /t 3 > nul

echo [*] Buoc 3: Bat lai Frontend (Port 3000)...
start "SportSpot Frontend (Port 3000)" cmd /k "cd /d %~dp0frontend && title SportSpot Frontend (Port 3000) && flutter run -d edge --web-port 3000"

echo.
echo [V] Da khoi dong lai toan bo server thanh cong!
echo.
echo Nhan phim bat ky de quay lai menu...
pause > nul
goto MENU

:EXIT_PROG
exit
