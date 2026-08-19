// ============================================================
// 地狱之下模板库 / UnderHell Template Library
// 提供架空世界风格的文档排版组件 / Fictional-world styled document components
// ============================================================

// 主题色定义 / Theme color definitions
#let darkred = rgb("#540808")     // 深红色:用于标题、强调线条 / Dark red: for headings, accent lines
#let darkyellow = rgb("#fcba03")  // 暗黄色:用于二级标题下划线 / Dark yellow: for level-2 heading underline
#let 品牌 = smallcaps("地狱之下")  // 品牌文本(小型大写)/ Brand text (smallcaps)

// 页脚内容生成器 / Footer content generator
// 第 1 页之后显示页脚图片与页码 / Show footer image and page number after page 1
#let footer-content = context {
      if here().page() > 1 {
        place(left+bottom, image("img/footer.svg", width: 100%))
        align(center)[#here().page()]
      }
    }
// 页脚状态:允许在文中动态修改页脚 / Footer state: allows dynamic modification within the document
#let footer = state("footer", footer-content)

// 语言状态:存储当前语言的 TOML 配置 / Language state: stores current language TOML config
// 默认加载英文配置 / Loads English config by default
#let language = state("language", toml("languages/en.toml"))

// ------------------------------------------------------------
// 名词系统 / Nomenclature system
// 每个核心概念用一个"元素"(即普通名词系统的名称)作为 ID。
// 普通名词系统直接读取 ID 的值本身;其他名词系统为同一元素提供不同名词。
// 数据以 CSV(宽表)存储(如 文档/名词系统.csv):首行是各名词系统名,
// 首列是元素 id,单元格为该元素在对应系统下的名词,无名词则留空。
// 由文档通过 csv() 读取后传入 地狱之下模板(nomen-data:) 注入。
// 当前系统缺失某元素时自动回退到普通名词(即 ID)。
// Each core concept is identified by an "元素" (the common-system name).
// The 普通 system reads the ID value directly; other systems provide
// alternative terms. Data is a wide-format CSV (e.g. 文档/名词系统.csv):
// header row = system names, first column = element ids, cells = the term
// under that system (empty if none), read by the document with csv() and
// injected via 地狱之下模板(nomen-data:). Missing elements fall back to
// the common term (the ID) automatically.
// ------------------------------------------------------------

// 名词系统状态:当前系统名,默认普通系统 "普通";数据数组
// Nomenclature state: current system name (default "普通") and data array
#let nomen-state = state("nomen", "普通")
#let nomen-data-state = state("nomen-data", none)

// 在数据中查找 ID 在当前系统中的名词;未找到返回 none
// Look up the term for an ID in a given system within data; none if absent
// 数据为宽表:首行是表头(列名),首列是元素 id,单元格为该元素在对应系统中的名词(可为空)。
// Data is a wide table: header row = system names, first column = element ids,
// cells = that element's term under each system (may be empty).
#let _nomen-lookup(id, system, data) = {
  if data == none or data.len() == 0 {
    return none
  }
  // 确定系统所在列索引 / Find the column index of the system
  let header = data.at(0)
  let col = none
  for j in range(header.len()) {
    if header.at(j) == system {
      col = j
      break
    }
  }
  if col == none {
    return none
  }
  // 逐行查找元素 id / Scan rows for the element id
  for row in data.slice(1) {
    if row.len() > col and row.at(0) == id {
      let term = row.at(col)
      if term != "" {
        return term
      }
    }
  }
  none
}

// 查询某元素在当前名词系统下的名词。
// 普通系统("普通")直接返回元素名(id)本身;
// 其他系统查表,缺失时回退到普通名词(即 id)。
// 返回的文本以深红色标出,默认使用标题字体(header),可用 font 参数覆盖。
// Query the term for an element in the current system.
// The 普通 system just returns the element name (id) itself;
// other systems look it up, falling back to the id when missing.
// The result is rendered in dark red, defaulting to the header font,
// overridable via the font parameter.
#let _元素字体 = state("元素字体", none)

