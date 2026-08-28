# DeepSeek Harness (dsh) Web UI — Docker 一键启动

[![Build](https://img.shields.io/github/actions/workflow/status/obrige/dsh-docker/docker-image.yml?branch=main&label=build&logo=github)](https://github.com/obrige/dsh-docker/actions/workflows/docker-image.yml)
[![GHCR](https://img.shields.io/badge/GHCR-ghcr.io%2Fobrige%2Fdsh-docker-blue?logo=docker&logoColor=white)](https://github.com/obrige/dsh-docker/pkgs/container/dsh-docker)
[![License](https://img.shields.io/github/license/obrige/dsh-docker)](https://github.com/obrige/dsh-docker/blob/main/LICENSE)
[![Stars](https://img.shields.io/github/stars/obrige/dsh-docker?logo=github)](https://github.com/obrige/dsh-docker)

> **EN** — One-click, self-hosted **DeepSeek Harness (dsh) Web UI** via Docker Compose. The Docker image is auto-built by GitHub Actions and published to GHCR, so `docker compose pull && docker compose up -d` runs a DeepSeek AI coding agent / LLM harness with a browser UI in seconds — no Node.js, no local build, always latest. 中文说明见下文。

DeepSeek 官方只提供 npm / 源码两种运行方式,仓库里没有 Dockerfile。
本仓库用 GitHub Actions **在线构建**镜像并推送到 GHCR,本地**不用构建**,
`docker compose` 直接拉取现成镜像,不锁版本。

## 工作原理

- `.github/workflows/docker-image.yml`:推送到 main / 打 tag / 手动触发 / 每周一自动重建
- 构建产物推送到 `ghcr.io/obrige/dsh-docker:latest`
- 本地 `docker compose up` 只做 pull,不做 build

## 目录结构

| 文件/目录 | 作用 |
| --- | --- |
| `.github/workflows/docker-image.yml` | GitHub Actions 在线构建并推送 GHCR |
| `Dockerfile` | 基于 node:24-slim,安装最新版 @deepseek-ai/dsh |
| `docker-compose.yml` | 直接拉取 GHCR 镜像,配置端口、数据卷 |
| `docker-entrypoint.sh` | 启动入口(内含 socat 端口转发) |
| `start.bat` / `start.sh` | 一键拉取镜像 + 启动 + 打开浏览器 |
| `.gitattributes` | 保证 start.bat 以 CRLF 提交 |
| `LICENSE` | MIT 开源协议 |
| `data/` | (自动生成)配置、API Key、会话数据,持久化 |
| `workspace/` | (自动生成)你的项目目录,agent 的工作区 |

## 快速开始(3 步)

1. **安装 Docker**:Windows/macOS 装 [Docker Desktop](https://www.docker.com/products/docker-desktop/) 并启动;Linux 装 docker + compose 插件。
2. **克隆本仓库**,把要交给 agent 的代码放进 `workspace/` 目录(首次运行会自动创建)。
3. **一键启动**:
   - Windows:双击 `start.bat`
   - macOS / Linux:`./start.sh`
   - 或者手动执行:`docker compose pull && docker compose up -d`

浏览器会自动打开 http://127.0.0.1:3080 。

## 首次使用配置

1. 打开 **Settings → Models**,填入 DeepSeek API Key 并保存(密钥存在 `data/.credentials.yaml`,只写不回显)。
2. 点击 **Choose workspace**,选择 `/workspace`(对应宿主机 `workspace/` 目录)。
3. 新建会话,开始给 agent 派活。

> 也可以把 `DEEPSEEK_API_KEY=xxx` 写进 `data/.env`(容器内自动加载 `$DSH_HOME/.env`)。

## 镜像从哪来

镜像由 GitHub Actions 构建,推送地址:`ghcr.io/obrige/dsh-docker:latest`。

- **首次使用前**:先去仓库 Actions 页手动跑一次工作流,或等 push 触发;构建完成后再 `docker compose pull`。
- **更新到最新版**:`docker compose pull && docker compose up -d`(Actions 每周一 03:00 自动重建,也可手动触发 workflow_dispatch)。
- **构建指定版本**:Actions 页 → **Run workflow** → 填 `dsh-version`(如 `0.1.1-rc.2`)即可按该版本编译镜像;留空则用 npm 最新版。
- **GHCR 包可见性**:ghcr 上的包默认 private,匿名 pull 会 401。本仓库的包已设为 **public**,可直接拉取。

## 常用命令

```bash
docker compose pull          # 拉取最新镜像
docker compose up -d         # 启动
docker compose logs -f dsh   # 看日志
docker compose restart dsh   # 重启
docker compose down          # 停止(数据保留在 data/ 和 workspace/)
docker compose down -v       # 停止并删除数据(慎用)
```

## 常见问题

- **端口被占用**:改 `docker-compose.yml` 里 `"3080:3080"` 左边数字,如 `"8080:3080"`,再 up。
- **为什么有 socat?**:官方当前版本不支持 `--host 0.0.0.0`,只监听 127.0.0.1;容器内 socat 把 0.0.0.0:3080 转发到 dsh 的 127.0.0.1:3081。
- **沙箱在容器里能用吗?**:能。dsh 的 Linux 沙箱用 Landlock(无特权 LSM,内核 5.13+ 即可)和 bwrap 双后端,容器内**无需特权、无需加 cap** 即可正常生效,与裸机一致;多个后端都不可用时,dsh 会明确报 `SANDBOX_UNAVAILABLE`(fail-closed),不会静默降级成无沙箱运行。容器本身还额外提供了 PID 命名空间、网络、文件系统视图隔离,比裸机更安全。
- **想让 agent 访问宿主机更多目录?**:最简单的是把代码直接放进 `workspace/`(已挂载为容器内 `/workspace`),选这个工作区即可。想额外挂载别的目录,推荐**相对路径**(以 compose 文件所在目录为基准,换机器、clone 分享都不失效),例如在 `docker-compose.yml` 的 volumes 加一行 `- ./projects:/workspace/extra`,然后 agent 在 Web UI 里选 `/workspace` 后即可读写 `extra/`。
- **需要特殊能力(如 ptrace 调试、Docker-in-Docker)?**:默认最小权限跑;确有必要时给容器加 `cap_add`(如 `SYS_PTRACE`)或 `--privileged`(不推荐),按需放开。
- **Linux 下 data/ 属主是 root**:容器以 root 运行,属正常;清理可 `sudo chown -R $(id -u):$(id -g) data`。
- **想用别的 LLM**:Web UI 里 Settings → Models → Add provider,或加自定义 OpenAI 兼容端点。
- **开发者预览版**:官方明确提示会有破坏性变更;不锁版本 = 每次重建都可能升级。

## 参考

- 官方仓库:https://github.com/deepseek-ai/deepseek-harness
- 官方运行方式:`npx @deepseek-ai/dsh web`(需本机 Node.js)
