# xie-huimin-math-analysis-latex

谢惠民、恽自求、易法槐、钱定边《数学分析习题课讲义（第2版）》上、下册的 LaTeX 忠实整理工程。

本仓库采用“一仓双册”结构：第 1–12 章为上册，第 13–26 章为下册。正文转录以 2018 年上册、2019 年下册扫描版为唯一题面依据。目标是把扫描书转成可维护的结构化 LaTeX，而不是 OCR 文本堆积或重新编写教材。

## 目录

- `数学分析习题课讲义.tex`：合订主文件
- `01上册.tex` / `02下册.tex`：分册入口
- `chapters/ch01.tex` … `chapters/ch26.tex`：各章正文，默认一章一个 agent
- `frontmatter/` / `backmatter/`：前后置材料
- `preamble/`：全书统一宏、数学记号、环境
- `STYLE_GUIDE.md`：强制排版与转录规范
- `examples/style-example.tex`：agent 必读示例
- `TASKS.md`：任务号、扫描页范围、输出文件
- `source-pages/`：从原 PDF 直接抽取的逐页扫描图，仅本地使用且不进 Git
- `PAGE_MANIFEST.csv`：逐页映射与哈希
- `scripts/extract_source_pages.py`：从两册 PDF 重建 `source-pages/`

Agent 不需要重新找 PDF，不需要 OCR，不需要设计格式。读 `STYLE_GUIDE.md`、示例和自己分配的页面图片，然后只写指定 `.tex` 文件即可。
