# xie-huimin-math-analysis-latex

谢惠民、恽自求、易法槐、钱定边《数学分析习题课讲义（第2版）》的结构化 LaTeX 整理与习题解答工程。

正文转录以 2018 年上册、2019 年下册扫描版为题面依据。当前 `main` 保留“一仓双册 + 分册解答”的兼容结构：第 1–12 章为上册，第 13–26 章为下册，并已纳入 26 章习题解答。项目目标是得到可维护、可校核、可持续排版优化的 LaTeX 源码，而不是 OCR 文本堆积或对原书正文的重新编写。

截至当前版本，第 1–26 章正文与对应解答已经汇总到主文件 `数学分析习题课讲义.tex`。TeXPage 全书构建已通过，生成 1755 页，TeX error、Missing character、undefined reference 和 undefined citation 均为 0。仍保留少量非致命的长公式/长行版面 warning，后续排版分支继续做视觉优化。原书前置材料、参考题提示、参考文献与索引中的部分内容仍在 `frontmatter/`、`backmatter/` 中保留待补任务，不应据此宣称扫描版所有附属页面均已转录完成。

## 目录

- `数学分析习题课讲义.tex`：当前合订主文件，依次载入两册正文和两册习题解答
- `01上册.tex` / `02下册.tex`：正文分册入口
- `03上册习题解答.tex` / `04下册习题解答.tex`：解答分册入口
- `chapters/ch01.tex` … `chapters/ch26.tex`：26 章正文
- `solutions/ch01.tex` … `solutions/ch26.tex`：26 章习题解答
- `frontmatter/` / `backmatter/`：前后置材料与待补附属内容
- `preamble/`：全书统一宏、数学记号和环境
- `STYLE_GUIDE.md`：转录与排版规范
- `examples/style-example.tex`：环境与格式示例
- `TASKS.md`：原始扫描页范围与正文转录任务映射
- `ANSWER_SOURCES.md` / `ANSWER_PAGE_MANIFEST.csv`：解答来源与页级证据
- `PAGE_MANIFEST.csv` / `SOURCE_MANIFEST.md`：正文页级映射、哈希与来源记录
- `scripts/`：扫描页提取、结构验证等维护脚本
- `source-pages/` / `answer-pages/`：由原 PDF 重建的本地页图，不进入 Git

维护时应优先保持题面、解答、页级来源和结构验证的一致性；涉及数学内容的修改应保留可追溯证据，并在提交前运行结构检查与 `git diff --check`。
