@echo off
chcp 65001 > nul
title SportSpot - Ngrok Tunnel (VietQR PayOS)
color 0A
echo ================================================================
echo         KHOI DONG NGROK TUNNEL CHO PAYOS (SPORTSPOT)
echo ================================================================
echo.
echo [*] Public URL : https://couptative-kickless-eleonor.ngrok-free.dev
echo [*] Forward to : http://localhost:5000
echo [*] Web UI     : http://localhost:4040
echo ================================================================
echo.
.\ngrok.exe http --url=couptative-kickless-eleonor.ngrok-free.dev 5000
