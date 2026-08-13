# DeepSeek Harness (dsh) Web UI — Docker 一键启动

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
- **GHCR 包可见性**:ghcr 上的包默认 private,匿名 pull 会 401。请到 GitHub 头像 → Your packages → `dsh-docker` → Package settings,把可见性改为 **public**(或先 `docker login ghcr.io -u obrige`)。

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
- **Linux 下 data/ 属主是 root**:容器以 root 运行,属正常;清理可 `sudo chown -R $(id -u):$(id -g) data`。
- **想用别的 LLM**:Web UI 里 Settings → Models → Add provider,或加自定义 OpenAI 兼容端点。
- **开发者预览版**:官方明确提示会有破坏性变更;不锁版本 = 每次重建都可能升级。
- **原生沙箱**:镜像未加特权,容器内 landlock 沙箱能力有限,日常使用不受影响。

## 参考

- 官方仓库:https://github.com/deepseek-ai/deepseek-harness
- 官方运行方式:`npx @deepseek-ai/dsh web`(需本机 Node.js)