#let 元素(id, font: none) = {
  context {
    let cur = nomen-state.get()
    let data = nomen-data-state.get()
    let t = _nomen-lookup(id, cur, data)
    let term = if t == none { id } else { t }
    let f = if font != none { font } else { _元素字体.get() }
    let args = (fill: darkred)
    if f != none {
      args.font = f
    }
    text(..args)[#term]
  }
}

// 设置当前名词系统 / Set the current nomenclature system
#let set-nomen(name) = nomen-state.update(name)

// 设置名词系统数据(CSV 读取结果)/ Set nomenclature data (csv() result)
#let set-nomen-data(data) = nomen-data-state.update(data)

// ------------------------------------------------------------
// 地狱之下模板:文档主模板 / Main document template
// 用作 #show: 地狱之下模板.with(...) 应用整篇文档样式
// Used via #show: 地狱之下模板.with(...) to apply document-wide styling
//
// 参数 / Parameters:
//   title        - 文档标题(封面大标题)/ Document title (cover headline)
//   author       - 作者 / Author
//   subtitle     - 副标题 / Subtitle
//   cover        - 封面背景图 / Cover background image
//   font-size    - 正文字号(默认 12pt)/ Body font size (default 12pt)
//   paper        - 纸张尺寸(默认 a4)/ Paper size (default a4)
//   logo         - 右下角 logo 图 / Logo image at bottom-right
//   fancy-author - 是否使用花式作者展示(带火焰图案)/ Fancy author display with fire splash
//   add-title    - 封面是否显示标题 / Whether to show title on cover
//   bg           - 正文背景,"default" 使用默认背景,或传入自定义图 / Body background
//   lang         - 语言代码(如 "en"/"zh"/"it"),决定加载哪个 languages/*.toml
//                  Language code, determines which languages/*.toml to load
//   print        - 打印模式:去除背景图/封面图、双栏、宽边距、纯黑文字、简化页脚
//                  默认自动读取编译时输入变量 --input print=true;
//                  文档也可显式传入 print: true/false 覆盖
//                  Print mode: no background/cover images, two columns, wider margins,
//                  pure black text, simplified footer (for ink-saving physical print).
//                  Defaults to reading --input print=true at compile time;
//                  documents can override with print: true/false
//   screen       - 小屏模式:A5 单栏、保留背景与彩色装饰、窄边距、较小字号
//                  适合手机/平板等窄屏设备阅读
//                  默认自动读取编译时输入变量 --input screen=true;
//                  Screen mode: A5 single column, keeps background & colors, narrow margins,
//                  smaller font size. For reading on phones/tablets.
//                  Defaults to reading --input screen=true at compile time
//   nomen        - 名词系统名称,决定 #nomen-term() 的取词来源
//                  默认自动读取编译时输入变量 --input nomen=xxx,缺省为 "普通"
//                  文档也可显式传入 nomen: "xxx" 覆盖
//                  Nomenclature system name; selects which system #nomen-term() draws from.
//                  Defaults to reading --input nomen=xxx at compile time,
//                  falling back to "普通". Documents can override with nomen: "xxx"
//   nomen-data   - 名词系统数据文件位置,由文档在初始化时传入 csv() 读取结果。
//                  所有名词系统集中在同一个 CSV(列: id, system, term);
//                  如 csv("名词系统.csv")。缺省不注入。
//                  Nomenclature data file location: pass the csv() result here,
//                  all systems live in one CSV (columns: id, system, term),
//                  e.g. csv("名词系统.csv"). Not injected by default.
// ------------------------------------------------------------
#let 地狱之下模板(title: "",
              author: "",
              subtitle: "",
              cover: none,
              font-size: 12pt,
              paper: "a4",
              logo: none,
              fancy-author: false,
              add-title: true,
              bg: "default",
              lang: "en",
              print: "print" in sys.inputs and sys.inputs.print == "true",
              screen: "screen" in sys.inputs and sys.inputs.screen == "true",
              nomen: if "nomen" in sys.inputs and sys.inputs.nomen != "" { sys.inputs.nomen } else { "普通" },
              nomen-data: none,
  body) = {
  // 设置文档元数据 / Set document metadata
  set document(author: author, title: title)
  // 段落间距与首行缩进 / Paragraph spacing and first-line indent
  set par(spacing: 0.7em, first-line-indent: (amount: 1.5em, all: false))
  // set heading(numbering: "1.1")

  // 读取语言 TOML,提取字体配置(优先级低于用户在文章中自定义的字体)
  // Load language TOML and extract font config (lower priority than user's custom fonts)
  let lang-toml = if lang == "en" {
    toml("languages/en.toml")
  } else {
    toml("languages/" + lang + ".toml")
  }
  // 解析 [fonts] 段,缺省则使用空字典 / Parse [fonts] section, default to empty dict
  let fonts-cfg = if "fonts" in lang-toml { lang-toml.fonts } else { (:) }
  // 正文字体列表(支持回退)/ Body font list (with fallback)
  let body-fonts = if "body" in fonts-cfg { fonts-cfg.body } else { none }
  // 标题字体列表(支持回退)/ Header font list (with fallback)
  let header-fonts = if "header" in fonts-cfg { fonts-cfg.header } else { none }
  // 构造 text() 的命名参数包,无配置时为空字典 / Build named args for text(); empty dict if none
  let header-font-args = if header-fonts != none { (font: header-fonts) } else { (:) }
  // 元素默认使用标题字体 / Elements default to the header font
  _元素字体.update(header-fonts)
  // 斜体字体列表(支持回退)/ Italic font list (with fallback)
  let italic-fonts = if "italic" in fonts-cfg { fonts-cfg.italic } else { none }

  // 非 en 时更新语言状态 / Update language state when not English
  if lang != "en" {
    language.update(lang-toml)
  }

  // 设置当前名词系统 / Set the current nomenclature system
  nomen-state.update(nomen)
  // 注入名词系统数据(若有)/ Inject nomenclature data if provided
  if nomen-data != none {
    nomen-data-state.update(nomen-data)
  }

  // 标题始终使用深红(打印/普通/小屏均保持红色) / Headings always darkred
  let heading-fill = darkred

  // 一级标题样式:小型大写、深红(打印模式也为深红)/ Level-1 heading: smallcaps, always darkred
  show heading.where(level: 1): it => block(text(
    ..header-font-args,
    size: 1.5em,
    fill: darkred,
    weight: "regular",
    // style: "italic",
    smallcaps(it),
  ))

  // 二级标题样式:带黄色下划线(打印模式去掉下划线)/ Level-2 heading
  show heading.where(
    level: 2
  ): it => block(text(
    ..header-font-args,
    size: 1.5em,

    fill: heading-fill,
    weight: "regular",

  )[
    #box(width: 100%, inset: (bottom: 4pt), stroke: (bottom: if print { 0pt } else { 1pt + darkyellow }))[#smallcaps(it)]
  ])

  // 三级标题样式:深红色、小一号、无下划线 / Level-3 heading: darkred, slightly smaller
  show heading.where(level: 3): it => block(text(
    ..header-font-args,
    size: 1.3em,
    fill: heading-fill,
    weight: "regular",
  )[#smallcaps(it)])

  // 四级标题样式:左色条 + 深红色 / Level-4 heading: left bar accent
  show heading.where(level: 4): it => block[
    #box(
      inset: (left: 8pt),
      stroke: (left: if print { 0pt } else { 3pt + darkyellow }),
      width: 100%,
    )[#text(..header-font-args, size: 1.15em, fill: heading-fill, weight: "regular")[#it]]
  ]

  // 五级标题样式:左侧圆点(垂直居中)+ 深红斜体 / Level-5 heading: left dot (vertically centered) + darkred italic
  show heading.where(level: 5): it => block[
    #grid(
      columns: (auto, 1fr),
      column-gutter: 0.6em,
      align: (center, left),
      [#box(circle(radius: 1.5pt, fill: heading-fill))],
      text(..header-font-args, size: 1em, fill: heading-fill, weight: "regular", style: "italic")[#it],
    )
  ]

  // 六级标题样式:深红、小号、前置 — 符号 / Level-6 heading: darkred, small, "—" prefix
  show heading.where(level: 6): it => block[
    #text(..header-font-args, size: 0.95em, fill: heading-fill, weight: "regular")[
      — #it
    ]
  ]

  // 正文背景图:打印模式禁用;小屏/普通模式保留 / Body background
  let bg-img = if print or bg == none {
    none
  } else if bg == "default" {
    image("img/background.jpg", width: 110%)
  } else {
    bg
  }

  // 小屏模式字号在下方 text-args 中统一设置 / Screen font size set in text-args below
  // 小屏模式使用适中字号(A5 页面)/ Screen mode uses moderate font size for A5

  // 根据模式构造页面参数(必须在 if 块外 set,否则词法作用域不延伸)
  // Build page args based on mode (must set outside if block due to lexical scoping)
  let page-args = if print {
    // 打印模式:双栏、宽边距(装订余量)、无背景、简化页脚(仅页码)
    // Print mode: two columns, wider margins (binding), no background, simple footer
    (
      flipped: false,
      margin: (left: 25mm, right: 20mm, top: 25mm, bottom: 25mm),
      numbering: "1",
      number-align: center,
      columns: 2,
      background: none,
      footer: context {
        if here().page() > 1 {
          align(center)[#here().page()]
        }
      },
    )
  } else if screen {
    // 小屏模式:单栏、窄边距、保留背景、简化页脚
    // Screen mode: single column, narrow margins, keep background, simple footer
    (
      flipped: false,
      margin: (left: 10mm, right: 10mm, top: 15mm, bottom: 15mm),
      numbering: "1",
      number-align: center,
      columns: 1,
      background: bg-img,
      footer: context {
        if here().page() > 1 {
          align(center)[#here().page()]
        }
      },
    )
  } else {
    (
      flipped: false,
      margin: (left: 15mm, right: 15mm, top: 30mm, bottom: 30mm),
      numbering: "1",
      number-align: start,
      columns: 2,
      background: bg-img,
      footer: context {
        let f = footer.get()
        footer.update(footer-content)
        f
      },
    )
  }
  // 小屏模式使用 A5 纸张 / Screen mode uses A5 paper
  let actual-paper = if screen { "a5" } else { paper }
  set page(actual-paper, ..page-args)

  // 副标题非空时追加换行,便于排版 / Append newline to subtitle if non-empty
  if subtitle.len() > 0 {
    subtitle = subtitle + "\n"
  }

  // 封面页 / Front page
  if print {
    // 打印模式封面:纯白背景,黑色文字,无装饰图 / Print cover: white bg, black text
    page(background: none, margin: (top: 40mm, bottom: 20mm), columns: 1)[
      #if add-title {
        place(top + center, text(fill: black, size: 48pt, weight: 800, upper(title)))
      }
      #if subtitle.len() > 0 {
        place(bottom + center, dy: -1cm,
          text(fill: black, size: 18pt)[#subtitle #if not fancy-author {"by " + author}]
        )
      }
    ]
  } else if screen {
    // 小屏模式封面:保留背景图与彩色标题,缩小字号 / Screen cover: keep bg, smaller text
    page(background: cover, margin: (top: 20mm, bottom: 10mm), columns: 1)[
      #if add-title {
        place(top + center,
          box(fill: rgb("#00000066"), inset: 8%, text(fill: white, size: 36pt, weight: 800, upper(title)))
        )
      }
      #if subtitle.len() > 0 {
        place(
          bottom + center,
          dy: -0.2cm,
          box(width: 85%, fill: rgb("#00000066"), inset: (left:8pt, right:8pt, top:8pt, bottom: 8pt), text(fill: white, size: 14pt)[#subtitle #if not fancy-author {"by " + author}]
        ))
      }
    ]
  } else {
    // FRONT PAGE / 封面页(单栏)
    page(background: cover, margin: (top: 10mm, bottom: 5mm),
  columns: 1)[
    #if add-title {
      // 顶部居中大标题 / Top-center large title
      place(
        top + center,
        box(fill: rgb("#00000066"), inset: 10%, text(fill: white, size: 60pt, weight: 800, upper(title)))
      )
     }

      #if subtitle.len() > 0 {
      // 底部副标题(可选作者名)/ Bottom subtitle (with optional author)
      place(
        bottom + center,
        dy: -0.2cm,
        box(width: 80%, fill: rgb("#00000066"), inset: (left:10pt, right:10pt, top:10pt, bottom: 10pt), text(fill: white, size:20pt)[#subtitle #if not fancy-author {"by " + author}]
      ))}

      #if logo != none {
        // 右下角 logo / Logo at bottom-right
        place(dx: 91%, dy: 100%-2.5cm,
          logo // image("img/DMsGuildLogo.jpg", width: 13%)
        )
      }

      #if fancy-author {
        // 花式作者展示:火焰图案 + 作者名 / Fancy author: fire splash + author name
        place(dx: -10%, dy: 73%, image("img/fire_splash.svg", width: 60%))
        place(dx: -10% + 0.7cm, dy: 73% + 0.7cm)[#text(size: 18pt, fill: white, weight: 700)[by #author]]
      }
    ]
  }

  // 应用正文字体(来自语言 TOML,优先级低于用户在文章中 set text(font: ...) 的自定义)
  // Apply body fonts from language TOML; user's #set text(font: ...) in body overrides this
  // 注意:set/show 不能放在 if 块内(词法作用域不延伸到块外),改用参数字典构造后一次性 set
  // Note: set/show inside an if block is lexically scoped and won't leak out; build args first
  // 小屏模式使用适中字号 / Screen mode uses moderate font size
  let actual-font-size = if screen { 13pt } else { font-size }
  let text-args = (size: actual-font-size, lang: lang, fill: black)
  if body-fonts != none {
    text-args.font = body-fonts
  }
  set text(..text-args)

  // 斜体使用独立字体(如等距更紗黑體),优先级低于用户自定义
  // Italic text uses its own font (e.g. Sarasa Mono SC); user rules take precedence.
  // 注意:仅设置 font,不显式设 style——emph 自带 italic,显式 style 会干扰字体选变体
  // Note: set only font, not style; emph already carries italic, an explicit style
  // would break font-variant selection (e.g. pick Regular instead of Italic).
  let italic-args = if italic-fonts != none {
    (font: italic-fonts)
  } else {
    (:)
  }
  show emph: set text(..italic-args)

  body

}


