@echo off
chcp 65001 >nul
cd /d "%~dp0"

where docker >nul 2>nul
if errorlevel 1 (
  echo [错误] 未检测到 Docker,请先安装 Docker Desktop 后重试。
  pause
  exit /b 1
)

echo 正在拉取最新镜像并启动 DeepSeek Harness ...
docker compose pull
if errorlevel 1 (
  echo [错误] 拉取镜像失败,请检查网络或镜像可见性。
  pause
  exit /b 1
)
docker compose up -d
if errorlevel 1 (
  echo [错误] 启动失败,请检查上方日志。
  pause
  exit /b 1
)

echo 启动成功!正在打开浏览器 http://127.0.0.1:3080 ...
start "" http://127.0.0.1:3080
pause
