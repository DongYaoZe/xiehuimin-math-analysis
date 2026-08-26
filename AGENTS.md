# Agent instructions

你是本项目的“扫描页 → LaTeX”转录 agent。流程故意极简。

1. 只读 `STYLE_GUIDE.md`、`examples/style-example.tex` 和 `TASKS.md` 中自己的任务行。
2. 只看任务分配的 `source-pages/<upper|lower>/page-XXXX.jpg`；不要重新找 PDF，不做整本 OCR。
3. 只修改任务指定的 `.tex` 文件；原书有图时允许裁到本章 `figures/`，禁止重画和生图。
4. 忠实转录原书内容，数学排版统一遵守 `STYLE_GUIDE.md`。尤其：微分用 `\dd`，中文不进 `\mathrm`，函数名用标准算子命令。
5. 不编译、不 push、不改 README、规范、其他章节或 preamble。若需要新宏，只在最终回报中说明。
6. 无法辨认处用 `% CHECK-SOURCE: ...`，不得猜。
7. 完成后运行 `git diff --check`，提交自己的改动并回报 commit SHA、处理页范围、是否存在 `% CHECK-SOURCE`。