// ------------------------------------------------------------
// uhtab:生成地狱之下风格的表格区块 / UnderHell style table block
//   name     - 表格标题 / Table title
//   columns  - 列宽配置(默认 (1fr, 4fr))/ Column widths
//   breakable - 是否允许跨页 / Whether the block can break across pages
//   contents  - 表格内容(按行展开)/ Table contents (spread as rows)
// ------------------------------------------------------------
#let 表格(name, columns: (1fr, 4fr), breakable: false, ..contents) = [
  #block(breakable: breakable)[
  // 标题:小型大写 + 1.3em 字号 / Title: smallcaps, 1.3em size
  *#smallcaps(text(size: 1.3em)[#name])*
  #v(-1em)
  #table(
  columns: columns,
  // 第 0 列居中,其余列左对齐 / Column 0 centered, others left-aligned
  align: (col, row) =>
   if col == 0 { center }
    else { left },
  // 隔行变色(斑马纹)/ Alternating row colors (zebra striping)
  fill: (col, row) => if calc.odd(row+1) { rgb("#aaaaaa00") } else { rgb("#aaffaa33") },
  inset: 10pt,
  stroke: none,
  // align: horizon,
  ..contents
  )
]]


// ------------------------------------------------------------
// 浮动图片辅助函数 / Floating figure helpers
// ------------------------------------------------------------

