# ========================================
# 🐛 DEBUG HELPER SCRIPT
# ========================================
# Script hỗ trợ debug microservices nhanh chóng
# Sử dụng: .\debug.ps1 [command]
# ========================================

param(
    [Parameter(Position=0)]
    [string]$Command = "menu"
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

# ========================================
# FUNCTIONS
# ========================================

function Show-Menu {
    Clear-Host
    Write-Info "╔════════════════════════════════════════════════════════╗"
    Write-Info "║          🐛 FINANCE AI - DEBUG HELPER                 ║"
    Write-Info "╚════════════════════════════════════════════════════════╝"
    Write-Host ""
    Write-Host "📋 DOCKER COMMANDS:"
    Write-Host "  1. logs-all        - Xem logs tất cả services"
    Write-Host "  2. logs-trans      - Xem logs Transaction Service"
    Write-Host "  3. logs-chat       - Xem logs Chatbot Service"
    Write-Host "  4. logs-gateway    - Xem logs API Gateway"
    Write-Host ""
    Write-Host "🔧 SERVICE MANAGEMENT:"
    Write-Host "  5. restart-all     - Restart tất cả services"
    Write-Host "  6. restart-trans   - Restart Transaction Service"
    Write-Host "  7. restart-chat    - Restart Chatbot Service"
    Write-Host "  8. rebuild-trans   - Rebuild Transaction Service"
    Write-Host "  9. rebuild-chat    - Rebuild Chatbot Service"
    Write-Host ""
    Write-Host "🔍 DEBUGGING:"
    Write-Host "  10. shell-trans    - Vào shell của Transaction Service"
    Write-Host "  11. shell-gateway  - Vào shell của API Gateway"
    Write-Host "  12. check-env      - Kiểm tra biến môi trường"
    Write-Host "  13. test-api       - Test API endpoints"
    Write-Host ""
    Write-Host "🧹 CLEANUP:"
    Write-Host "  14. clean          - Dọn dẹp Docker (containers + images)"
    Write-Host "  15. clean-all      - Dọn dẹp toàn bộ (bao gồm volumes)"
    Write-Host ""
    Write-Host "0. Exit"
    Write-Host ""
}

function Show-Logs-All {
    Write-Info "📋 Đang xem logs của tất cả services..."
    Set-Location microservices
    docker-compose logs -f
}

function Show-Logs-Transaction {
    Write-Info "📋 Đang xem logs của Transaction Service..."
    Set-Location microservices
    docker-compose logs -f transaction_service
}

function Show-Logs-Chatbot {
    Write-Info "📋 Đang xem logs của Chatbot Service..."
    Set-Location microservices
    docker-compose logs -f chatbot_service
}

function Show-Logs-Gateway {
    Write-Info "📋 Đang xem logs của API Gateway..."
    Set-Location microservices
    docker-compose logs -f api_gateway
}

function Restart-All {
    Write-Info "🔄 Đang restart tất cả services..."
    Set-Location microservices
    docker-compose restart
    Write-Success "✅ Đã restart tất cả services!"
}

function Restart-Transaction {
    Write-Info "🔄 Đang restart Transaction Service..."
    Set-Location microservices
    docker-compose restart transaction_service
    Write-Success "✅ Đã restart Transaction Service!"
}

function Restart-Chatbot {
    Write-Info "🔄 Đang restart Chatbot Service..."
    Set-Location microservices
    docker-compose restart chatbot_service
    Write-Success "✅ Đã restart Chatbot Service!"
}

function Rebuild-Transaction {
    Write-Info "🔨 Đang rebuild Transaction Service..."
    Set-Location microservices
    docker-compose up -d --build --no-deps transaction_service
    Write-Success "✅ Đã rebuild Transaction Service!"
}

function Rebuild-Chatbot {
    Write-Info "🔨 Đang rebuild Chatbot Service..."
    Set-Location microservices
    docker-compose up -d --build --no-deps chatbot_service
    Write-Success "✅ Đã rebuild Chatbot Service!"
}

function Enter-Shell-Transaction {
    Write-Info "🐚 Đang vào shell của Transaction Service..."
    Write-Warning "Gõ 'exit' để thoát"
    Set-Location microservices
    docker exec -it mcr_transaction_service sh
}

function Enter-Shell-Gateway {
    Write-Info "🐚 Đang vào shell của API Gateway..."
    Write-Warning "Gõ 'exit' để thoát"
    Set-Location microservices
    docker exec -it mcr_api_gateway sh
}

function Check-Environment {
    Write-Info "🔍 Đang kiểm tra biến môi trường..."
    Write-Host ""
    Write-Host "=== Transaction Service ===" -ForegroundColor Yellow
    docker exec mcr_transaction_service env | Select-String "SUPABASE|PORT|HOST"
    Write-Host ""
    Write-Host "=== Chatbot Service ===" -ForegroundColor Yellow
    docker exec mcr_chatbot_service env | Select-String "N8N|PORT|HOST"
    Write-Host ""
    Write-Success "✅ Hoàn tất!"
}

function Test-API {
    Write-Info "🧪 Đang test API endpoints..."
    Write-Host ""
    
    Write-Host "Testing API Gateway Health..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -Method GET -TimeoutSec 5
        Write-Success "✅ API Gateway: OK (Status: $($response.StatusCode))"
    } catch {
        Write-Error "❌ API Gateway: FAILED"
    }
    
    Write-Host ""
    Write-Host "Testing Transaction Service..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/transactions" -Method GET -TimeoutSec 5
        Write-Success "✅ Transaction Service: OK (Status: $($response.StatusCode))"
    } catch {
        Write-Error "❌ Transaction Service: FAILED"
    }
    
    Write-Host ""
    Write-Success "✅ Test hoàn tất!"
}

