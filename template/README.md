# 示例

示例

![示例图片](附件/示例插图.jpg)

## 项目结构

- `配置.typ` —— 站点配置:标题、作者、元素系统数据
- `Makefile` —— 编译命令
- `内容/` —— 分章正文,每个 `.typ` 都会编译出一份文档
- `脚本/` —— 独立页入口 `页面.typ` 与网页后处理 `web_post.sh`
- `附件/` —— 元素系统数据与素材

## 快速开始

```sh
make pdf    # 内容/ 下全部 .typ → PDF
make web    # 多页站点:各页共用一份 CSS,跨页元素连成链接
make watch  # 监听入口,自动重编
```

## 元素系统一览

同一概念在不同系统下叫不同名字:

| 元素 | 普通 | 别名 | 学术 |
| --- | --- | --- | --- |
| 古龙 | 龙 | 龙 | 古代龙 |
| 巨人 | 巨人 | 石头人 | 巨怪 |

## 族群增长

族群规模按指数增长:

$$
P(t) = P_0 e^{r t}
$$

其中 $P_0$ 是初始规模,$r$ 是增长率。

## 写作约定

- 章节标题用 `=` / `==`,正文照常书写
- 引用概念用 `#元素[古龙]`,取词见 [元素系统一览](#元素系统一览)
- 需要 *斜体*、**粗体**、`行内代码` 时照常使用

> 本文件同时是一份「导入 Markdown」的示例:
> `内容/关于.typ` 用 `cmarker` 把它整个渲染进文档。

详见 <https://typst.app/docs/>。

## 部署网页

`make web` 产出的 `dist/` 是纯静态站点,可直接托管。把下面这份工作流存为
`.github/workflows/web.yml`,推送 `main` 后它会自动构建,并把产物强制推到 `web` 分支;
下面两个平台都按「绑 `web` 分支、平台侧不再构建」来接。

这份文件需要自己建一次:Typst 打包会跳过 `.github/`,该目录不进包,`typst init`
出来的项目里没有它。

```yaml
name: 构建静态网页并发布到 web 分支

# 把 make web 的产物提交到 web 分支,供 Cloudflare Pages / EdgeOne Pages 绑定发布。
on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: 安装 Typst
        run: |
          curl -fL https://github.com/typst/typst/releases/download/v0.15.1/typst-x86_64-unknown-linux-musl.tar.xz -o /tmp/typst.tar.xz
          tar -xf /tmp/typst.tar.xz -C /tmp
          sudo mv /tmp/typst-x86_64-unknown-linux-musl/typst /usr/local/bin/typst

      - name: 检出仓库
        uses: actions/checkout@v4

      - name: 构建网页(make web)
        run: make web

      - name: 推送到 web 分支
        working-directory: dist
        run: |
          git init -q -b web
          git config user.name "web-bot"
          git config user.email "web-bot@users.noreply.github.com"
          git add -A
          git commit -q -m "网页构建:${GITHUB_SHA}"
          git push -f "https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/${{ github.repository }}.git" web
```

### Cloudflare Pages

新建 Pages 项目 → 连接 Git 仓库,构建设置填:

| 项 | 值 |
| --- | --- |
| 生产分支 | `web` |
| 构建命令 | `exit 0` |
| 构建输出目录 | `/` |

### EdgeOne Pages

控制台创建项目 → 导入 Git 仓库,项目配置填:

| 项 | 值 |
| --- | --- |
| 生产分支 | `web` |
| 框架预设 | `Other` |
| 根目录 | `./` |
| 输出目录 | `./` |
| 编译命令 | 留空或 `exit 0`(分支里已是构建好的产物) |

两者都会在 `web` 分支更新后自动重新部署:推 `main` → CI 更新 `web` 分支 → 站点刷新。
不想用 CI 也可以本地 `make web` 后把 `dist/` 手动上传。