// topfig:在父块顶部浮动放置图片 / Float figure at top of parent block
#let 顶部图(figure) = [ #place(top + center, dy: -7em, dx:0em, float: true, scope: "parent", clearance: -6em, figure) ]
// bottomfig:在父块底部浮动放置图片 / Float figure at bottom of parent block
// 先清除页脚以避免重叠 / Suppress footer first to avoid overlap
#let 底部图(figure) = [ // Suppress the footer first
  #context footer.update("")
  #place(bottom + center, dy: 7em, dx:0em, float: true, scope: "parent", clearance: -6em, figure)
]


// ------------------------------------------------------------
// breakoutbox:浮动信息框(顶部+底部边框)/ Floating callout box
//   title    - 标题(可空)/ Title (can be empty)
//   contents - 框内内容 / Box contents
// ------------------------------------------------------------
#let 提示框(title, contents) = [#place(auto, float: true)[
  #set par(first-line-indent: 0em, spacing: 0.6em)
  #box(inset: 10pt, width: 100%, stroke: (top: 2pt, bottom: 2pt), fill: rgb("#ddeedd"))[
    #if title != none {
      align(left, smallcaps[*#title*])
    }

    #align(left)[#contents]
  ]
]]

// ------------------------------------------------------------
// 属性值换算工具 / Ability modifier utilities
// ------------------------------------------------------------

