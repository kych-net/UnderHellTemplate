---
name: "underhell-template"
description: "地狱之下(UnderHell)的 Typst 模板开发规范:中文化函数(表格/提示框/属性框/人物框/法术等)、元素系统、字体配置(zh.toml)、网页输出(web.css)与 Typst Universe 发布流程。在修改 模板/ 下 lib.typ、web.css、languages/、typst.toml 或执行发布工作流时调用。"
---

# UnderHell 模板开发规范

本技能面向 `模板/`(UnderHellTemplate 子模块)的 Typst 模板开发。正文文档写作见
`文档/.skills/underhell-docs`,地图生成器见 `程序/地图工具` 自带的 map-tool 技能。

## 仓库边界

- `模板/` 是独立 git 子模块 UnderHellTemplate,已发布至 Typst Universe(`@preview/underhell`)。
- 改动后需在子模块内 commit/push,再更新根仓库子模块指针(默认用根仓库 `推送.sh`)。
- 包分发文件:根目录下的 `typst.toml`、`lib.typ`、`README.md`、`LICENSE`、`img/`、`languages/`、`example/`。包外的 `.github/`、`web.css`、`webfonts/` 仅本项目网页构建用,不随包发布(见 typst.toml exclude)。

## 中文化函数(模板/lib.typ)

所有模板函数使用简体中文名,调用时勿用英文旧名:

| 中文名 | 用途 |
|--------|------|
| `地狱之下模板` | 文档初始化函数(show rule) |
| `元素` | 当前元素系统下的深红名词,可自动链接到标题 |
| `设定元素` | 普通模式=深红文本;传 `level:` 生成带 `<id>` 标签的编号标题 |
| `设置元素系统` | 文档内切换元素系统 |
| `表格` | uhtab:格式化表格,默认 2 列 1:4 |
| `提示框` | breakoutbox:彩色背景方框,可选标题 |
| `属性框` | statbox:D&D 风格属性块 |
| `人物框` | npcbox:NPC 卡片 |
| `法术` | spell:法术卡片 |
| `附录` | appendix |
| `顶部图` / `底部图` | 页面顶部/底部大图 |
| `品牌` | uhbrand:小型大写品牌名"地狱之下" |
| `评论` | 灰色注释(标题字体),`--input 隐藏评论=true` 可隐藏 |

## 元素系统实现

- `元素(id, font: none)`:普通系统直接读 ID 值本身;其他系统从 `元素系统数据`
  (宽表 CSV)查 `id,system,term`。当前系统缺失某元素时回退到 ID。
- `设定元素(id, font: none, level: none)`:无 level 时不生成链接;有 level 时
  生成 `<id>` 锚点标题,`@id` 可交叉引用。
- CSV 只存非普通系统的映射行。`别名` 系统通过名为 `别名` 的元素系统列提供。
- 元素化范围:仅核心概念(地名、生物类别、专有系统名)用 `#元素`;描述性文本不元素化。

## 已知坑(模板)

1. **Typst 函数参数必须用简体中文**(如 `基础层级` 而非 `基礎层级`)。
2. 类型检查用 `type(变量) == str`,勿用 `str(type(...)) == "str"`。
3. `str.match()` 结果用字典键访问(如 `m.text`),勿用数组下标。
4. 闭包变量不能修改外层;累加用 `fold`。
5. `set heading(offset:)` 只对标记标题(`= ×N`)生效,**不作用于** `#heading(level: N)`,
   且 offset 只接受非负值。
6. `#include` 的相对路径以被 include 文件所在位置解析(非调用处)。
7. 斜体 show rule 只设 `font` 不设 `style`——emph 自带 italic,显式 style 会破坏字体变体选择。
8. HTML 输出中 level ≥5 的标题用 `<hx class="lv-x">`(不钳制到 h6),CSS 用
   `[class^="lv-"]` 选择器统一基样式;缩进 5 级 7em、6 级 8em、7 级 9em(每级 +0.5em)。

## 字体(languages/zh.toml)

`lang: "zh"` 才加载中文配置。`[fonts]` 三组:

- `header`:段宁毛笔小楷(标题 + 元素默认)
- `body`:霞鹜文楷等宽(正文)
- `italic`:等距更纱黑体 SC(斜体)

## 网页输出(web.css / webfonts)

- `make web` 产单栏 HTML,`web_post.py` 注入样式与脚本,字体全库 woff2 拷入 `dist/webfonts/`。
- 发布时(.github/workflows/build-web.yml)按 HTML 实际用字子集化字体,只保留文中出现的字。
- 字体缺字(如 ▾ 💬)由浏览器回退系统字体,非模板缺陷。

## Typst Universe 发布

- 版本号只改 `typst.toml` 的 `version`;发布用 `.github/workflows/publish-typst.yml`,
  推送 `v*` 标签或手动触发(输入不带 v 前缀的版本号)。
- 流程:校验 typst.toml 版本 → checkout `typst/packages` → 放置包文件
  (typst.toml/lib.typ/README.md/LICENSE/img/languages/example)→ fork push → `gh pr create`。
- fork 需配置 `TYPST_PACKAGES_TOKEN`(fine-grained:Contents/Workflow/Pull requests 三项写权限)。
- 包名 `underhell` 下每个版本目录 `packages/preview/underhell/<version>/`,新版本需新建目录,
  勿覆盖旧版本。
