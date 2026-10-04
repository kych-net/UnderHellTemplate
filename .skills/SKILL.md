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
- 包分发文件:根目录下的 `typst.toml`、`lib.typ`、`web.css`、`README.md`、`LICENSE`、`img/`、`languages/`、`example/`、`template/`、`thumbnail.png`。包外的 `.github/`、`.gitcode/`、`.skills/`、`webfonts/` 不随包发布(见 typst.toml exclude)。`web.css` **必须进包**:lib.typ 在 web 模式直接 `read("web.css")`。
- `example/` 与 `template/` 内容同构,需**双份维护**:`example/` 是仓库内示例(在 `exclude` 内,不进下载 bundle);`template/` 是 `typst init @preview/underhell` 的脚手架,**必须进包**(不在 `exclude`),且须自包含(不引用仓库外路径)。`thumbnail.png` 是模板缩略图(长边 ≥1080px),Universe 打包时自动排除,但两个发布 workflow 手工 cp 时要带上。

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

可选的 `[web]` 段(仅网页输出用):

- `body-family` / `header-family` / `comment-family` / `bold-family`:自托管族名,插到对应 `[fonts]` 列表首位(生成 `--uh-*-font` 变量)。
- `[[web.fonts]]` 的 `family` / `file`:逐条生成 `@font-face`(`file` 相对 HTML 输出目录,如 `webfonts/x.woff2`)。
- 不配 `[web]` 时网页按 `[fonts]` 的系统字体回退,不生成 `@font-face`。

## 站点定制参数(默认值=本项目现状,第三方可覆盖)

`品牌名`(品牌名,PDF+网页)、`页脚链接`(`((标签:, 网址:, 提示:), ..)`,网页右上角导航)、
`备案号` / `备案链接`(网页页脚,备案号设为 `""` 则不渲染)、
`主题`(`标题色`/`强调色` 影响 PDF 与网页,`纸色`/`墨色` 仅网页;值为 Typst 颜色或 CSS 色字符串)、
`阅读器`(`默认字号`/`默认字体` + `字号`/`字体` 档位列表,驱动网页阅读器面板)。

主题色通过 `_标题色` / `_强调色` 状态注入:模块级函数(元素/属性表/属性框/人物框/附录/引用/目录)需
`= context {` 包裹后用 `_标题色.get()` 读取,标题 show 规则用局部变量 `heading-fill`。

## 网页输出(web.css / webfonts)

- `make web` 产单栏 HTML。样式**由模板自包含注入**:lib.typ 的 `_网页样式()` 读 `web.css`,把
  `/*UH_WEB_FONTFACE*/`、`/*UH_WEB_FONTVARS*/`、`/*UH_WEB_THEME*/`、`/*UH_WEB_READER*/` 四个锚点
  替换为按 TOML 与参数生成的内容,再 `html.elem("style", ..)` 输出。`web_post.py` 仅做标点/路径修复、
  字面 `#元素[]` 替换与 JS 注入(插件回退),不再负责样式。
- 阅读器面板纯 CSS:`:target` 开合面板,隐藏 radio + `body:has(#uh-fs-N:checked)` 切 `--uh-zoom`(字号)
  与 `--uh-body-font`(字体)。档位 id 为 `uh-fs-0..` / `uh-ft-0..`,由 `阅读器:` 参数长度决定。
- 只在网页输出的内容用 `#if is_web() [ … ]` 包裹(PDF 编译时整段跳过);`is_web()` / `is-web-target()`
  定义在 `lib.typ` 顶部,读 `--input web=true`。文档首页的站内导航段即用此法避开 PDF。
- **坑**:文档顶层若有 `#show text: 标点替换`(如 `文档/内容/index.typ`),该规则会连 `<style>` 里的 CSS 一起
  替换,把 `, ; :` 变成中文标点导致样式表失效——而 `<style>` 内的 text 元素只保留 `text` 字段,
  无法用 lang/fill 等标记区分。故 `_网页样式()` 在输出前加 `/*uh-raw*/` 前缀(`_原样标记`),
  `标点替换` 遇到该前缀原样放过(标记本身是 CSS 注释,留在输出中无害)。
- `make web` 会把 `webfonts/*.woff2` 拷到 `dist/webfonts/`;发布时(.github/workflows/build-web.yml)
  按 HTML 实际用字子集化字体,只保留文中出现的字。
- 字体缺字(如 ▾ 💬)由浏览器回退系统字体,非模板缺陷。

## Typst Universe 发布

- 版本号只改 `typst.toml` 的 `version`;发布用 `.github/workflows/publish-typst.yml`,
  推送 `v*` 标签或手动触发(输入不带 v 前缀的版本号)。
- 流程:校验 typst.toml 版本 → checkout `typst/packages` → 放置包文件
  (typst.toml/lib.typ/web.css/README.md/LICENSE/thumbnail.png/img/languages/example/template)→ fork push → `gh pr create`。
- `[template]` 段(typst.toml):`path = "template"`、`entrypoint = "内容/index.typ"`、`thumbnail = "thumbnail.png"`。模板包须在 `categories` 至少指定一个类别(现有 layout/report 已满足)。改 `template/` 后重导缩略图:`typst compile --package-path <本地包> --root template -f png --pages 1 --ppi 250 template/内容/index.typ thumbnail.png`。
- fork 需配置 `TYPST_PACKAGES_TOKEN`(fine-grained:Contents/Workflow/Pull requests 三项写权限)。
- 包名 `underhell` 下每个版本目录 `packages/preview/underhell/<version>/`,新版本需新建目录,
  勿覆盖旧版本。