// bonus:根据属性值计算修正值字符串 / Compute modifier string from ability score
// 规则:(score - 10) / 2 向下取整,>=10 为正 / Rule: floor((score-10)/2), "+" if >= 10
#let 修正值(i) = {
  let b = ""
  if i >= 10 {
    b = "+"
  }
  b + str(calc.floor((i - 10)/2))
}

// stat-to-str:格式化为 "值 (修正)" / Format as "score (modifier)"
#let 属性转串(a) = {
  (str(a) + " (" + 修正值(int(a)) + ")")
}

// ------------------------------------------------------------
// stats-table:六维属性表(STR/DEX/CON/INT/WIS/CHA)/ Six-ability stats table
//   stats - 字典,键为属性名,值为数值 / Dict of ability name -> score
//   color - 属性名的强调色,默认深红 / Accent color for ability names
// ------------------------------------------------------------
#let 属性表(stats, color: darkred) = {
  let content = ()
  // 第一行:属性名(强调色、加粗)/ First row: ability names (accent, bold)
  for k in stats.keys() {
    content.push([#text(fill: color, weight: 700, k)])
  }
  // 第二行:数值(修正)/ Second row: score (modifier)
  for k in stats.values() {
    content.push([#text(fill: black, 属性转串(k))])
  }
  // 6 列等宽,无描边,居中对齐 / 6 equal columns, no stroke, centered
  table(stroke: none, columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr), inset: 0pt, row-gutter: 5pt, align: center, ..content)
}

// ------------------------------------------------------------
// boxed-text:带黄色侧边的文本框 / Text box with yellow side strokes
//   header   - 标题文本(三级标题)/ Title (level-3 heading)
//   contents - 框内正文 / Box body content
// ------------------------------------------------------------
#let 侧标框(header, contents) = [
  #box(inset: 10pt, fill: rgb("#fefff9"), stroke: (right: 1pt + darkyellow, left: 1pt + darkyellow), width: 100%)[
    #set par(spacing: .6em, first-line-indent: 1.5em)
    #set text(size: 0.83em)
    #heading(outlined: false, level: 3, header)
    #v(0.5em)
    #contents
  ]
]

