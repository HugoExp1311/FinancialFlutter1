@echo off
title He Thong AI Finance Microservices
echo ===================================================
echo   KHOI DONG HE SINH THAI MICROSERVICES
echo ===================================================

echo [1/4] Kiem tra va danh thuc Docker Desktop...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo Phast hien Docker chua bat! Dang tat bat Docker Desktop ho sep...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo Vui long doi 15 giay cho Docker khoi dong he thong...
    timeout /t 15 /nobreak >nul
)

echo Dang bat module N8N...
docker start n8n_rss_demo 
echo N8N da san sang!

echo.
echo [2/4] Bmo cua Cua Khau (API Gateway Port 3000)...
:: Lệnh start /B cmd /c sẽ chạy nền mà không văng ra 1 tỷ cái cửa sổ rác
start "API Gateway" cmd /k "cd microservices\api_gateway && dart run bin/server.dart"

echo [3/4] Goi thu ngan (Transaction Service Port 3001)...
start "Transaction" cmd /k "cd microservices\transaction_service && dart run bin/server.dart"

echo [4/4] Don Phong Khach (Chatbot Service Port 3002)...
start "Chatbot AI" cmd /k "cd microservices\chatbot_service && dart run bin/server.dart"

echo.
echo ===================================================
echo [5/5] KHOI DONG FLUTTER APP (VUI LONG DOI...)
echo ===================================================
cd app
flutter run -d windows
