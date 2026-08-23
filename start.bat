@echo off
chcp 65001 >nul
title 张氏族谱 · 本地服务器
cd /d "%~dp0"

set PORT=8000
echo ==========================================
echo   张氏族谱 - 本地预览服务器
echo   http://localhost:%PORT%/index.html
echo   按 Ctrl+C 可停止服务器
echo ==========================================
echo.

:: 自动打开浏览器
start "" "http://localhost:%PORT%/index.html"

:: 优先使用 python，失败则尝试 py 启动器
where python >nul 2>nul
if %errorlevel%==0 (
    python -m http.server %PORT%
    goto :end
)

where py >nul 2>nul
if %errorlevel%==0 (
    py -m http.server %PORT%
    goto :end
)

echo [错误] 未找到 Python，请先安装 Python 3 并加入 PATH。
pause
:end
