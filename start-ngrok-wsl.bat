@echo off
chcp 65001 > nul
title Khởi Động Ngrok Docker (WSL2)
color 0A

echo ================================================================
echo         KHOI DONG NGROK DOCKER QUA WSL2 (UBUNTU)
echo ================================================================
echo.
echo [*] Dang khoi dong container ngrok va ket noi Backend...
wsl -d Ubuntu -e bash -c "cd /mnt/c/FPTU/Semester/8/PRM393/sport_spot/clone/SportSpot && ./run-ngrok-wsl.sh"

echo.
echo ================================================================
echo [V] HOAN TAT!
echo  * Web UI Dashboard : http://localhost:4040
echo ================================================================
echo.
pause
