#!/bin/bash
# Tự động lấy IP của Windows Host từ bên trong WSL2
WIN_IP=$(ip route | grep default | awk '{print $3}')
export BACKEND_HOST=$WIN_IP

echo "================================================"
echo "Khởi động ngrok trong Docker (WSL2)"
echo "Windows Host IP nhận diện: $WIN_IP:5000"
echo "================================================"

docker compose up -d

echo ""
echo "[V] Ngrok Docker đã chạy ngầm thành công!"
echo "👉 Xem Web UI và URL công khai tại: http://localhost:4040"
