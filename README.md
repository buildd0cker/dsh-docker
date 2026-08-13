# DeepSeek Harness (dsh) Web UI — Docker 一键启动

DeepSeek 官方只提供 npm / 源码两种运行方式,仓库里没有 Dockerfile。
这是社区自制的 Docker 方案:把 @deepseek-ai/dsh 打包进镜像,**不锁版本**,
每次构建都安装 npm 最新版。

## 目录结构

| 文件 | 作用 |
| --- | --- |
| `Dockerfile` | 基于 node:24-slim,全局安装最新版 @deepseek-ai/dsh |
| `docker-compose.yml` | 端口、数据卷、自动重启配置 |
| `docker-entrypoint.sh` | 启动入口(内含 socat 端口转发) |
| `start.bat` / `start.sh` | 一键构建 + 启动 + 打开浏览器 |
| `data/` | (自动生成)配置、API Key、会话数据,持久化 |
| `workspace/` | (自动生成)你的项目目录,agent 的工作区 |

## 快速开始(3 步)

1. **安装 Docker**:Windows/macOS 装 [Docker Desktop](https://www.docker.com/products/docker-desktop/) 并启动;Linux 装 docker + compose 插件。
2. **解压本 zip**,把要交给 agent 的代码放进 `workspace/` 目录。
3. **一键启动**:
   - Windows:双击 `start.bat`
   - macOS / Linux:`./start.sh`
   - 或者手动执行:`docker compose up -d --build`

浏览器会自动打开 http://127.0.0.1:3080 。

## 首次使用配置

1. 打开 **Settings → Models**,填入 DeepSeek API Key 并保存(密钥存在 `data/.credentials.yaml`,只写不回显)。
2. 点击 **Choose workspace**,选择 `/workspace`(对应宿主机的 `workspace/` 目录)。
3. 新建会话,开始给 agent 派活。

> 也可以把 `DEEPSEEK_API_KEY=xxx` 写进 `data/.env`(容器内会自动加载 `$DSH_HOME/.env`)。

## 常用命令

```bash
docker compose up -d --build   # 构建并启动(更新到最新版也用它)
docker compose logs -f dsh     # 看日志
docker compose restart dsh     # 重启
docker compose down            # 停止(数据保留在 data/ 和 workspace/)
docker compose down -v         # 停止并删除数据卷(慎用)
```

## 常见问题

- **端口被占用**:改 `docker-compose.yml` 里 `"3080:3080"` 左边的数字,如 `"8080:3080"`,然后重新 up。
- **为什么要有 socat?**:官方当前版本不支持 `--host 0.0.0.0`,只监听 127.0.0.1;容器内 socat 把 0.0.0.0:3080 转发到 dsh 的 127.0.0.1:3081,端口映射才能生效。
- **Linux 下 data/ 目录属主是 root**:容器以 root 运行,属正常;想清理可在宿主机 `sudo chown -R $(id -u):$(id -g) data`。
- **想用别的 LLM(OpenAI/Anthropic 等)**:Web UI 里 Settings → Models → Add provider,或加自定义 OpenAI 兼容端点。
- **这是开发者预览版**:官方明确提示会有破坏性变更;不锁版本 = 每次 `up --build` 都可能升级到新版本。
- **原生沙箱**:镜像未加特权,容器内 landlock 沙箱能力有限;日常使用不受影响。

## 参考

- 官方仓库:https://github.com/deepseek-ai/deepseek-harness
- 官方运行方式:`npx @deepseek-ai/dsh web`(需本机 Node.js)