// ------------------------------------------------------------
// statbox:怪物/生物属性框 / Monster/creature stat block
//   stats - 字典,包含 name/description/ac/hp/speed/stats/skillblock/traits
//           以及可选的 actions/reactions/limited_usage/equip/legendary_act
//   theme - 可选主题字典,定制配色:title(标题栏底色,可渐变)/accent(强调色)/
//           soft(浅底色)/border(边框色);缺省为经典深红风格
//           Dict with creature info and optional action sections
// ------------------------------------------------------------
#let 属性框(stats, theme: (:)) = {
  // 主题解析:缺省为经典深红/白底 / Resolve theme, default classic darkred
  let 标题色 = theme.at("title", default: darkred)
  let 强调色 = theme.at("accent", default: darkred)
  let 浅底色 = theme.at("soft", default: white)
  let 边框色 = theme.at("border", default: darkred)

  // 标题栏文字色:默认白色,可经 theme.title-fg 覆盖 / Title text color, default white
  let 标题文字色 = theme.at("title-fg", default: white)

  box(inset: 0pt, fill: 浅底色, stroke: 1pt + 边框色, width: 100%)[
    // 标题栏横幅 / Title banner
    box(
      width: 100%,
      inset: (x: 12pt, y: 7pt),
      fill: if type(标题色) == color { 标题色 } else { gradient.linear(..标题色) },
    )[
      #set text(fill: 标题文字色)
      #heading(outlined: false, level: 3, stats.name)
    ]

    #pad(x: 12pt, y: 8pt)[
      #set par(spacing: .6em)
      #set text(size: 0.83em)

      // 描述(斜体)/ Description (italic)
      _ #stats.description _

      #line(stroke: 1.5pt + 强调色, length: 100%)
      // AC/HP/Speed 标签使用当前语言配置 / AC/HP/Speed labels from current language
      #context [
        #text(fill: 强调色)[*#language.get().stats.ac*] #stats.ac\
        #text(fill: 强调色)[*#language.get().stats.hp*] #stats.hp\
        #text(fill: 强调色)[*#language.get().stats.speed*] #stats.speed\
      ]

      #line(stroke: 1.5pt + 强调色, length: 100%)
      // 六维属性表 / Six-ability stats table
      #属性表(stats.stats, color: 强调色)
      #line(stroke: 1.5pt + 强调色, length: 100%)

      // 技能块(感知、语言、挑战等级等)/ Skill block (senses, languages, challenge, etc.)
      #for skill in stats.skillblock {
        [#text(fill: 强调色)[*#skill.at(0)*] #skill.at(1)\ ]
      }
      #line(stroke: 1.5pt + 强调色, length: 100%)
      // 特性 / Traits (表格形式)
      #if stats.traits.len() > 0 {
        table(
          stroke: none,
          columns: (1fr, 4fr),
          inset: (x: 8pt, y: 4pt),
          align: (left, left),
          ..stats.traits.map(trait => (
            [#text(fill: 强调色, weight: 700)[#trait.at(0)]],
            trait.at(1),
          )).flatten(),
        )
      }

      // 动作段落(标签来自语言配置)/ Action sections (labels from language config)
      #context {
        let sections = (
          language.get().sections.actions,
          language.get().sections.reactions,
          language.get().sections.limited_usage,
          language.get().sections.equip,
          language.get().sections.legendary_act,
        )
        for section in sections {
          // 仅当 stats 中存在该段落时渲染 / Render only if section exists in stats
          if section in stats.keys() {
            block[
              #set par(spacing: 1em)
              #text(size: 1.3em, fill: 强调色)[#box(width:100%, inset: (bottom: 3pt), stroke: (bottom: 1pt+darkyellow))[#smallcaps(section)]]
              #for action in stats.at(section) {
                [_*#text(fill: 强调色)[#action.at(0)].*_ #action.at(1) \ ]
              }
            ]
          }
        }
      }
    ]
  ]
}

