@echo off
chcp 65001 > nul
title "SportSpot - LAN Dev Server (iPhone & Mobile Testing)"
color 0A

REM Lay dia chi IPv4 LAN dang ket noi Internet / Default Gateway
set "LAN_IP="
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "(Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Get-NetIPAddress -AddressFamily IPv4 | Select-Object -First 1).IPAddress"`) do (
    set "LAN_IP=%%a"
)
if "%LAN_IP%"=="" (
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address" /c:"IPv4"') do (
        if "%LAN_IP%"=="" (
            for /f "tokens=1" %%b in ("%%a") do set "LAN_IP=%%b"
        )
    )
)
if "%LAN_IP%"=="" set "LAN_IP=localhost"

set "FRONTEND_URL=http://%LAN_IP%:8080"
set "BACKEND_URL=http://%LAN_IP%:5000"
set "QR_TXT=%TEMP%\sportspot_qr_%LAN_IP%.txt"
set "QR_PNG=%TEMP%\sportspot_qr_%LAN_IP%.png"

REM Kiem tra va don bo nho dem QR neu file loi (nho hon 50 bytes)
if exist "%QR_TXT%" for %%F in ("%QR_TXT%") do if %%~zF lss 50 del "%QR_TXT%" > nul 2>&1
if exist "%QR_PNG%" for %%F in ("%QR_PNG%") do if %%~zF lss 50 del "%QR_PNG%" > nul 2>&1

REM Khoi tao ma QR - ASCII console va file anh PNG
if not exist "%QR_TXT%" curl.exe -s --max-time 3 "https://qrenco.de/%FRONTEND_URL%" > "%QR_TXT%" 2>nul
if exist "%QR_TXT%" for %%F in ("%QR_TXT%") do if %%~zF lss 50 del "%QR_TXT%" > nul 2>&1

if not exist "%QR_PNG%" curl.exe -s --max-time 3 -o "%QR_PNG%" "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=%FRONTEND_URL%" > nul 2>&1
if exist "%QR_PNG%" for %%F in ("%QR_PNG%") do if %%~zF lss 50 del "%QR_PNG%" > nul 2>&1

:MENU
cls
echo ================================================================
echo       SPORTSPOT - TRINH DIEU KHIEN LAN [IPHONE / MOBILE DEV]
echo ================================================================
echo.
echo   [!] IP LAN HIEN TAI CUA MAY TINH: %LAN_IP%
echo   [*] Frontend Web  : %FRONTEND_URL%
echo   [*] Backend API   : %BACKEND_URL%
echo.
if not exist "%QR_TXT%" goto SKIP_MENU_QR
echo   --- QUET MA QR DANG TRUY CAP BANG CAMERA IPHONE [EXPO STYLE] ---
type "%QR_TXT%"
echo.
:SKIP_MENU_QR
echo   [1] Khoi dong ca Backend va Frontend qua LAN (0.0.0.0)
echo   [2] Khoi dong lai toan bo Server LAN (Restart)
echo   [3] Dung tat ca Server LAN (Stop Ports 5000 ^& 8080)
echo   [4] Mo anh Ma QR phong to (Windows Photos / Viewer)
echo   [0] Thoat (Exit)
echo.
echo ================================================================
set "opt="
set /p opt="> Vui long chon chuc nang (0-4): "
if defined opt set "opt=%opt: =%"

if "%opt%"=="1" goto START_SERVERS
if "%opt%"=="2" goto RESTART_SERVERS
if "%opt%"=="3" goto STOP_SERVERS
if "%opt%"=="4" goto SHOW_QR
if "%opt%"=="0" goto EXIT_PROG
if /i "%opt%"=="q" goto EXIT_PROG
if /i "%opt%"=="exit" goto EXIT_PROG

echo.
echo [!] Lua chon khong hop le. Vui long chon lai!
timeout /t 2 > nul 2>&1 || ping -n 3 127.0.0.1 > nul
goto MENU

:START_SERVERS
cls
echo ================================================================
echo        DANG KHOI DONG BACKEND ^& FRONTEND CHO MANG LAN...
echo ================================================================
echo.

REM 1. Khoi dong Backend tai 0.0.0.0:5000
echo [*] Dang khoi dong Backend .NET 8 (0.0.0.0:5000)...
start "SportSpot Backend LAN (Port 5000)" cmd /k "cd /d %~dp0backend\SportSpot.API && title SportSpot Backend LAN (Port 5000) && dotnet run --urls http://0.0.0.0:5000"

echo [*] Cho Backend on dinh trong 3 giay...
timeout /t 3 > nul 2>&1 || ping -n 4 127.0.0.1 > nul

REM 2. Khoi dong Frontend Flutter Web Server tai 0.0.0.0:8080
echo [*] Dang khoi dong Frontend Flutter Web Server (0.0.0.0:8080)...
start "SportSpot Frontend LAN (Port 8080)" cmd /k "cd /d %~dp0frontend && title SportSpot Frontend LAN (Port 8080) && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080"

echo.
echo ================================================================
echo [V] DA KHOI DONG THANH CONG SERVER LAN!
echo.
echo  * Dia chi IPv4 may tinh : %LAN_IP%
echo.
echo  * Tren iPhone / Safari  : %FRONTEND_URL%
echo  * Tren may tinh ca nhan : http://localhost:8080 hoac %FRONTEND_URL%
echo  * Backend Swagger API   : %BACKEND_URL% hoac http://localhost:5000
echo.
if not exist "%QR_TXT%" goto SKIP_START_QR
echo  ================================================================
echo   QUET MA QR DUOI DAY BANG CAMERA IPHONE [EXPO STYLE]:
echo  ================================================================
echo.
type "%QR_TXT%"
echo.
:SKIP_START_QR
echo  Luu y: Dam bao iPhone va May tinh dang bat cung mot mang Wi-Fi!
echo ================================================================
echo.
echo Nhan phim bat ky de quay lai menu...
pause > nul
goto MENU

:SHOW_QR
cls
echo ================================================================
echo               MA QR TRUY CAP CHO IPHONE / MOBILE
echo ================================================================
echo.
echo  * URL Web App  : %FRONTEND_URL%
echo  * Backend API  : %BACKEND_URL%
echo.
if exist "%QR_PNG%" (
    echo [*] Dang mo anh Ma QR phong to trong Windows Photos / Viewer...
    start "" "%QR_PNG%"
)
if not exist "%QR_PNG%" (
    echo [*] Dang mo ma QR tren trinh duyet...
    start "" "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=%FRONTEND_URL%"
)
echo.
if not exist "%QR_TXT%" goto SKIP_SHOW_QR
echo  ================================================================
echo   MA QR TREN CONSOLE [QUET TRUC TIEP BANG CAMERA IPHONE]:
echo  ================================================================
echo.
type "%QR_TXT%"
echo.
:SKIP_SHOW_QR
echo ================================================================
echo.
echo Nhan phim bat ky de quay lai menu...
pause > nul
goto MENU

:STOP_SERVERS
cls
echo ================================================================
echo               DANG DUNG CAC TIEN TRINH SERVER LAN...
echo ================================================================
echo.

echo [*] Dang tat cac cua so Backend va Frontend LAN...
taskkill /FI "WINDOWTITLE eq SportSpot Backend LAN*" /F /T > nul 2>&1
taskkill /FI "WINDOWTITLE eq SportSpot Frontend LAN*" /F /T > nul 2>&1
taskkill /IM SportSpot.API.exe /F /T > nul 2>&1

REM Giai phong cac cong 5000 va 8080 neu con treo
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000') do (
    taskkill /F /PID %%a > nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080') do (
    taskkill /F /PID %%a > nul 2>&1
)

echo.
echo [V] Da dung toan bo cac server LAN thanh cong!
echo.
echo Nhan phim bat ky de quay lai menu...
pause > nul
goto MENU

:RESTART_SERVERS
cls
echo ================================================================
echo               DANG KHOI DONG LAI TOAN BO SERVER LAN...
echo ================================================================
echo.
echo [*] Buoc 1: Dung cac server dang chay...
taskkill /FI "WINDOWTITLE eq SportSpot Backend LAN*" /F /T > nul 2>&1
taskkill /FI "WINDOWTITLE eq SportSpot Frontend LAN*" /F /T > nul 2>&1
taskkill /IM SportSpot.API.exe /F /T > nul 2>&1

for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000') do (
    taskkill /F /PID %%a > nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080') do (
    taskkill /F /PID %%a > nul 2>&1
)

timeout /t 2 > nul 2>&1 || ping -n 3 127.0.0.1 > nul

echo [*] Buoc 2: Bat lai Backend (0.0.0.0:5000)...
start "SportSpot Backend LAN (Port 5000)" cmd /k "cd /d %~dp0backend\SportSpot.API && title SportSpot Backend LAN (Port 5000) && dotnet run --urls http://0.0.0.0:5000"

timeout /t 3 > nul 2>&1 || ping -n 4 127.0.0.1 > nul

echo [*] Buoc 3: Bat lai Frontend (0.0.0.0:8080)...
start "SportSpot Frontend LAN (Port 8080)" cmd /k "cd /d %~dp0frontend && title SportSpot Frontend LAN (Port 8080) && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080"

echo.
echo ================================================================
echo [V] Da khoi dong lai toan bo server LAN thanh cong!
echo.
echo  * Tren iPhone / Safari : %FRONTEND_URL%
echo  * Backend Swagger API  : %BACKEND_URL%
echo.
if not exist "%QR_TXT%" goto SKIP_RESTART_QR
echo  ================================================================
echo   QUET MA QR DUOI DAY BANG CAMERA IPHONE [EXPO STYLE]:
echo  ================================================================
echo.
type "%QR_TXT%"
echo.
:SKIP_RESTART_QR
echo ================================================================
echo.
echo Nhan phim bat ky de quay lai menu...
pause > nul
goto MENU

:EXIT_PROG
exit /b 0
