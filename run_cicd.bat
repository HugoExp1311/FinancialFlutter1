@echo off
REM ========================================
REM  GITHUB ACTIONS TRIGGER HELPER
REM ========================================
REM Script chạy GitHub Actions workflows từ local
REM Yêu cầu: GitHub CLI (gh) đã được cài đặt
REM ========================================

setlocal enabledelayedexpansion

echo ===================================================
echo   GITHUB ACTIONS - WORKFLOW TRIGGER
echo ===================================================
echo.

REM Kiểm tra GitHub CLI đã cài chưa
gh --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] GitHub CLI chua duoc cai dat!
    echo.
    echo Cai dat bang lenh:
    echo   winget install --id GitHub.cli
    echo.
    echo Hoac download tai: https://cli.github.com/
    pause
    exit /b 1
)

REM Kiểm tra đã login chưa
gh auth status >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Chua dang nhap GitHub CLI!
    echo.
    echo Dang nhap bang lenh:
    gh auth login
    if errorlevel 1 (
        echo [ERROR] Dang nhap that bai!
        pause
        exit /b 1
    )
)

:MENU
cls
echo ╔════════════════════════════════════════════════════════╗
echo ║       GITHUB ACTIONS - WORKFLOW TRIGGER MENU          ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo 📋 AVAILABLE WORKFLOWS:
echo.
echo   1. Main Pipeline          - Build, test toan bo he thong
echo   2. Dependency Check       - Kiem tra dependencies
echo   3. Release Management     - Tao release + tag moi
echo.
echo   4. View Workflow Runs     - Xem lich su chay
echo   5. View Latest Run        - Xem run gan nhat
echo.
echo   0. Exit
echo.
set /p choice="Chon workflow (0-5): "

if "%choice%"=="1" goto MAIN_PIPELINE
if "%choice%"=="2" goto DEPENDENCY_CHECK
if "%choice%"=="3" goto RELEASE_MANAGEMENT
if "%choice%"=="4" goto VIEW_RUNS
if "%choice%"=="5" goto VIEW_LATEST
if "%choice%"=="0" goto EXIT
echo.
echo [ERROR] Lua chon khong hop le!
timeout /t 2 >nul
goto MENU

:MAIN_PIPELINE
echo.
echo ========================================
echo   MAIN PIPELINE
echo ========================================
echo.
echo Workflow nay se:
echo   - Analyze Flutter code
echo   - Build Web ^& Android
echo   - Test microservices
echo   - Build Docker images
echo   - Integration test
echo.
set /p confirm="Ban co chac chan? (y/N): "
if /i not "%confirm%"=="y" goto MENU

echo.
echo [*] Dang trigger workflow...
gh workflow run main.yml

if errorlevel 1 (
    echo [ERROR] Khong the trigger workflow!
    pause
    goto MENU
)

echo.
echo [SUCCESS] Da trigger Main Pipeline!
echo.
echo Xem tien do tai:
gh workflow view main.yml --web
timeout /t 3 >nul
goto MENU

:DEPENDENCY_CHECK
echo.
echo ========================================
echo   DEPENDENCY CHECK
echo ========================================
echo.
echo Workflow nay se:
echo   - Kiem tra outdated packages
echo   - Security vulnerability scan
echo   - Docker image scan
echo.
set /p confirm="Ban co chac chan? (y/N): "
if /i not "%confirm%"=="y" goto MENU

echo.
echo [*] Dang trigger workflow...
gh workflow run dependency-check.yml

if errorlevel 1 (
    echo [ERROR] Khong the trigger workflow!
    pause
    goto MENU
)

echo.
echo [SUCCESS] Da trigger Dependency Check!
echo.
echo Xem tien do tai:
gh workflow view dependency-check.yml --web
timeout /t 3 >nul
goto MENU

:RELEASE_MANAGEMENT
echo.
echo ========================================
echo   RELEASE MANAGEMENT
echo ========================================
echo.
echo Workflow nay se:
echo   - Tao Git tag moi
echo   - Build APK ^& Web
echo   - Tao GitHub Release
echo   - Upload artifacts
echo.
set /p version="Nhap version (vd: 1.0.0) hoac Enter de auto: "

echo.
set /p confirm="Ban co chac chan? (y/N): "
if /i not "%confirm%"=="y" goto MENU

echo.
echo [*] Dang trigger workflow...

if "%version%"=="" (
    gh workflow run release.yml
) else (
    gh workflow run release.yml -f version=%version%
)

if errorlevel 1 (
    echo [ERROR] Khong the trigger workflow!
    pause
    goto MENU
)

echo.
echo [SUCCESS] Da trigger Release Management!
echo.
echo Xem tien do tai:
gh workflow view release.yml --web
timeout /t 3 >nul
goto MENU

:VIEW_RUNS
echo.
echo ========================================
echo   WORKFLOW RUNS HISTORY
echo ========================================
echo.
gh run list --limit 10
echo.
pause
goto MENU

:VIEW_LATEST
echo.
echo ========================================
echo   LATEST WORKFLOW RUN
echo ========================================
echo.
gh run view
echo.
echo Xem chi tiet tren web? (y/N): 
set /p open_web=""
if /i "%open_web%"=="y" (
    gh run view --web
)
pause
goto MENU

:EXIT
echo.
echo Tam biet!
exit /b 0