// ------------------------------------------------------------
// npcbox:NPC 信息框 / NPC info block
//   npc - 字典,包含 name/race/class/alignment/stats(可选)
//         以及 description/background/roleplay(可选,标签使用语言配置)
//         Dict with NPC info; description/background/roleplay use localized labels
// ------------------------------------------------------------
#let 人物框(npc) = [
  #box(inset: 12pt, fill: white, stroke: 1pt, width: 100%)[
    #set par(spacing: .6em)
    #set text(size: 0.83em)
    #heading(outlined: false, level: 3, npc.name)

    // 种族/职业/阵营(斜体,逗号分隔)/ Race/class/alignment (italic, comma-joined)
    #{
      let parts = ()
      if "race" in npc.keys() { parts.push(npc.race) }
      if "class" in npc.keys() { parts.push(npc.class) }
      if "alignment" in npc.keys() { parts.push(npc.alignment) }
      if parts.len() > 0 {
        emph(parts.join(", "))
      }
    }

    #line(stroke: 2pt + darkred, length: 100%)

    // 可选的六维属性表 / Optional six-ability stats table
    #if "stats" in npc.keys() {
      属性表(npc.stats)
      line(stroke: 2pt + darkred, length: 100%)
    }

    // 描述/背景/角色扮演段落(标签来自语言配置)/ Localized description/background/roleplay sections
    #context {
      let labels = language.get().npc
      let sections = (
        ("description", labels.description),
        ("background", labels.background),
        ("roleplay", labels.roleplay),
      )
      for (key, label) in sections {
        if key in npc.keys() {
          block(spacing: 0.8em)[
            #text(fill: darkred, weight: 700)[#smallcaps(label)] \
            #npc.at(key)
          ]
        }
      }
    }
  ]
]

