@echo off
chcp 65001 >nul
color 0B

REM Ep thu muc chay ve dung goc cua file bat
cd /d "%~dp0"

echo ===================================================
echo   KHOI DONG HE SINH THAI MICROSERVICES (WEB DOCKER)
echo ===================================================

echo.
echo [1/3] Kiem tra va danh thuc Docker Desktop...
echo Dang bat module N8N...
REM docker start n8n_rss_demo

echo.
echo [2/3] Khoi dong cac Microservices (Transaction, Chatbot, API Gateway)...
cd microservices
REM docker-compose up -d --build
docker-compose up -d 
echo Dang xoa cache DNS cho API Gateway...
docker-compose restart api_gateway
REM Mo rieng terminal moi de giam sat log thoi gian thuc
start cmd /k "docker-compose logs -f"
cd ..

echo.
echo [3/3] Khoi dong ung dung Flutter Client (Window Desktop)...
cd app
flutter run -d windows

pause
