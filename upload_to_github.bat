@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d "%~dp0"

REM ============ 配置区（按需修改） ============
set "GH_USER=zsjzol"
set "GH_REPO=zsjzol.github.io"
set "BRANCH=main"
set "EMAIL=zsjzol@users.noreply.github.com"
REM ============================================

echo.
echo ==========================================
echo    GitHub Pages 静态页面上传工具
echo    %GH_USER%/%GH_REPO%
echo ==========================================
echo.

REM ---- 检查 Git 是否安装 ----
git --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到 Git，请先安装: https://git-scm.com/
    pause
    exit /b 1
)

REM ---- 获取 Token：优先环境变量 GITHUB_TOKEN，否则隐藏输入 ----
if "%GITHUB_TOKEN%"=="" (
    echo 请输入 GitHub Personal Access Token（输入时不显示）:
    for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$s = Read-Host -AsSecureString 'Token'; [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))"`) do set "TOKEN=%%i"
    echo.
) else (
    set "TOKEN=%GITHUB_TOKEN%"
    echo [信息] 已使用环境变量 GITHUB_TOKEN
)
if "%TOKEN%"=="" (
    echo [错误] 未输入 Token，已退出。
    pause
    exit /b 1
)

set "PUSH_URL=https://%TOKEN%@github.com/%GH_USER%/%GH_REPO%.git"
set "REPO_URL=https://github.com/%GH_USER%/%GH_REPO%.git"

REM ---- 检查远程仓库是否存在 ----
git ls-remote "%PUSH_URL%" HEAD >nul 2>&1
if errorlevel 1 (
    echo.
    echo [错误] 无法访问远程仓库 %GH_USER%/%GH_REPO%
    echo        请确认:
    echo        1. 已在 https://github.com/new 创建同名仓库（必须已创建）
    echo        2. Token 勾选了 repo 或 public_repo 权限
    pause
    exit /b 1
)

REM ---- 检测远程默认分支 ----
for /f "usebackq tokens=2" %%b in (`git ls-remote --symref "%PUSH_URL%" HEAD ^| findstr HEAD`) do set "RB=%%b"
if not "%RB%"=="" (
    for /f "tokens=3 delims=/" %%c in ("%RB%") do set "BRANCH=%%c"
    echo [信息] 远程默认分支: %BRANCH%
)

REM ---- 初始化本地仓库（如需要） ----
if not exist .git (
    echo [1/5] 初始化本地 Git 仓库...
    git init >nul
)
git config user.name "%GH_USER%"
git config user.email "%EMAIL%"
git remote remove origin >nul 2>&1
git remote add origin "%REPO_URL%"

REM ---- 创建 .gitignore 排除 .codebuddy 工具目录 ----
if not exist .gitignore (
    echo .codebuddy/ > .gitignore
    echo [信息] 已创建 .gitignore（排除 .codebuddy）
)

REM ---- 添加文件 ----
echo [2/5] 添加所有文件到暂存区...
git add -A .

REM ---- 提交 ----
echo [3/5] 提交更改...
set "MSG=页面更新 %date% %time%"
git commit -m "%MSG%" >nul 2>&1
if errorlevel 1 (
    echo [提示] 没有新更改可提交，继续执行推送
) else (
    git branch -M %BRANCH%
)

REM ---- 推送 ----
echo [4/5] 推送到 GitHub（分支 %BRANCH%）...
git push "%PUSH_URL%" HEAD:%BRANCH%
if errorlevel 1 (
    echo.
    echo [警告] 直接推送失败（可能远程已有内容），尝试合并后再推...
    git pull "%PUSH_URL%" %BRANCH% --allow-unrelated-histories --no-edit
    if errorlevel 1 (
        echo [错误] 合并失败（可能存在冲突），请手动处理后重新运行本脚本。
        pause
        exit /b 1
    )
    git push "%PUSH_URL%" HEAD:%BRANCH%
)

REM ---- 完成 ----
echo [5/5] 上传完成！
echo.
echo 在线地址: https://%GH_USER%.github.io/
echo 提示: GitHub Pages 部署通常需要 1-2 分钟生效
echo.
pause
