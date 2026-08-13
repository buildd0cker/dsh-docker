#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "[错误] 未检测到 Docker,请先安装 Docker Desktop / docker + compose 插件。"
  exit 1
fi

echo "正在构建并启动 DeepSeek Harness ..."
docker compose up -d --build

echo "启动成功!正在打开浏览器 http://127.0.0.1:3080 ..."
case "$(uname -s)" in
  Darwin) open "http://127.0.0.1:3080" ;;
  *)      xdg-open "http://127.0.0.1:3080" >/dev/null 2>&1 || true ;;
esac