// ------------------------------------------------------------
// spell:法术条目 / Spell entry
//   spl - 字典,包含 name/spell-type/properties(属性列表)/description
//         Dict with name, spell-type, properties (list), description
// ------------------------------------------------------------
#let 法术(spl) = [
  #set par(spacing: .6em, first-line-indent: 0em)
  #heading(outlined: false, level: 3, spl.name)

  // 法术类型(斜体)/ Spell type (italic)
  _#spl.spell-type _
  #v(0.5em)
  // 属性列表(施法时间、范围、持续时间、成分等)/ Property list
  #for prop in spl.properties {

       [*#prop.at(0):* #prop.at(1) \ ]


      }
  #v(0.5em)

  #spl.description

]

// ------------------------------------------------------------
// appendix:附录功能 / Appendix helper
//   title         - 附录总标题(默认 "附录")/ Appendix master title
//   numbering-fmt - 附录标题编号格式(默认 "A.1.",即附录 A 及其子标题 A.1, A.1.1)/
//                   Appendix heading numbering format
//   body         - 附录正文内容 / Appendix body content
//
// 用法 / Usage:
//   #appendix[
//     = 附录子标题
//     内容...
//   ]
// 也可通过 include 引入附录文件 / Or include an appendix file:
//   #appendix[#include "附录文件.typ"]
// ------------------------------------------------------------
#let 附录(title: "附录", numbering-fmt: "A.1.", body) = [
  // 切换标题编号为字母格式(附录 A, A.1, A.1.1 ...)/
  // Switch heading numbering to letter format
  #set heading(numbering: numbering-fmt)
  // 重置标题计数器,使附录从 A 开始 / Reset heading counter so appendix starts at A
  #counter(heading).update(0)
  // 附录分区名:不作为标题,不占用编号;附录正文从一级标题开始
  // Appendix part label: not a heading, does not consume a number; body starts at level-1 headings
  #align(left)[#text(size: 3em, weight: "bold", fill: darkred, font: "Comic Sans MS")[#title]]
  #v(0.6em)
  #body
]

// ------------------------------------------------------------
// trademarks:版权声明 / Copyright notice
// 用于文档末尾的版权声明 / Used at the end of the document for copyright notice
// ------------------------------------------------------------
#let 版权声明 = text(size: 0.9em, style: "italic")[
  #品牌 及其相关标识均为本项目原创内容。本作品中的所有设定、角色、地名及世界观均为虚构,如有雷同纯属巧合。

All original material in this work is copyright by the respective authors and published under the MIT License.
]

// ------------------------------------------------------------
// 世界纲要:单栏居中页 / World Overview: single-column centered page
// ------------------------------------------------------------
#let 世界纲要(body) = [
  #page(columns: 1, margin: (left: 30mm, right: 30mm, top: 30mm, bottom: 30mm))[
    #align(center)[
      #set text(size: 1.1em)
      #body
    ]
  ]
]

// ------------------------------------------------------------
// 目录:单栏居中页 / Table of contents: single-column centered page
// ------------------------------------------------------------
#let 目录() = [
  #page(columns: 1, margin: (left: 30mm, right: 30mm, top: 30mm, bottom: 30mm))[
    #align(center)[
      #outline(title: text(size: 1.6em, fill: darkred, weight: "bold")[目录])
    ]
  ]
]
