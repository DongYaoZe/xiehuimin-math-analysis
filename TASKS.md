# Agent task map

所有页码均为 PDF 物理页码；agent 直接读取 `source-pages/<volume>/page-XXXX.jpg`。印刷页码仅用于核对。

| Task | 内容 | source-pages | PDF物理页 | 印刷页 | 输出文件 |
|---|---|---|---:|---:|---|
| FU | 上册前置材料（目录页不手抄） | upper | 1–17 | 前置页 | `frontmatter/upper.tex` |
| C01 | 第1章 引论 | upper | 18–28 | 1–11 | `chapters/ch01.tex` |
| C02 | 第2章 数列极限 | upper | 29–83 | 12–66 | `chapters/ch02.tex` |
| C03 | 第3章 实数系的基本定理 | upper | 84–113 | 67–96 | `chapters/ch03.tex` |
| C04 | 第4章 函数极限 | upper | 114–140 | 97–123 | `chapters/ch04.tex` |
| C05 | 第5章 连续函数 | upper | 141–173 | 124–156 | `chapters/ch05.tex` |
| C06 | 第6章 导数与微分 | upper | 174–201 | 157–184 | `chapters/ch06.tex` |
| C07 | 第7章 微分学的基本定理 | upper | 202–242 | 185–225 | `chapters/ch07.tex` |
| C08 | 第8章 微分学的应用 | upper | 243–294 | 226–277 | `chapters/ch08.tex` |
| C09 | 第9章 不定积分 | upper | 295–315 | 278–298 | `chapters/ch09.tex` |
| C10 | 第10章 定积分 | upper | 316–352 | 299–335 | `chapters/ch10.tex` |
| C11 | 第11章 积分学的应用 | upper | 353–391 | 336–374 | `chapters/ch11.tex` |
| C12 | 第12章 广义积分 | upper | 392–419 | 375–402 | `chapters/ch12.tex` |
| C13 | 第13章 数项级数 | lower | 13–51 | 1–39 | `chapters/ch13.tex` |
| C14 | 第14章 函数项级数与幂级数 | lower | 52–90 | 40–78 | `chapters/ch14.tex` |
| C15 | 第15章 Fourier 级数 | lower | 91–117 | 79–105 | `chapters/ch15.tex` |
| C16 | 第16章 无穷级数的应用 | lower | 118–148 | 106–136 | `chapters/ch16.tex` |
| C17 | 第17章 高维空间中的点集与基本定理 | lower | 149–158 | 137–146 | `chapters/ch17.tex` |
| C18 | 第18章 多元函数的极限与连续 | lower | 159–178 | 147–166 | `chapters/ch18.tex` |
| C19 | 第19章 偏导数与全微分 | lower | 179–199 | 167–187 | `chapters/ch19.tex` |
| C20 | 第20章 隐函数存在定理与隐函数求导 | lower | 200–220 | 188–208 | `chapters/ch20.tex` |
| C21 | 第21章 偏导数的应用 | lower | 221–250 | 209–238 | `chapters/ch21.tex` |
| C22 | 第22章 重积分 | lower | 251–290 | 239–278 | `chapters/ch22.tex` |
| C23 | 第23章 含参变量积分 | lower | 291–320 | 279–308 | `chapters/ch23.tex` |
| C24 | 第24章 曲线积分 | lower | 321–347 | 309–335 | `chapters/ch24.tex` |
| C25 | 第25章 曲面积分 | lower | 348–382 | 336–370 | `chapters/ch25.tex` |
| C26 | 第26章 场论初步 | lower | 383–397 | 371–385 | `chapters/ch26.tex` |
| BU | 上册参考题提示、参考文献、索引 | upper | 420–443 | 403–末 | `backmatter/upper.tex` |
| FL | 下册前置材料（目录页不手抄） | lower | 1–12 | 前置页 | `frontmatter/lower.tex` |
| BL | 下册参考题提示、参考文献、索引 | lower | 398–421 | 386–末 | `backmatter/lower.tex` |

默认分工是一章一个 agent。特别长的章节如果以后需要拆分，只按 `\section` 边界拆，并由整合者提前创建独立输出文件；agent 不自行拆章。
