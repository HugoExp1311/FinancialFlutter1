@echo off
REM ========================================
REM  GIT COMMIT & PUSH HELPER
REM ========================================
REM Script tự động commit và push code lên GitHub
REM ========================================

echo ===================================================
echo   GIT COMMIT ^& PUSH TO GITHUB
echo ===================================================
echo.

REM Kiểm tra có thay đổi không
git status --short
if errorlevel 1 (
    echo [ERROR] Git khong hoat dong! Kiem tra lai.
    pause
    exit /b 1
)

echo.
echo [1/4] Dang add tat ca file thay doi...
git add .

echo.
echo [2/4] Dang commit...
set /p commit_msg="Nhap commit message (hoac Enter de dung mac dinh): "
if "%commit_msg%"=="" (
    set commit_msg=ci: update CI/CD pipeline and configurations
)
git commit -m "%commit_msg%"

echo.
echo [3/4] Dang push len GitHub...
git push origin main

if errorlevel 1 (
    echo.
    echo [WARNING] Push that bai! Thu push len branch develop...
    git push origin develop
)

echo.
echo [4/4] Hoan tat!
echo.
echo ===================================================
echo   THANH CONG! Code da duoc push len GitHub
echo ===================================================
echo.
echo Vao GitHub Actions de xem pipeline chay:
echo https://github.com/YOUR_USERNAME/YOUR_REPO/actions
echo.
pause
