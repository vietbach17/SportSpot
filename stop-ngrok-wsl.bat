@echo off
chcp 65001 > nul
title Dừng Ngrok Docker (WSL2)
color 0C

echo ================================================================
echo             DUNG CONTAINER NGROK TRONG WSL2
echo ================================================================
echo.
wsl -d Ubuntu -e bash -c "cd /mnt/c/FPTU/Semester/8/PRM393/sport_spot/clone/SportSpot && docker compose down"

echo.
echo [V] Da dung container ngrok thanh cong!
echo.
pause
