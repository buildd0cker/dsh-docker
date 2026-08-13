#!/bin/sh
set -e

# 背景:dsh web 默认只绑定 127.0.0.1,且当前版本不支持 --host 0.0.0.0。
# 因此让 dsh 监听 127.0.0.1:3081,再用 socat 在 0.0.0.0:3080 上做转发,
# 这样宿主机通过端口映射即可访问,Windows/macOS/Linux 都适用。
socat TCP-LISTEN:3080,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:3081 &
SOCAT_PID=$!

trap 'kill "$SOCAT_PID" 2>/dev/null || true' TERM INT

# 启动目录即默认工作区(/workspace)
exec dsh web --port 3081