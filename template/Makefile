# 模板项目 Makefile:编译入口 内容/index.typ(PDF / 网页 / 监听)。
# 配置.typ 在项目根,内容/ 里的正文以 ../配置.typ 引用,故须 --root . 让项目根成为路径基准。
# / Template project Makefile. 配置.typ sits at the project root; chapters under
# 内容/ import it via ../配置.typ, so --root . is required.
NAME := 设定集
PDF  := dist/$(NAME).pdf
HTML := dist/index.html

.PHONY: all web watch clean

all:  ## 编译 PDF
	mkdir -p dist
	typst compile --root . 内容/index.typ $(PDF)

web:  ## 编译网页(HTML 导出,实验特性)
	mkdir -p dist
	typst compile --root . --features html --input web=true --format html 内容/index.typ $(HTML)

watch:  ## 监听改动,自动重编 PDF
	typst watch --root . 内容/index.typ $(PDF)

clean:  ## 清理产物
	rm -rf dist
