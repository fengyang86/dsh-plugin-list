# dsh-plugin-list

**个人精选 DeepSeek Harness (dsh) 插件清单**——一份机器可读的清单 + 一条命令，让多台电脑装出同一份插件集合。

> 为什么不用 awesome 列表：那是"别人筛选的"；这里是**你自己审过、自己常用**的，而且可以直接被脚本消费。

## 快速开始

```powershell
# 1. 克隆（新机器）
git clone https://github.com/fengyang86/dsh-plugin-list.git

# 2. 预览将安装什么
pwsh ./install.ps1 -DryRun

# 3. 安装（dsh 在 PATH 上时）
pwsh ./install.ps1

# 源码运行环境（dsh checkout 目录里）：
pwsh ./install.ps1 -Dsh "pnpm dsh"
```

**多机同步**：新机器重复上面步骤即可；清单更新后 `git pull` 再跑一次 install.ps1（已装的会自动跳过）。

## 清单格式（plugins.json）

```jsonc
{
  "version": 1,
  "profile": "web",
  "plugins": [
    {
      "name": "dsh-spotlight",                    // 显示名
      "spec": "@0xsline/dsh-spotlight",           // dsh plugin add 的 spec（npm 包名或 link:路径）
      "category": "ui",                            // 分类（ui / market / personal ...）
      "description": "命令面板",
      "repo": "https://github.com/...",            // 可选：来源仓库
      "platforms": ["win32", "darwin", "linux"],   // 可选：平台过滤，缺省 = 全平台
      "local": true                                // 可选：本地插件（spec 因机器而异，用 local.json 覆盖）
    }
  ]
}
```

## 本地插件（每台机器不同）

自己开发的插件用 `link:` 挂载，路径因机器而异：

1. 复制 `local.example.json` 为 `local.json`（已 gitignore）
2. 把本机的 spec 填进去
3. install.ps1 遇到 `local: true` 的条目会读 `local.json`；没配置就跳过

## 添加新插件（流程）

1. 先试用（`dsh plugin --profile web add <spec>`），确认好用、且审过源码
2. 在 `plugins.json` 里加一项（包名可用 `gh api repos/<owner>/<repo>/contents/package.json` 查）
3. 提交 PR / 直接 push

## 安全提醒

第三方插件以**你的权限**运行：能读文件、用凭据、联网。装之前先看源码；不熟的东西别装进清单。