function Clean-Docker {
    Write-Warning "⚠️  Cảnh báo: Lệnh này sẽ xóa tất cả containers và images!"
    $confirm = Read-Host "Bạn có chắc chắn? (y/N)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        Write-Info "🧹 Đang dọn dẹp Docker..."
        Set-Location microservices
        docker-compose down
        docker system prune -f
        Write-Success "✅ Đã dọn dẹp Docker!"
    } else {
        Write-Info "Đã hủy."
    }
}

function Clean-All {
    Write-Warning "⚠️  CẢNH BÁO: Lệnh này sẽ xóa TOÀN BỘ (bao gồm volumes/data)!"
    $confirm = Read-Host "Bạn có CHẮC CHẮN? (y/N)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        Write-Info "🧹 Đang dọn dẹp toàn bộ..."
        Set-Location microservices
        docker-compose down -v
        docker system prune -af --volumes
        Write-Success "✅ Đã dọn dẹp toàn bộ!"
    } else {
        Write-Info "Đã hủy."
    }
}

# ========================================
# MAIN LOGIC
# ========================================

switch ($Command) {
    "menu" {
        while ($true) {
            Show-Menu
            $choice = Read-Host "Chọn lệnh (0-15)"
            
            switch ($choice) {
                "1" { Show-Logs-All }
                "2" { Show-Logs-Transaction }
                "3" { Show-Logs-Chatbot }
                "4" { Show-Logs-Gateway }
                "5" { Restart-All }
                "6" { Restart-Transaction }
                "7" { Restart-Chatbot }
                "8" { Rebuild-Transaction }
                "9" { Rebuild-Chatbot }
                "10" { Enter-Shell-Transaction }
                "11" { Enter-Shell-Gateway }
                "12" { Check-Environment }
                "13" { Test-API }
                "14" { Clean-Docker }
                "15" { Clean-All }
                "0" { 
                    Write-Success "👋 Tạm biệt!"
                    exit 
                }
                default { 
                    Write-Error "❌ Lựa chọn không hợp lệ!"
                    Start-Sleep -Seconds 2
                }
            }
            
            if ($choice -ne "0") {
                Write-Host ""
                Read-Host "Nhấn Enter để tiếp tục"
            }
        }
    }
    "logs-all" { Show-Logs-All }
    "logs-trans" { Show-Logs-Transaction }
    "logs-chat" { Show-Logs-Chatbot }
    "logs-gateway" { Show-Logs-Gateway }
    "restart-all" { Restart-All }
    "restart-trans" { Restart-Transaction }
    "restart-chat" { Restart-Chatbot }
    "rebuild-trans" { Rebuild-Transaction }
    "rebuild-chat" { Rebuild-Chatbot }
    "shell-trans" { Enter-Shell-Transaction }
    "shell-gateway" { Enter-Shell-Gateway }
    "check-env" { Check-Environment }
    "test-api" { Test-API }
    "clean" { Clean-Docker }
    "clean-all" { Clean-All }
    default {
        Write-Error "❌ Lệnh không hợp lệ: $Command"
        Write-Info "Sử dụng: .\debug.ps1 [command]"
        Write-Info "Hoặc chạy: .\debug.ps1 để xem menu"
    }
}
