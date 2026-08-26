\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{beautybook}[23-07-2024 V10.1 beautybook Class]
% /* -------------------------------------------------------------------------- */
% /*                                    切换文类                                    */
% /* -------------------------------------------------------------------------- */
\DeclareKeys{% = \DeclareKeys[autoclass]
   lang .choice: ,
   lang/en .code:n = \def\beautybook@class{book} ,
   lang/cn .code:n = \def\beautybook@class{ctexbook} ,
   lang .initial:n = en ,
   unknown .code:n = \beautybook@unknown ,
}

\ExplSyntaxOn
\clist_new:N \beautybook@unknownoptions
\cs_new_protected:Npn \beautybook@unknown
{
   \bool_if:NTF \l__keys_no_value_bool
   { % eg. 12pt, twoside
      \clist_put_right:Nx \beautybook@unknownoptions
      { \l_keys_key_str }
   }
   { % eg. zihao=4, fontset=windows
      \clist_put_right:Nx \beautybook@unknownoptions
      { \l_keys_key_str = { \exp_not:o \l_keys_value_tl } }
   }
}
\ExplSyntaxOff

\ProcessKeyOptions % = \ProcessKeyOptions[beautybook]
\PassOptionsToClass\beautybook@unknownoptions\beautybook@class
%% 如果不需要过滤上面定义的 lang 等键，可以直接使用
%% \PassOptionsToClass\@raw@classoptionslist\beautybook@class

\LoadClass{\beautybook@class}
% /* ---------------------------------- 切换文类 ---------------------------------- */


% /* -------------------------------------------------------------------------- */
% /*                           判断 A4 paper程序                          */
% /* -------------------------------------------------------------------------- */
\ExplSyntaxOn
\cs_new:Npn \ifaivpaper@TF
{
   \bool_lazy_and:nnTF
   { \dim_compare_p:nNn { 297mm } = { \paperheight } } % 不能是 29.7cm
   { \dim_compare_p:nNn { 210mm } = { \paperwidth  } }
}
\ExplSyntaxOff
% \ifaivpaper@TF{a4paper内容}{not a4paper内容} % 这个用在想要判断a4paper的地方
% /* -------------------------------------------------------------------------- */
% /*                           判断 A4 paper程序                          */
% /* -------------------------------------------------------------------------- */

\RequirePackage[dvipsnames,svgnames,x11names,table]{xcolor}
\RequirePackage{tikz,calc} %%页面样式设计核心包 %提供\pgfonlayer命令
\usetikzlibrary{cd,calc,shadows,shadows.blur,hobby,intersections, decorations.markings, decorations.pathreplacing,spy,arrows,shapes,fadings,trees,mindmap,patterns,shapes.arrows,shapes.symbols,tikzmark,shapes.geometric,graphs, quotes, angles,decorations.pathmorphing,through,shadings,backgrounds,positioning,fit,arrows.meta,shapes.misc,decorations.shapes}

% /* --------------------------------- 模板默认颜色 --------------------------------- */
\colorlet{outermarginfgcolor}{DarkCyan} % foregroundcolor 较深的前景色
\colorlet{outermarginbgcolor}{DarkCyan!30} % backgroundcolor 较浅的背景色
% /* -------------------------------------------------------------------------- */

% /* -------------------------------------------------------------------------- */
% /*                                   封面切换程序                                   */
% /* -------------------------------------------------------------------------- */
\ExplSyntaxOn
\keys_define:nn {beautybook/coverstyle}
{
   cover-choose.choice:,
   cover-choose.value_required:n = true,
   cover-choose/cn.code:n = {\RequirePackage{stys/beautybook-cover-cn}},
   cover-choose/en.code:n = {\RequirePackage{stys/beautybook-cover-en}},
   cover-choose/enfig.code:n = {\RequirePackage{stys/beautybook-cover-enfig}},
   cover-choose/birkar.code:n = {\RequirePackage{stys/beautybook-cover-birkar}},
   cover-choose/stargate.code:n = {\RequirePackage{stys/beautybook-cover-stargate}},
   %cover-choose .initial:n = en , % 设置 en 为初始值
}
\newtoks \l__beautybook_tmpa_toks
\cs_new_protected:Npn \coverstyle
{
   \tex_afterassignment:D \__beautybook_set_coverstyle:
   \l__beautybook_tmpa_toks
}
\cs_new:Npn \__beautybook_set_coverstyle:
{ \keys_set:nV { beautybook / coverstyle } \l__beautybook_tmpa_toks }
% Math fonts
\keys_define:nn {beautybook/mathstyle}
{
   math-font.choice:,
   math-font.value_required:n = true,
   math-font/plain.code:n={
         \RequirePackage{amssymb,amsfonts,upgreek}
      },
   math-font/mtpro2.code:n = {
         \RequirePackage{amsmath,amssymb}
         \let\Bbbk\relex
         \RequirePackage{mtpro2}
         \newcommand\hmmax{0} % default 3
         \RequirePackage{bm}
         \DeclareSymbolFont{CMlargesymbols}{OMX}{cmex}{m}{n}
         \let\sum\relax
         \let\prod\relax
         \DeclareMathSymbol{\sum}{\mathop}{CMlargesymbols}{"50}
         \DeclareMathSymbol{\prod}{\mathop}{CMlargesymbols}{"51}
         %% \infty
         \DeclareSymbolFont{symbolsCM}{OMS}{cmsy}{m}{n}
         \SetSymbolFont{symbolsCM}{bold}{OMS}{cmsy}{b}{n}
         \DeclareMathSymbol{\infty}{\mathord}{symbolsCM}{"31}
      },
   math-font/fourier.code:n = {
         % ----------------------------- Fourier Math Font ---------------------------- %
         \usepackage{fourier,amssymb}
         \usepackage[T1]{fontenc}
         \DeclareMathAlphabet{\mathcal}{OMS}{cmsy}{m}{n} % use the plain \mathcal font style insted of the one from fourier!
         \DeclareSymbolFont{orilargesymbols}{OMX}{cmex}{m}{n}
         \DeclareMathSymbol{\orisum}{\mathop}{orilargesymbols}{"50}
         \renewcommand\sum\orisum % Replace sum symbol with default one.
         % Restore the font symbol of \mathbb
         \DeclareSymbolFont{AMSb}{U}{msb}{m}{n}
         \makeatletter
         \DeclareSymbolFontAlphabet{\math@bb}{AMSb}
         % see http://tex.stackexchange.com/a/254979/
         \AtBeginDocument{\protected\def\mathbb{\math@bb}}
         \makeatother
         \DeclareMathAlphabet{\mathfrak}{U}{jkpmia}{m}{it}
         \SetMathAlphabet{\mathfrak}{bold}{U}{jkpmia}{bx}{it}
         % ---------------------------------------------------------------------------- %
      },
   math-font/stix.code:n = { % Only work at XeLaTeX engine!!
         % /* -------------------------------------------------------------------------- */
         \RequirePackage{amssymb}
         \RequirePackage[bold-style=ISO]{unicode-math}%使用宏包.   注意这个选项必须带上.   不然正文中使用粗体斜体将冲突
         \defaultfontfeatures{ Scale=MatchLowercase, Ligatures=TeX }%抑制不必要的警告
         %------------------------------------------%
         %自定义数学符号及字体
         % 说明：需要打开unicode-math.pdf和unicode-symbols.pdf两个文件.   前者是使用教程.   后者是unicode索引.   对照macro索引更换需要的符号字体.   注意只能插入macro实现符号索引.   不能插入unicode或者符号本身.   可实现完全的自定义数学字体设计
         %------------------------------------------%
         \setmathfont{texgyretermes-math.otf}%设置数学环境全局字体.   这一步必须放在最前面.   必须有且字体包不能是XITSMath-Regular.otf
         % \setmathfont{Asana-Math.otf}%有点点卡通风格的感觉
         % \setmathfont{XCharter-Math.otf}%细线条的风格
         \setmathfont{XITSMath-Regular.otf}[range={\mathalpha}]%设置全体拉丁、希腊字母为XITS字体
         % \setmathfont{Erewhon-Math.otf}[range={\mitpi,\mbfitpi,\mitomega,\mbfitomega,\mitgamma,\mittau,\mbfittau,\mitsigma,\mbfitsigma,\mitpsi,\mbfitpsi}]
         \setmathfont{STIXTwoMath-Regular.otf}[range={\mathop,\mathopen,\mathclose,\mathcal}]%设置全体括号、大型运算符为STIX2字体
         \setmathfont{STIXTwoMath-Regular.otf}[range={\mitmu,\mbfitmu,\mitgamma,\mbfitgamma}]%单独设置\mu.   \gamma两个符号为STIX2字体
         \setmathfont{texgyretermes-math.otf}[range={\sum}]%求和号很好看
         \setmathfont{texgyretermes-math.otf}[range={\mathbb}]%默认的数学环境正文
         \setmathfont{texgyretermes-math.otf}[range={}]
         % /* -------------------------------------------------------------------------- */
         \let\llangle\relax\let\rrangle\relax
      },
   %cover-choose .initial:n = plain , % 设置 en 为初始值
}
\cs_new_protected:Npn \mathstyle
{
   \tex_afterassignment:D \__beautybook_set_mathstyle:
   \l__beautybook_tmpa_toks
}
\cs_new:Npn \__beautybook_set_mathstyle:
{ \keys_set:nV { beautybook / mathstyle } \l__beautybook_tmpa_toks }
\ExplSyntaxOff
\RequirePackage{stys/beautybook-bottompage} %封底
% /* -------------------------------------------------------------------------- */

% /* -------------------------------------------------------------------------- */
% /*                                    宏包导入                                    */
% /* -------------------------------------------------------------------------- */
\RequirePackage{cncolours,ninecolors}
\RequirePackage{appendix} % 附录
\RequirePackage{etoolbox} % 判断函数
\RequirePackage{imakeidx}
\RequirePackage{varwidth}
\RequirePackage{caption}\colorlet{captioncolor}{outermarginfgcolor} % 图片和表格题注文字颜色
\RequirePackage{indentfirst}
% Math-Stuff
\RequirePackage{amsmath,amsthm,mathrsfs,extarrows,bropd,mathtools}
\RequirePackage[thmtools-compat]{keytheorems} %第三套定理系统定制核心包
\RequirePackage{nicematrix}
\RequirePackage[left=2cm,right=2cm,top=.6cm,bottom=2.2cm]{geometry}
\RequirePackage{tabularray}
\RequirePackage{enumitem}\setlist{font=\upshape} % 取消所有列表默认距离 nosep,
\RequirePackage[normalem]{ulem} % 用于参考文献
% 关于图片 graphicx
\RequirePackage{graphicx}
% 如果图片没有指定后缀, 依次按下列顺序搜索
\DeclareGraphicsExtensions{.pdf,.eps,.jpg,.png}
% 设置图表搜索路径, 可以给图表文件夹取如下名字
\graphicspath{{inner_pics/}{inner_pics/titleimages/}{figures/}{figure/}{pictures/}{picture/}{pic/}{pics/}{image/}{images/}}
\RequirePackage{anyfontsize} % 消除字体大小警告
\RequirePackage[colorlinks,linkcolor = purple,anchorcolor =  purple,urlcolor = purple,citecolor= purple]{hyperref}
% /* -------------------------------------------------------------------------- */

% /* -------------------------------------------------------------------------- */
% /*                                 设置pgflayers                                */
% /* -------------------------------------------------------------------------- */
\pgfdeclarelayer{background} %背景%底层
\pgfdeclarelayer{foreground} %上层
\pgfdeclarelayer{top} %顶部
\pgfdeclarelayer{bottom} %底部
\pgfsetlayers{bottom,background,main,foreground,top}
% /* -------------------------------------------------------------------------- */

% /* -------------------------------------------------------------------------- */
% /* -------------------------------------------------------------------------- */
% /* 设置封面与版权页元素                               */
% /* -------------------------------------------------------------------------- */
\newcommand\bookseries[1]{\def\@bookseries{#1}}
\newcommand\subtitle[1]{\def\@subtitle{#1}}
\newcommand\edition[1]{\def\@edition{#1}}
\newcommand\presslogo[1]{\def\@presslogo{#1}}
\newcommand\pressname[1]{\def\@pressname{#1}}
\newcommand\coverimage[1]{\def\@coverimage{#1}}

% ----------------------------- 版权页专属变量及宏包 ----------------------------- %
\RequirePackage{ifthen}
\RequirePackage[type={CC},modifier={by-nc-nd},hyperxmp={false},version={4.0}]{doclicense}

\newcommand{\templateauthor}{Yaoze Dong} % 名字
\newcommand{\doctitle}[1]{\def\@doctitle{#1}}
\newcommand{\docsubtitle}[1]{\def\@docsubtitle{#1}}
\newcommand{\copyrightpage}[5]{\def\@faculty{#1}\def\@university{#2}\def\@publisher{#3}\def\@ams{#4}\def\@city{#5}}

\newboolean{copyright}
\newcommand{\copyrights}{\setboolean{copyright}{true}}
% /* -------------------------------------------------------------------------- */

% /* -------------------------------------------------------------------------- */
% /*                                  模板用到的距离标尺                                 */
% /* -------------------------------------------------------------------------- */
\newlength\outermarginwidth % 页边栏宽度
\setlength\outermarginwidth{1.5cm}

\newlength\covershift % 封面距离标尺
\setlength\covershift{5cm}
% /* -------------------------------------------------------------------------- */
\newcommand{\tikzoverlay}[1]{\begin{tikzpicture}[remember picture,overlay] #1 \end{tikzpicture}}

% /* -------------------------------------------------------------------------- */
% /*                                   目录样式设置                                   */
% /* -------------------------------------------------------------------------- */
\RequirePackage{xpatch}%修正章节编号
\RequirePackage[automark,singlespacing=true]{scrlayer-scrpage}%页面设置宏包,隶属于koma-script文档类
\RequirePackage[explicit]{titlesec}
\RequirePackage{titletoc}
% /* ------------------------------- minted代码高亮 ------------------------------- */
\RequirePackage{minted}
% 公有设置
\setminted{ % 全局代码样式
   fontsize=\small,
   frame=leftline,framesep=5pt,rulecolor=gray!35,framerule=.75pt,
   breaklines,
   autogobble,
   linenos,numberblanklines=false,
   numbersep=2mm,
   breakanywhere=true,
   ignorelexererrors=true
}
\RequirePackage{fvextra} % 加载 fvextra 包以支持代码分页
% 开启代码分页
\fvset{breaklines=true, breakanywhere=true}
% ---------------------------------- 重定义行号样式 --------------------------------- %
\renewcommand{\theFancyVerbLine}{\sffamily\textcolor[RGB]{176,176,176}{\footnotesize \oldstylenums{\arabic{FancyVerbLine}}}}
% ---------------------------------------------------------------------------- %
\definecolor{back}{RGB}{248,248,248} % 代码背景色
% \newenvironment{tcbmint}[1]{
%   \begin{tcblisting}{
%       listing engine=minted,
%       boxrule=0.1mm,
%       colback=back,
%       colframe=gray!35,
%       listing only,
%       left=8mm,
%       breakable,
%       minted language=#1, % 高亮代码类型
%       minted options={} % 每个盒子都可以自定义不同的局部代码样式
%     }
%     }{
%   \end{tcblisting}
% }
% /* -------------------------------------------------------------------------- */
\RequirePackage[most]{tcolorbox}
\tcbuselibrary{breakable, skins,theorems,minted}
\setcounter{tocdepth}{3}
\setcounter{secnumdepth}{3}%增加编号深度

\newcommand\boxednum[1]
{
   \tcbsidebyside[sidebyside adapt=left,
      nobeforeafter,fontupper=\sffamily\large\bfseries,fontlower=\large,colframe=white,colupper=white,colback=outermarginfgcolor!90,colbacklower=gray!10,frame hidden,width =\textwidth,
      top=0mm,bottom=0mm,right=0mm,left=2mm,before skip balanced=0em,after skip balanced=0em,arc=0pt,outer arc=0pt,bicolor,sidebyside gap=6mm,boxrule=0pt,sidebyside align=center,halign=center,halign lower=left,fuzzy shadow={-0.4mm}{0.4mm}{0mm}{0.2mm}{white!50!gray},% 上
      fuzzy shadow={0.4mm}{-0.4mm}{0mm}{0.2mm}{fill=white!40!gray},%下
   ]{% left hand side % adjust from this side
      \thecontentslabel
   }{% right hand side
      \textbf{#1} \hfill \thecontentspage
   }% end
}

\newcommand\boxednonum[1]
{
   \begin{tcolorbox}[nobeforeafter,fontupper=\large,fontlower=\large,colframe=white,fontupper=\sffamily\bfseries,colupper=white,colback=outermarginfgcolor!90,colbacklower=gray!10,frame hidden,width = \textwidth,sidebyside gap=6mm,
         top=0mm,bottom=0mm,right=0cm,left=2mm,before skip balanced=0em,after skip balanced=0em,arc=0pt,outer arc=0pt,bicolor,sidebyside,boxrule=0pt,sidebyside align=center,halign=center,halign lower=left,lefthand width=3mm,fuzzy shadow={-0.4mm}{0.4mm}{0mm}{0.2mm}{white!50!gray},% 上
         fuzzy shadow={0.4mm}{-0.4mm}{0mm}{0.2mm}{fill=white!40!gray},%下
      ]
      \tcblower \textbf{#1}\hfill \thecontentspage
   \end{tcolorbox}
}
%
\titlecontents{chapter}[0mm]
{\addvspace{-.5em}}
{\contentsmargin{0pt}\boxednum}
{\contentsmargin{0pt}\boxednonum}
{}
[\addvspace{-.5em}]
%
\titlecontents{section}
[4.5em] % ie, 1.5em (chapter) + 2.3em
{}
{\hyperlink{section.\thecontentslabel}{\contentslabel{2.2em}}}
{\hspace*{-2.2em}}
{\titlerule*[1pc]{.}\contentspage\hspace*{1.5mm}}
%
\titlecontents{subsection}
[7.3em] % ie, 1.5em (chapter) + 2.3em
{}
{\hyperlink{subsection.\thecontentslabel}{\contentslabel{2.7em}}}
{\hspace*{-2.7em}}
{\titlerule*[1pc]{.}\contentspage\hspace*{1.5mm}}
%
\titlecontents{subsubsection}
[10.7em] % ie, 1.5em (chapter) + 2.3em
{}
{\hyperlink{subsubsection.\thecontentslabel}{\contentslabel{3.3em}}}
{\hspace*{-3.3em}}
{\titlerule*[1pc]{.}\contentspage\hspace*{1.5mm}}
% /* -------------------------------------------------------------------------- */


% /* -------------------------------------------------------------------------- */
% /*                                    章节样式                                    */
% /* -------------------------------------------------------------------------- */
\newcommand\chapimage[1]{\def\@chapimage{#1}}
% /* ---------------------------- titleimage自动导入程序 ---------------------------- */


\ExplSyntaxOn
\seq_new:N \g__beautybook_chapter_oimage_seq % odd 
\seq_new:N \g__beautybook_chapter_eimage_seq % even 
\seq_new:N \g__beautybook_part_oimage_seq % odd 
\seq_new:N \g__beautybook_part_eimage_seq % even 
%
\keys_define:nn { beautybook/titleimage }
{
   chapteroddimage  .code:n =
   \seq_gset_from_clist:Nn \g__beautybook_chapter_oimage_seq {#1} ,
   chapterevenimage .code:n =
   \seq_gset_from_clist:Nn \g__beautybook_chapter_eimage_seq {#1} ,
   partoddimage     .code:n =
   \seq_gset_from_clist:Nn \g__beautybook_part_oimage_seq    {#1} ,
   partevenimage    .code:n =
   \seq_gset_from_clist:Nn \g__beautybook_part_eimage_seq    {#1} ,
}
\cs_new:Npn \__beautybook_title_image:Nn #1#2 % image seq, number
{ \seq_item:Nn #1 { \int_mod:nn {#2} { \seq_count:N #1 } + 1 } } %对照表-对录入的字符串进行编号
\cs_new:Npn \beautybook@chapterimagename %生成索契表 ： 判断奇偶数页并按(章节编号)!!读取相应的列表组中的字符串
{
   \int_if_odd:nTF { \value{page} }
   { \__beautybook_title_image:Nn \g__beautybook_chapter_oimage_seq { \value{chapter} } }
   { \__beautybook_title_image:Nn \g__beautybook_chapter_eimage_seq { \value{chapter} } }
}
\cs_new:Npn \beautybook@partimagename
{
   \int_if_odd:nTF { \value{page} }
   { \__beautybook_title_image:Nn \g__beautybook_part_oimage_seq { \value{part} } }
   { \__beautybook_title_image:Nn \g__beautybook_part_eimage_seq { \value{part} } }
}
\cs_new_protected:Npn \titleimage #1
{ \keys_set:nn { beautybook/titleimage } {#1} }
\ExplSyntaxOff

% /* -------------------------------- Chatper样式 ------------------------------- */
\titleformat{\chapter}{\huge\bfseries\filcenter}{}{1em}{
   \makebox[0pt][l]{\def\rad{7pt}%
      \begin{tikzpicture}[remember picture, overlay]%
         \begin{pgfonlayer}{bottom}
            \ifaivpaper@TF{ % A4
               \ifodd\value{page}
               \shade[right color=outermarginbgcolor!30,middle color=outermarginbgcolor!50,left color=outermarginfgcolor!30] (current page.north west) rectangle ++(\paperwidth,-.2\paperheight+0.3cm); % background odd
               \else
               \shade[left color=outermarginbgcolor!30,middle color=outermarginbgcolor!50,right color=outermarginfgcolor!30] (current page.north west) rectangle ++(\paperwidth,-.2\paperheight+0.3cm); % background even
               \fi
            }{ % Letter
               \ifodd\value{page}
               \shade[right color=outermarginbgcolor!30,middle color=outermarginbgcolor!50,left color=outermarginfgcolor!30] (current page.north west) rectangle ++(\paperwidth,-.2\paperheight-0.05cm); % background odd
               \else
               \shade[left color=outermarginbgcolor!30,middle color=outermarginbgcolor!50,right color=outermarginfgcolor!30] (current page.north west) rectangle ++(\paperwidth,-.2\paperheight-0.05cm); % background even
               \fi
            }
            \fill[outermarginfgcolor,opacity=.5]([shift={(0,-4.45cm)}]current page.north west) rectangle ++(\paperwidth,-2mm); % line
         \end{pgfonlayer}
         \path[fill=outermarginfgcolor]node[append after command={
                  ([xshift=-3*\rad]chapinfoofpart.north west)  to[out=0,in=-180,looseness=1] ([xshift=\rad]chapinfoofpart.south west) --([xshift=-\rad]chapinfoofpart.south east) to[out=0,in=180,looseness=1] ([xshift=3*\rad]chapinfoofpart.north east) --cycle},
            text=white,font=\sffamily\large\bfseries,align=center,minimum height=1cm] (chapinfoofpart) at ([shift={(0,-4.95cm)}]current page.north) {Part\ \thepart};
         \begin{pgfonlayer}{bottom}
            \fill[outermarginfgcolor!90,opacity=0.5] ([shift={(-3*\rad,0)}]chapinfoofpart.north west) to[out=180,in=0,looseness=1] +(-4*\rad,-1.2cm)--([shift={(7*\rad,-1.2cm)}]chapinfoofpart.north east) to[out=-180,in=0,looseness=1] +(-4*\rad,1.2cm); % partnumber shade
         \end{pgfonlayer}
         \ifodd\value{page}
         \begin{pgfonlayer}{top}
            \fill[outermarginfgcolor,opacity=0.7,rounded corners=5pt]node[append after command={([yshift=2cm]chapnum.north west) rectangle (chapnum.south east)},right,text=white,minimum width=2cm,align=center,font=\sffamily\bfseries] (chapnum) at ([shift={(1.5cm,-2.5cm)}]current page.north west) {\scalebox{3}{\thechapter}};
            \begin{pgfonlayer}{foreground}
               \pattern[pattern=sixpointed stars,pattern color=white,opacity=0.6,rounded corners=5pt]
               ([yshift=2cm]chapnum.north west) rectangle (chapnum.south east);
            \end{pgfonlayer}
            \fill [outermarginfgcolor,path fading=fade up,rounded corners=5pt]%
            ([yshift=2cm]chapnum.north west) rectangle (chapnum.south east);
            \node[above left,font=\sc\fontsize{22pt}{22pt}\selectfont,align=center] (contents name) at ([shift={(0cm,-4.45cm)}]current page.north east) {\begin{varwidth}{.7\linewidth}\baselineskip=2ex  #1\end{varwidth}};
         \end{pgfonlayer}
         \begin{pgfonlayer}{bottom}
            \node[right] (image) at ([shift={(-0.5cm,-2.8cm)}]current page.north west) {\includegraphics[width=7cm]{\@chapimage}};
         \end{pgfonlayer}
         \else
         \begin{pgfonlayer}{top}
            \fill[outermarginfgcolor,opacity=0.7,rounded corners=5pt]node[append after command={([yshift=2cm]chapnum.north west) rectangle (chapnum.south east)},left,text=white,minimum width=2cm,align=center,font=\sffamily\bfseries] (chapnum) at ([shift={(-1.5cm,-2.5cm)}]current page.north east) {\scalebox{3}{\thechapter}};
            \begin{pgfonlayer}{foreground}
               \pattern[pattern=sixpointed stars,pattern color=white,opacity=0.6,rounded corners=5pt]
               ([yshift=2cm]chapnum.north west) rectangle (chapnum.south east);
            \end{pgfonlayer}
            \fill [outermarginfgcolor,path fading=fade up,rounded corners=5pt]%
            ([yshift=2cm]chapnum.north west) rectangle (chapnum.south east);
            \node[above right,font=\sc\fontsize{22pt}{22pt}\selectfont,align=center] (contents name) at ([shift={(0cm,-4.45cm)}]current page.north west) {\begin{varwidth}{.7\linewidth}\baselineskip=2ex  #1\end{varwidth}};
         \end{pgfonlayer}
         \begin{pgfonlayer}{background}
            \node[left] (image) at ([shift={(0.5cm,-2.8cm)}]current page.north east) {\includegraphics[width=7cm]{\@chapimage}};
         \end{pgfonlayer}
         \fi
         \path[fill=outermarginbgcolor]node[append after command={
                  ([xshift=-2*\rad]pagenumber.south west)  to[out=0,in=180,looseness=1] ([xshift=\rad]pagenumber.north west) --([xshift=-\rad]pagenumber.north east) to[out=0,in=-180,looseness=1] ([xshift=2*\rad]pagenumber.south east) --cycle},
            text=outermarginfgcolor,font=\sffamily\fontsize{15}{15}\selectfont\bfseries,align=center,minimum height=0.4cm,minimum width=1.3cm,inner sep=1.5mm] (pagenumber) at ([shift={(0,0.3cm)}]current page.south) {\thepage};
      \end{tikzpicture}}
}
\titleformat{name=\chapter,numberless}{\bfseries\huge\filcenter}{}{1em}{
   \makebox[0pt][l]{\def\rad{7pt}%
      \begin{tikzpicture}[remember picture, overlay]%
         \begin{pgfonlayer}{bottom}
            \ifodd\value{page}
            \shade[right color=outermarginbgcolor!30,middle color=outermarginbgcolor!50,left color=outermarginfgcolor!30] (current page.north west) rectangle ++(\paperwidth,-.2\paperheight); % background odd
            \else
            \shade[left color=outermarginbgcolor!30,middle color=outermarginbgcolor!50,right color=outermarginfgcolor!30] (current page.north west) rectangle ++(\paperwidth,-.2\paperheight); % background even
            \fi
            \fill[outermarginfgcolor,opacity=.5]([shift={(0,-4.45cm)}]current page.north west) rectangle ++(\paperwidth,-2mm); % line
         \end{pgfonlayer}
         \ifodd\value{page}
         \begin{pgfonlayer}{top}
            \node[above left,font=\sc\fontsize{25pt}{25pt}\selectfont,align=center] (contents name) at ([shift={(0cm,-4.45cm)}]current page.north east) {\begin{varwidth}{.7\linewidth}\baselineskip=25pt  #1\end{varwidth}};
         \end{pgfonlayer}
         \begin{pgfonlayer}{bottom}
            \node[right] (image) at ([shift={(-0.5cm,-2.8cm)}]current page.north west) {\includegraphics[width=7cm]{\@chapimage}};
         \end{pgfonlayer}
         \else
         \begin{pgfonlayer}{top}
            \node[above right,font=\sc\fontsize{25pt}{25pt}\selectfont,align=center] (contents name) at ([shift={(0cm,-4.45cm)}]current page.north west) {\begin{varwidth}{.7\linewidth}\baselineskip=25pt  #1\end{varwidth}};
         \end{pgfonlayer}
         \begin{pgfonlayer}{background}
            \node[left] (image) at ([shift={(0.5cm,-2.8cm)}]current page.north east) {\includegraphics[width=7cm]{\@chapimage}};
         \end{pgfonlayer}
         \fi
         \path[fill=outermarginbgcolor]node[append after command={
                  ([xshift=-2*\rad]pagenumber.south west)  to[out=0,in=180,looseness=1] ([xshift=\rad]pagenumber.north west) --([xshift=-\rad]pagenumber.north east) to[out=0,in=-180,looseness=1] ([xshift=2*\rad]pagenumber.south east) --cycle},
            text=outermarginfgcolor,font=\sffamily\fontsize{15}{15}\selectfont\bfseries,align=center,minimum height=0.4cm,minimum width=1.3cm,inner sep=1.5mm] (pagenumber) at ([shift={(0,0.3cm)}]current page.south) {\thepage};
      \end{tikzpicture}}
}
\titlespacing{\chapter}{0pt}{0pt}{70pt}

% /* --------------------------------- Part定制 --------------------------------- */

%%定义标题文字长度%%
\newlength{\partstarlen}
%%设置临界长度%%
\newlength{\criticstarlen}
\setlength{\criticstarlen}{\textwidth}
% 定义垂直方向的渐变
\tikzfading[name=fade bottom to top,
   bottom color=transparent!0, % 底部完全透明
   top color=transparent!100]      % 顶部不透明
\tikzfading[name=middle, top color=transparent!90, bottom
   color=transparent!90, middle color=transparent!20]
\makeatletter
\newcommand\partabstract[1]{\def\@partabstract{#1}}
\newcommand\partimage[1]{\def\@partimage{#1}}
\titleformat{\part}
{\normalfont\huge\filcenter}
{}
{20pt}
{\settowidth{\partstarlen}{\sc\huge #1} % 计算\partabstract的长度并写入到\partstarlen中
   \begin{tikzpicture}[remember picture,overlay]
      \def\barwidth{2cm}
      \fill[outermarginbgcolor,opacity=0.6]
      (current page.north west) rectangle (current page.south east);
      \ifodd\value{page}
      \fill [outermarginfgcolor!20]%
      (current page.north east) rectangle ++(-\outermarginwidth,-\paperheight);
      \pattern [pattern=north east lines,pattern color=outermarginfgcolor!50]%
      (current page.north east) rectangle ++(-\outermarginwidth,-\paperheight);
      \fill [outermarginbgcolor!90,path fading=fade south]%
      ([yshift=1mm]current page.north east) rectangle ++(-\outermarginwidth,-.8\paperheight);
      \fill [outermarginbgcolor,path fading=fade north]%
      (current page.south east) rectangle ++(-\outermarginwidth,.8\paperheight);%
      % lines
      \fill[outermarginfgcolor,rounded corners=2pt] (current page.north east) --++(-5pt,-0.15cm)--++(-\outermarginwidth+10pt,0) --++(-5pt,0.15cm)--cycle;
      \coordinate (anchor of headmark) at ([shift={(-1.2\outermarginwidth,-0.2cm)}]current page.north east);
      \node[below ,text=outermarginfgcolor,font=\sffamily\bfseries\fontsize{15}{20}\selectfont] (partpagenum) at ([shift={(-.5\outermarginwidth,0)}]current page.north east) {\thepage};
      \fill[outermarginfgcolor,rounded corners=2pt] (current page.south east) --++(-5pt,0.15cm)--++(-\outermarginwidth+10pt,0) --++(-5pt,-0.15cm)--cycle; % 页码横线
      \node[] (hbar) at ($(current page.north)!0.33!(current page.south)$) {
         \begin{tikzpicture}
            %%--------------- Horizontal Line --------------------%%
            \fill[outermarginbgcolor!70]
            (0,0) rectangle ++(\paperwidth,-1cm);
            %%--------------- Horizontal Line -------------------%%
            \fill[outermarginbgcolor]
            (0,-.25cm) rectangle ++(\paperwidth,-.5cm);
            \fill[outermarginfgcolor]
            (.67\paperwidth,-.25cm) rectangle ++(4.5cm,-.5cm);
            \fill[outermarginfgcolor!20!white]
            (.67\paperwidth-1mm,-.25cm) rectangle ++(1mm,-.5cm);
            \fill[outermarginfgcolor!20!white]
            (.67\paperwidth+4.4cm,-.25cm) rectangle ++(1mm,-.5cm);
         \end{tikzpicture}
      };
      \node[above,font=\sc\huge,shift={(.33\linewidth,.5\barwidth)}] (partname) at (hbar) {Part\ \thepart};
      \node[below left,font=\sc\huge,shift={(.146\linewidth,-\barwidth)}] (partcontents) at (partname) {\begin{varwidth}{.9\linewidth}\raggedright\baselineskip=25pt  #1 \end{varwidth}}; % 标题名称
      \begin{pgfonlayer}{background}
         \node[above,shift={(-.4\linewidth,-4*\barwidth)}] at (partname) {\ifdefvoid{\@partimage}{}{\includegraphics[width=1.2\linewidth]{\@partimage}}}; % 图片位置调整
         % % 应用渐变效果
         \fill[path fading=fade bottom to top, fill=nuanbai] (current page.north west) rectangle ([xshift=-\outermarginwidth]current page.south east);
      \end{pgfonlayer}
      %判断标题文字长度与临界长度的关系
      \ifdim\partstarlen<\criticstarlen
         %如果标题长度小于临界长度则使用(hbar)定位
         \node[below,font=\normalfont\fontsize{13}{16}\selectfont,shift={(0,-1.2*\barwidth)}] at (hbar) {\ifdefvoid{\@partabstract}{}{\begin{varwidth}{.9\linewidth}\baselineskip=3ex \@partabstract\end{varwidth}}}; % 简介文字调整
      \else
         \node[below,font=\normalfont\fontsize{13}{16}\selectfont,shift={(0,-1.2*\barwidth)}] at (partcontents) {\ifdefvoid{\@partabstract}{}{\begin{varwidth}{.9\linewidth}\baselineskip=3ex \@partabstract\end{varwidth}}}; % 简介文字调整
      \fi
      \else
      \fill [outermarginfgcolor!20]%
      (current page.north west) rectangle ++(\outermarginwidth,-\paperheight);
      \pattern [pattern=north west lines,pattern color=outermarginfgcolor!50]%
      (current page.north west) rectangle ++(\outermarginwidth,-\paperheight);
      \fill [outermarginbgcolor!90,path fading=fade south]%
      ([yshift=1mm]current page.north west) rectangle ++(\outermarginwidth,-.8\paperheight);
      \fill [outermarginbgcolor,path fading=fade north]%
      (current page.south west) rectangle ++(\outermarginwidth,.8\paperheight);%
      % lines
      \fill[outermarginfgcolor,rounded corners=2pt] (current page.north west) --++(5pt,-0.15cm)--++(\outermarginwidth-10pt,0) --++(5pt,0.15cm)--cycle;
      \coordinate (anchor of headmark) at ([shift={(1.2\outermarginwidth,-0.2cm)}]current page.north west);
      \node[below ,text=outermarginfgcolor,font=\sffamily\bfseries\fontsize{15}{20}\selectfont] (partpagenum) at ([shift={(.5\outermarginwidth,0)}]current page.north west) {\thepage};
      \fill[outermarginfgcolor,rounded corners=2pt] (current page.south west) --++(5pt,0.15cm)--++(\outermarginwidth-10pt,0) --++(5pt,-0.15cm)--cycle; % 页码横线
      \node[] (hbar) at ($(current page.north)!0.33!(current page.south)$) {
         \begin{tikzpicture}
            %%--------------- Horizontal Line --------------------%%
            \fill[outermarginbgcolor!70]
            (0,0) rectangle ++(\paperwidth,-1cm);
            %%--------------- Horizontal Line -------------------%%
            \fill[outermarginbgcolor]
            (0,-.25cm) rectangle ++(\paperwidth,-.5cm);
            \fill[outermarginfgcolor]
            (.15\paperwidth,-.25cm) rectangle ++(4.5cm,-.5cm);
            \fill[outermarginfgcolor!20!white]
            (.15\paperwidth-1mm,-.25cm) rectangle ++(1mm,-.5cm);
            \fill[outermarginfgcolor!20!white]
            (.15\paperwidth+4.5cm,-.25cm) rectangle ++(1mm,-.5cm);
         \end{tikzpicture}
      };
      \node[above,font=\sc\huge,shift={(-.31\linewidth,.5\barwidth)}] (partname) at (hbar) {Part\ \thepart};
      \node[below right,font=\sc\huge,shift={(-.125\linewidth,-\barwidth)}] (partcontents) at (partname) {\begin{varwidth}{.9\linewidth}\raggedright\baselineskip=25pt  #1 \end{varwidth}}; % 标题名称
      \begin{pgfonlayer}{background}
         \node[above,shift={(.35\linewidth,-4*\barwidth)}] at (partname) {\ifdefvoid{\@partimage}{}{\includegraphics[width=1.2\linewidth]{\@partimage}}}; % 图片位置调整
         % % 应用渐变效果
         \fill[path fading=fade bottom to top, fill=nuanbai] (current page.north east) rectangle ([xshift=\outermarginwidth]current page.south west);
      \end{pgfonlayer}
      %判断标题文字长度与临界长度的关系
      \ifdim\partstarlen<\criticstarlen
         %如果标题长度小于临界长度则使用(hbar)定位
         \node[below,font=\normalfont\fontsize{13}{16}\selectfont,shift={(0,-1.2*\barwidth)}] at (hbar) {\ifdefvoid{\@partabstract}{}{\begin{varwidth}{.9\linewidth}\baselineskip=3ex \@partabstract\end{varwidth}}}; % 简介文字调整
      \else
         \node[below,font=\normalfont\fontsize{13}{16}\selectfont,shift={(0,-1.2*\barwidth)}] at (partcontents) {\ifdefvoid{\@partabstract}{}{\begin{varwidth}{.9\linewidth}\baselineskip=3ex \@partabstract\end{varwidth}}}; % 简介文字调整
      \fi
      \fi
   \end{tikzpicture}}

\assignpagestyle{\part}{empty}
\assignpagestyle{\chapter}{empty}


% /* -------------------------------- Section样式 ------------------------------- */
\titleformat{\section}
{}
{}
{-.5em} %左右移动\thesection标签位置
{\mysectionformat{#1}{outermarginfgcolor}}
%
\titleformat{name=\section,numberless}{}{}{-.5em}{\mysectionnonumformat{#1}{outermarginfgcolor}}

\newcommand{\mysectionformat}[2]{%
   \makebox[0pt][l]{
      \def\rad{7pt}%
      \begin{tikzpicture}[remember picture]
         \path[fill=outermarginfgcolor,blur shadow={shadow blur steps=10,shadow xshift=1pt, shadow yshift=-1pt,shadow blur radius=1.5pt,shadow opacity=35}]node[append after command={
                  ([xshift=\rad]sec.north west) to[out=180,in=0,looseness=1] ([xshift=-3*\rad]sec.south west) --([xshift=-\rad]sec.south east) to[out=0,in=180,looseness=1] ([xshift=3*\rad]sec.north east) --cycle},
            text=white,font=\sffamily\large\bfseries,align=center,inner ysep=2mm] (sec) at (0,0) {Sec\ \thesection};
         \node[text=black,font=\large,below right] (secnum) at ([shift={(0,-1mm)}]sec.north east) {\begin{varwidth}{.85\linewidth}\setlength\baselineskip{18pt}\hspace{.5cm}#1\end{varwidth}};
         \begin{pgfonlayer}{bottom}
            % -------- 右侧小翅膀 --------
            \shade[right color=#2!20, left color=#2!80!black]
            ([xshift=3*\rad]sec.north east)
            to[out=0, in=180] ++(2*\rad, -.7*\rad)
            -| +(-5*\rad,.7*\rad)
            -- cycle;
         \end{pgfonlayer}
      \end{tikzpicture}}}%最后一个选项为 [<after code>]

\newcommand{\mysectionnonumformat}[2]{%
   \makebox[0pt][l]{
      \def\rad{7pt}%
      \begin{tikzpicture}[remember picture]
         \path[fill=outermarginfgcolor,blur shadow={shadow blur steps=10,shadow xshift=1pt, shadow yshift=-1pt,shadow blur radius=1.5pt,shadow opacity=35}]node[append after command={
                  ([xshift=\rad]sec.north west) to[out=180,in=0,looseness=1] ([xshift=-3*\rad]sec.south west) --([xshift=-\rad]sec.south east) to[out=0,in=180,looseness=1] ([xshift=3*\rad]sec.north east) --cycle},
            text=white,font=\sffamily\large\bfseries,align=center,inner ysep=2mm] (sec) at (0,0) {Sec};
         \node[text=black,font=\large,below right] (secnum) at ([shift={(0,-1mm)}]sec.north east) {\begin{varwidth}{.85\linewidth}\setlength\baselineskip{18pt}\hspace{.5cm}#1\end{varwidth}};
         \begin{pgfonlayer}{bottom}
            % -------- 右侧小翅膀 --------
            \shade[right color=#2!20, left color=#2!80!black]
            ([xshift=3*\rad]sec.north east)
            to[out=0, in=180] ++(2*\rad, -.7*\rad)
            -| +(-5*\rad,.7*\rad)
            -- cycle;
         \end{pgfonlayer}
      \end{tikzpicture}}}%最后一个选项为 [<after code>]

\titlespacing*{\section}{0pt}{3.5ex plus 1ex minus .2ex}{2.3ex plus .2ex}


% /* ------------------------------ Subsection样式 ------------------------------ */
\usepackage{pifont}
\newcommand{\subsectionnumstyle}[2]{
   \makebox[0pt][l]{\def\rad{5pt}%
      \def\inrad{3pt}
      \begin{tikzpicture}[remember picture]
         \path[fill=#2,blur shadow={shadow blur steps=10,shadow xshift=1pt, shadow yshift=-1pt,shadow blur radius=1.5pt,shadow opacity=35}]node[append after command={
                  % 主体
                  ([shift={(\rad,\rad)}]sec.north west) arc[start angle=90, end angle=180, radius=\rad]  {[rounded corners=\inrad]--(sec.south west)}--([yshift=-3mm]$(sec.south west)!0.5!(sec.south east)$) {[rounded corners=\inrad]--(sec.south east)} -- (sec.north east) arc[start angle=180, end angle=90, radius=\rad]--cycle
               },
            text=white,font=\sffamily\large\bfseries,align=center,inner ysep=1.5mm,inner xsep=1mm] (sec) at (0,0) {\thesubsection};
         % 阴影
         \begin{pgfonlayer}{bottom}
            \shade[right color=#2!20, left color=#2!80!black]
            ([xshift=\rad,yshift=\rad]sec.north east) % 注意这里起点需对应你核心代码中的 3*\rad
            to[out=0, in=180] ++(2*\rad, -\rad) % 镜像：out 180->0, in 0->180, x -2->2
            -| +(-5*\rad,\rad)                % 镜像：x 5->-5
            -- cycle;
         \end{pgfonlayer}
         \node[text=black,font=\large,below right] (sectitle) at ([shift={(2mm,6.5mm)}]sec.south east) {\begin{varwidth}{.9\linewidth}\setlength\baselineskip{18pt}#1\end{varwidth}};
      \end{tikzpicture}}
}

\newcommand{\subsectionnonumstyle}[2]{
   \makebox[0pt][l]{\def\rad{5pt}%
      \def\inrad{3pt}
      \begin{tikzpicture}[remember picture]
         \path[fill=#2,blur shadow={shadow blur steps=10,shadow xshift=1pt, shadow yshift=-1pt,shadow blur radius=1.5pt,shadow opacity=35}]node[append after command={
                  % 主体
                  ([shift={(\rad,\rad)}]sec.north west) arc[start angle=90, end angle=180, radius=\rad]  {[rounded corners=\inrad]--(sec.south west)}--([yshift=-3mm]$(sec.south west)!0.5!(sec.south east)$) {[rounded corners=\inrad]--(sec.south east)} -- (sec.north east) arc[start angle=180, end angle=90, radius=\rad] --cycle
               },
            text=white,font=\sffamily\large\bfseries,align=center,inner ysep=0.5mm,inner xsep=1.5mm] (sec) at (0,0) {\Huge\ding{99}};
         % 阴影
         \begin{pgfonlayer}{bottom}
            \shade[right color=#2!20, left color=#2!80!black]
            ([xshift=\rad,yshift=\rad]sec.north east) % 注意这里起点需对应你核心代码中的 3*\rad
            to[out=0, in=180] ++(2*\rad, -\rad) % 镜像：out 180->0, in 0->180, x -2->2
            -| +(-5*\rad,\rad)                % 镜像：x 5->-5
            -- cycle;
         \end{pgfonlayer}
         \node[text=black,font=\large,below right] (sectitle) at ([shift={(2mm,6.5mm)}]sec.south east) {\begin{varwidth}{.9\linewidth}\setlength\baselineskip{18pt}#1\end{varwidth}};
      \end{tikzpicture}}
}

\titleformat{\subsection}
{}
{}
{-.5em} %左右移动\thesection标签位置
{\subsectionnumstyle{#1}{outermarginfgcolor}}

\titleformat{name=\subsection,numberless}{}{}{-.5em}{\subsectionnonumstyle{#1}{outermarginfgcolor}}

% \titlespacing*{\subsection}{0pt}{3.5ex plus 1ex minus .2ex}{2.3ex plus .2ex}

%%--------------------------------  SCRLAYER-SCRPAGE  -------------------------------------%%

% /* -------------------------------------------------------------------------- */
% /*                                  透明度渐变填充设定                                 */
% /* -------------------------------------------------------------------------- */
\tikzfading[name=fade south,
   top color =transparent!0,
   bottom color=transparent!80]
\tikzfading[name=fade north,
   top color =transparent!100,
   bottom color=transparent!0]
\tikzfading[name=fade right,
   right color =transparent!100,
   left color=transparent!0]
\tikzfading[name=fade left,
   left color =transparent!100,
   right color=transparent!0]
% /* -------------------------------------------------------------------------- */
% /*                                  透明度渐变填充设定                                 */
% /* -------------------------------------------------------------------------- */

% /* -------------------------------------------------------------------------- */
% /*                                 SIDE-BAR配置                                 */
% /* -------------------------------------------------------------------------- */

\ExplSyntaxOn
\char_set_catcode_space:N \
\tl_const:Nn \c__beautybook_sidebar_on_tl { % Sidebar-On

   \newlength\chapternumbersize
   \setlength\chapternumbersize{36pt}
   \setlength{\headheight}{40pt} % 页眉高度
   \renewcommand\chaptermarkformat{}
   % define a new mark for the chapter number
   \newmarks\chapternum
   \xapptocmd\chaptermark{\marks\chapternum{\thechapter}}{}{\PatchFailed}
   \newmarks\secnum
   \xapptocmd\sectionmark{\marks\secnum{\thesection}}{}{\PatchFailed}

   \newcommand*\outermarginpagemark{%
      \tikzoverlay{
         \begin{pgfonlayer}{top}
            \ifodd\value{page}
            \fill[outermarginfgcolor,rounded corners=2pt] (current page.north east) --++(-5pt,-0.15cm)--++(-\outermarginwidth+10pt,0) --++(-5pt,0.15cm)--cycle;
            \coordinate (anchor of headmark) at ([shift={(-1.2\outermarginwidth,-0.2cm)}]current page.north east);
            \node[below ,text=outermarginfgcolor,font=\sffamily\bfseries\fontsize{15}{15}\selectfont] at ([shift={(-.5\outermarginwidth,-0.15cm)}]current page.north east) {\thepage};
            \fill[outermarginfgcolor!50,rounded corners=1pt] ([shift={(0.2\outermarginwidth,0.2cm)}]anchor of headmark) --++(-5pt,-0.15cm)--++(-.45\linewidth,0) --++(-5pt,0.15cm)--cycle; % 页眉横线
            \node[below left,font=\upshape,text=outermarginfgcolor] at ([yshift=0.05cm]anchor of headmark) {\begin{varwidth}{\linewidth}\rightmark\end{varwidth}};
            \fill[outermarginfgcolor,rounded corners=2pt] (current page.south east) --++(-5pt,0.15cm)--++(-\outermarginwidth+10pt,0) --++(-5pt,-0.15cm)--cycle; % 页码横线
            \else
            \fill[outermarginfgcolor,rounded corners=2pt] (current page.north west) --++(5pt,-0.15cm)--++(\outermarginwidth-10pt,0) --++(5pt,0.15cm)--cycle;
            \coordinate (anchor of headmark) at ([shift={(1.2\outermarginwidth,-0.2cm)}]current page.north west);
            \node[below ,text=outermarginfgcolor,font=\sffamily\bfseries\fontsize{15}{15}\selectfont] at ([shift={(.5\outermarginwidth,-0.15cm)}]current page.north west) {\thepage};
            \fill[outermarginfgcolor!50,rounded corners=1pt] ([shift={(-0.2\outermarginwidth,0.2cm)}]anchor of headmark) --++(5pt,-0.15cm)--++(.45\linewidth,0) --++(5pt,0.15cm)--cycle; % 页眉横线
            \node[below right,font=\upshape,text=outermarginfgcolor] at ([yshift=0.05cm]anchor of headmark) {\begin{varwidth}{\linewidth}\rightmark\end{varwidth}};
            \fill[outermarginfgcolor,rounded corners=2pt] (current page.south west) --++(5pt,0.15cm)--++(\outermarginwidth-10pt,0) --++(5pt,-0.15cm)--cycle; % 页码横线
            \fi
         \end{pgfonlayer}}
   }


   % Add A Side-Bar Box For The Chapter Number
   \newcommand*\outermarginchapternumberbox{%
      \if@mainmatter
         \tikzoverlay{
            \shade[top color=outermarginfgcolor!90,bottom color=outermarginbgcolor]
            (\outermarginwidth,-.5\outermarginwidth+2mm) rectangle (0,-1.5\outermarginwidth+2mm);
            \node[anchor=center,text=white,font=\sffamily\bfseries] at (1/2*\outermarginwidth,-\outermarginwidth+2mm) {\usekomafont{chapternumber}{\botmarks\chapternum}};%
         }
      \fi
      \vfill
   }

   \newkomafont{chapternumber}{%页边章节编号字体
      \fontsize{\chapternumbersize}{\chapternumbersize}\selectfont
   }%

   \newcommand\outermarginmark{
      \ifodd\value{page}\hfill\else\hspace*{\dimexpr\outermarginwidth*3/8\relax}\fi
      \rotatebox{90}{\parbox{\layerheight}{
            \raggedleft
            \usekomafont{outermargin}{%
               \MakeMarkcase{\ifodd\value{page}\odd@outermargin\else\even@outermargin\fi}}%
         }}%
      \ifodd\value{page}\hspace*{\dimexpr\outermarginwidth*3/8\relax}\fi%
   }
   \newcommand*\even@outermargin{}
   \newcommand*\odd@outermargin{}
   \newcommand*\evenoutermargin[1]{\renewcommand\even@outermargin{#1}}% 偶数页内容
   \newcommand*\oddoutermargin[1]{\renewcommand\odd@outermargin{#1}}% 奇数页内容

   %
   \newkomafont{outermargin}{%页边章节名称字体
      \bfseries\fontsize{15}{15}\selectfont\color{outermarginfgcolor}
   }
   % declare new page style using layers
   \DeclareNewPageStyleByLayers{scth}{%
      scth.outermargin.bg.even,%
      scth.outermargin.bg.odd,%
      scth.outermargin.fg.even,%
      scth.outermargin.fg.odd,%
      scth.outermargin.pn.even,%
      scth.outermargin.pn.odd,%
      scth.outermargin.cn.even,%
      scth.outermargin.cn.odd,%
      scth.outermargin.text.even,%
      scth.outermargin.text.odd%
   }
   % define the layers for even pages
   \DeclareNewLayer[
      background, % 下层(背景)
      evenpage,
      outermargin,
      width=\outermarginwidth,
      contents={\color{outermarginbgcolor}\rule{\layerwidth}{\layerheight}} %色彩装饰条
   ]{scth.outermargin.bg.even}%
   %%=============%                 页边条颜色              %=======================%%

   %偶数页边纹理效果设置
   \newcommand{\evensidbardeepcolor}{%
      \tikzoverlay{
         \ifodd\value{page}
            \fill [outermarginfgcolor!20]%
            (current page.north east) rectangle ([xshift=-\outermarginwidth,yshift=0]current page.south east);
            \pattern [pattern=checkerboard,pattern color=outermarginfgcolor!50]%
            (current page.north east) rectangle ([xshift=-\outermarginwidth,yshift=0]current page.south east);
            \fill [outermarginbgcolor!90,path fading=fade south]%
            ([yshift=1mm]current page.north east) rectangle ([xshift=-\outermarginwidth,yshift=-.5\layerheight]current page.north east);
            \fill [outermarginbgcolor,path fading=fade north]%
            (current page.south east) rectangle ([xshift=-\outermarginwidth,yshift=.2\layerheight]current page.south east);
         \else
            \fill [outermarginfgcolor!20]%
            (current page.north west) rectangle ([xshift=\outermarginwidth,yshift=0]current page.south west);
            \pattern [pattern=checkerboard,pattern color=outermarginfgcolor!50]%
            (current page.north west) rectangle ([xshift=\outermarginwidth,yshift=0]current page.south west);
            \fill [outermarginbgcolor!90,path fading=fade south]%
            ([yshift=1mm]current page.north west) rectangle ([xshift=\outermarginwidth,yshift=-.5\layerheight]current page.north west);
            \fill [outermarginbgcolor,path fading=fade north]%
            (current page.south west) rectangle ([xshift=\outermarginwidth,yshift=.2\layerheight]current page.south west);
         \fi
      }
   }
   %%==============偶数页页边条颜色========================%%
   \DeclareNewLayer[
      foreground, %
      evenpage,
      outermargin,
      width=\outermarginwidth,
      contents=\evensidbardeepcolor %色彩装饰条
   ]{scth.outermargin.fg.even}%
   %%==============偶数页页脚页码========================%%
   \DeclareNewLayer[
      foreground, %上层 (背景之上)
      evenpage,
      foot, % 页脚
      contents=\outermarginpagemark
   ]{scth.outermargin.pn.even}%
   %%==============偶数页章节编号========================%%
   \DeclareNewLayer[
      foreground, %上层 (背景之上)
      evenpage,
      head, %页眉
      hoffset=0pt,
      width=\outermarginwidth,
      align=t,
      addvoffset=\dimexpr-\chapternumbersize-12pt+\headheight\relax,
      height=\chapternumbersize+\headheight,
      contents=\outermarginchapternumberbox%章节编号
   ]{scth.outermargin.cn.even}%
   %%======================章节名称===================================%%
   \DeclareNewLayer[
      clone=scth.outermargin.cn.even,
      addheight=\dimexpr\headheight+\headsep+\textheight\relax,
      addvoffset=\dimexpr+2\outermarginwidth\relax,
      hoffset=-2.5pt,
      contents=\outermarginmark %
   ]{scth.outermargin.text.even}%

   % define the layers for odd page from the settings for even pages
   \newcommand*\DeclareOddFromEven[1]{%复制自偶数页样式命令
      \DeclareNewLayer[
         clone=#1.even,
         oddpage,
         align=r,
         hoffset=\paperwidth
      ]{#1.odd}%
   }
   \DeclareOddFromEven{scth.outermargin.bg}
   \DeclareOddFromEven{scth.outermargin.pn}
   \DeclareOddFromEven{scth.outermargin.cn}
   \DeclareOddFromEven{scth.outermargin.text}
   \DeclareOddFromEven{scth.outermargin.fg}

   % add the layers to page style scrheadings and page style plain
   \ForEachLayerOfPageStyle*{scth}{%
      \AddLayersToPageStyle{scrheadings}{#1}%
      \AddLayersToPageStyle{plain.scrheadings}{#1}%
   }
   %----------------------------------------------
   \KOMAoptions{markcase=upper} %页眉
   % for page styles scrheadings and plain
   \clearpairofpagestyles
   \ohead{}
   \cfoot{}
   \ofoot{}
   \oddoutermargin{\sffamily\leftmark} % Odd Side Text
   \evenoutermargin{\sffamily\@title} % Even Side Text
} % Sidebar-On
\tl_const:Nn \c__beautybook_sidebar_off_tl { % Sidebar-Off

   \newgeometry{left=2cm,right=2cm,top=2cm,bottom=2cm,head=16pt} % set proper headheight
   \newlength\chapternumbersize
   \setlength\chapternumbersize{36pt}
   % \setlength{\headheight}{40pt} % 页眉高度
   \renewcommand\chaptermarkformat{}
   % define a new mark for the chapter number
   \newmarks\chapternum
   \xapptocmd\chaptermark{\marks\chapternum{\thechapter}}{}{\PatchFailed}
   \newmarks\secnum
   \xapptocmd\sectionmark{\marks\secnum{\thesection}}{}{\PatchFailed}
   %%=============%                 页边条颜色              %=======================%%

   %=====================================================%%
   \newcommand*\outermarginpagenummark{%
      \tikzoverlay{
         \begin{pgfonlayer}{top}
            \ifodd\value{page}
            \fill[outermarginfgcolor,rounded corners=2pt] (current page.north east) --++(-5pt,-0.15cm)--++(-\outermarginwidth+10pt,0) --++(-5pt,0.15cm)--cycle;
            \coordinate (anchor of headmark) at ([shift={(-1.2\outermarginwidth,-0.2cm)}]current page.north east);
            \node[below ,text=outermarginfgcolor,font=\sffamily\bfseries\fontsize{15}{15}\selectfont] at ([shift={(-.5\outermarginwidth,-0.15cm)}]current page.north east) {\thepage};
            \fill[outermarginfgcolor!50,rounded corners=1pt] ([shift={(0.2\outermarginwidth,0.2cm)}]anchor of headmark) --++(-5pt,-0.15cm)--++(-.45\linewidth,0) --++(-5pt,0.15cm)--cycle; % 页眉横线
            \node[below left,font=\upshape,text=outermarginfgcolor] at ([yshift=0.05cm]anchor of headmark) {\begin{varwidth}{\linewidth}\rightmark\end{varwidth}};
            \else
            \fill[outermarginfgcolor,rounded corners=2pt] (current page.north west) --++(5pt,-0.15cm)--++(\outermarginwidth-10pt,0) --++(5pt,0.15cm)--cycle;
            \coordinate (anchor of headmark) at ([shift={(1.2\outermarginwidth,-0.2cm)}]current page.north west);
            \node[below ,text=outermarginfgcolor,font=\sffamily\bfseries\fontsize{15}{15}\selectfont] at ([shift={(.5\outermarginwidth,-0.15cm)}]current page.north west) {\thepage};
            \fill[outermarginfgcolor!50,rounded corners=1pt] ([shift={(-0.2\outermarginwidth,0.2cm)}]anchor of headmark) --++(5pt,-0.15cm)--++(.45\linewidth,0) --++(5pt,0.15cm)--cycle; % 页眉横线
            \node[below right,font=\upshape,text=outermarginfgcolor] at ([yshift=0.05cm]anchor of headmark) {\begin{varwidth}{\linewidth}\rightmark\end{varwidth}};
            \fi
         \end{pgfonlayer}}
   }
   % declare new page style using layers
   \DeclareNewPageStyleByLayers{scth}{%
      scth.outermargin.pnnosidebar.even,%
      scth.outermargin.pnnosidebar.odd,%
   }
   %%==============偶数页页脚页码========================%%
   \DeclareNewLayer[
      foreground, %上层 (背景之上)
      evenpage,
      foot, % 页脚
      contents=\outermarginpagenummark
   ]{scth.outermargin.pnnosidebar.even}%


   % define the layers for odd page from the settings for even pages
   \newcommand*\DeclareOddFromEven[1]{%复制自偶数页样式命令
      \DeclareNewLayer[
         clone=#1.even,
         oddpage,
         align=r,
         hoffset=\paperwidth
      ]{#1.odd}%
   }
   \DeclareOddFromEven{scth.outermargin.pnnosidebar}

   % add the layers to page style scrheadings and page style plain
   \ForEachLayerOfPageStyle*{scth}{%
      \AddLayersToPageStyle{scrheadings}{#1}%
      \AddLayersToPageStyle{plain.scrheadings}{#1}%
   }
   %----------------------------------------------
   \KOMAoptions{markcase=upper} %页眉
   % for page styles scrheadings and plain
   \clearpairofpagestyles
   \ohead{}
   \cfoot{}
   \ofoot{}
} % Sidebar-Off
\char_set_catcode_ignore:N \
\keys_define:nn {beautybook/sidestyle}
{
   sidebar.choice:,
   sidebar.value_required:n = true,
   sidebar/on.code:n = \c__beautybook_sidebar_on_tl,
   sidebar/off.code:n = \c__beautybook_sidebar_off_tl,
} % Sidebar-On

\tl_new:N \l__beautybook_new_style_tmp_tl
\cs_new_protected:Npn \__beautybook_new_style_cmd:Nn #1#2
{
   \cs_new_protected:Npn #1
   {
      \tl_set:Nn \l__beautybook_new_style_tmp_tl
      { \keys_set:nV {#2} \l__beautybook_tmpa_toks }
      \tex_afterassignment:D \l__beautybook_new_style_tmp_tl
      \l__beautybook_tmpa_toks
   }
}
\__beautybook_new_style_cmd:Nn \sidestyle { beautybook/sidestyle }

\keys_define:nn { beautybook / style }
{
   cover-choose .meta:nn = { beautybook/coverstyle } { cover-choose = {#1} } ,
   math-font    .meta:nn = { beautybook/mathstyle } { math-font = {#1} } ,
   sidebar      .meta:nn = { beautybook/sidestyle } { sidebar = {#1} } ,
}
\__beautybook_new_style_cmd:Nn \beautybookstyle { beautybook/style }
\ExplSyntaxOff
%%--------------------------------  SCRLAYER-SCRPAGE  -------------------------------------%%

% /* -------------------------------------------------------------------------- */
% /*                                    中国风盒子                                   */
% /* -------------------------------------------------------------------------- */

%% Begin The Most Beautiful Box (STYLE : ys style) 

\makeatletter
\definecolor{framegolden}{HTML}{455a64} % 控制外框颜色
\definecolor{framegray}{HTML}{e0e0e0} % 控制填充颜色
\newdimen\ys@frame@linewidth
\newdimen\ys@frame@radius
\newdimen\ys@frame@sep
\def\ys@frame@fill@opacity{0.2}

\pgfdeclarehorizontalshading{ys@fade@circle}{500bp}
{color(0bp)=(pgftransparent!100); color(25bp)=(pgftransparent!100);
   color(45bp)=(pgftransparent!0); color(55bp)=(pgftransparent!0);
   color(75bp)=(pgftransparent!100); color(100bp)=(pgftransparent!100)}
\pgfdeclarefading{ys circle}{\pgfuseshading{ys@fade@circle}}

\def\ys@frame@star@list@t{%
   -0.7071\ys@frame@radius+0.2133\ys@frame@sep/%
   -0.7071\ys@frame@radius+0.2133\ys@frame@sep/%
   frame.north east,%
   0.7071\ys@frame@radius-0.2133\ys@frame@sep/%
   -0.7071\ys@frame@radius+0.2133\ys@frame@sep/%
   frame.north west}
\def\ys@frame@star@list@b{%
   0.7071\ys@frame@radius-0.2133\ys@frame@sep/%
   0.7071\ys@frame@radius-0.2133\ys@frame@sep/%
   frame.south west,%
   -0.7071\ys@frame@radius+0.2133\ys@frame@sep/%
   0.7071\ys@frame@radius-0.2133\ys@frame@sep/%
   frame.south east}
\edef\ys@frame@star@list{\ys@frame@star@list@t,\ys@frame@star@list@b}

%region outer
\def\ys@frame@remove@middleline#1#2{}
\def\ys@frame@draw@middleline#1#2{%
   \clip ([xshift=-\ys@frame@linewidth,#1]frame.north west)--
   ([xshift=\ys@frame@linewidth,#1]frame.north east)--
   ([xshift=\ys@frame@linewidth,#2]frame.south east)--
   ([xshift=-\ys@frame@linewidth,#2]frame.south west)--cycle;}
\def\ys@frame@unbrokenouter{%
   \path[draw=framegolden,fill=framegray,fill opacity=\ys@frame@fill@opacity,line width=\ys@frame@linewidth]
   ([xshift=\ys@frame@radius]frame.north west)--([xshift=-\ys@frame@radius]frame.north east)
   arc(-180:-90:\ys@frame@radius)--
   ([yshift=-\ys@frame@radius]frame.north east)--([yshift=\ys@frame@radius]frame.south east)
   arc(90:180:\ys@frame@radius)--
   ([xshift=-\ys@frame@radius]frame.south east)--([xshift=\ys@frame@radius]frame.south west)
   arc(0:90:\ys@frame@radius)--
   ([yshift=\ys@frame@radius]frame.south west)--([yshift=-\ys@frame@radius]frame.north west)
   arc(-90:0:\ys@frame@radius)--cycle;}
\def\ys@frame@firstouter{%
   \ys@frame@remove@middleline{yshift=.5\ys@frame@linewidth}{yshift=.7\ys@frame@linewidth}%
   \path[draw=framegolden,fill=framegray,fill opacity=\ys@frame@fill@opacity,line width=\ys@frame@linewidth]
   ([xshift=\ys@frame@radius]frame.north west)--([xshift=-\ys@frame@radius]frame.north east)
   arc(-180:-90:\ys@frame@radius)--
   ([yshift=-\ys@frame@radius]frame.north east)--
   (frame.south east)--
   (frame.south west)--
   ([yshift=-\ys@frame@radius]frame.north west)
   arc(-90:0:\ys@frame@radius)--cycle;}
\def\ys@frame@middleouter{%
   \ys@frame@remove@middleline{yshift=-.7\ys@frame@linewidth}{yshift=.7\ys@frame@linewidth}%
   \path[draw=framegolden,fill=framegray,fill opacity=\ys@frame@fill@opacity,line width=\ys@frame@linewidth]
   (frame.north west)--(frame.north east)--(frame.south east)--
   (frame.south west)--cycle;}
\def\ys@frame@lastouter{%
   \ys@frame@remove@middleline{yshift=-.7\ys@frame@linewidth}{yshift=-.5\ys@frame@linewidth}%
   \path[draw=framegolden,fill=framegray,fill opacity=\ys@frame@fill@opacity,line width=\ys@frame@linewidth]
   (frame.north west)--(frame.north east)--
   ([yshift=\ys@frame@radius]frame.south east)
   arc(90:180:\ys@frame@radius)--
   ([xshift=-\ys@frame@radius]frame.south east)--([xshift=\ys@frame@radius]frame.south west)
   arc(0:90:\ys@frame@radius)--
   ([yshift=\ys@frame@radius]frame.south west)--
   (frame.north west)--cycle;}
%endregion
%region inner
\def\ys@frame@unbrokeninner{%
   \path[draw=framegolden,line width=.5\ys@frame@linewidth,line cap=round]
   ([xshift=\ys@frame@radius+2\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north west)
   --([xshift=\ys@frame@radius+5\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north west) --++(45:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth)
   ([xshift=\ys@frame@radius+6\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north west)--++(-45:2\ys@frame@linewidth)--++(45:2\ys@frame@linewidth) %第一节
   --([xshift=-\ys@frame@radius-8.828\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north east)--++(-45:2\ys@frame@linewidth)--++(45:2\ys@frame@linewidth)
   ([xshift=-\ys@frame@radius-7.828\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north east)--++(45:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth) %第二节
   --([xshift=-\ys@frame@radius-2\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north east)
   %%
   ([yshift=-\ys@frame@radius-2\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.north east)
   --([yshift=-\ys@frame@radius-5\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.north east) --++(-135:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth)
   ([yshift=-\ys@frame@radius-6\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.north east)--++(-45:2\ys@frame@linewidth)--++(-135:2\ys@frame@linewidth) %第一节
   --([yshift=\ys@frame@radius+8.828\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.south east)--++(-45:2\ys@frame@linewidth)--++(-135:2\ys@frame@linewidth)
   ([yshift=\ys@frame@radius+7.828\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.south east)--++(-135:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth) %第二节
   %
   --([yshift=\ys@frame@radius+2\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.south east)
   %
   ([xshift=\ys@frame@radius+2\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south west)
   --([xshift=\ys@frame@radius+5\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south west) --++(-45:2\ys@frame@linewidth)--++(45:2\ys@frame@linewidth)
   ([xshift=\ys@frame@radius+6\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south west)--++(45:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth) %第一节
   --([xshift=-\ys@frame@radius-8.828\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south east)--++(45:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth)
   ([xshift=-\ys@frame@radius-7.828\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south east)--++(-45:2\ys@frame@linewidth)--++(45:2\ys@frame@linewidth) %第二节
   --([xshift=-\ys@frame@radius-2\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south east)
   %
   ([yshift=-\ys@frame@radius-2\ys@frame@linewidth,xshift=\ys@frame@sep]frame.north west)
   --([yshift=-\ys@frame@radius-5\ys@frame@linewidth,xshift=\ys@frame@sep]frame.north west) --++(-45:2\ys@frame@linewidth)--++(-135:2\ys@frame@linewidth)
   ([yshift=-\ys@frame@radius-6\ys@frame@linewidth,xshift=\ys@frame@sep]frame.north west)--++(-135:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth) %第一节
   --([yshift=\ys@frame@radius+8.828\ys@frame@linewidth,xshift=\ys@frame@sep]frame.south west)--++(-135:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth)
   ([yshift=\ys@frame@radius+7.828\ys@frame@linewidth,xshift=\ys@frame@sep]frame.south west)--++(-45:2\ys@frame@linewidth)--++(-135:2\ys@frame@linewidth) %第二节
   --([yshift=\ys@frame@radius+2\ys@frame@linewidth,xshift=\ys@frame@sep]frame.south west);}
\def\ys@frame@firstinner{%
   \path[draw=framegolden,line width=.5\ys@frame@linewidth,line cap=round]
   ([xshift=\ys@frame@radius+2\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north west)
   --([xshift=\ys@frame@radius+5\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north west) --++(45:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth)
   ([xshift=\ys@frame@radius+6\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north west)--++(-45:2\ys@frame@linewidth)--++(45:2\ys@frame@linewidth) %第一节
   --([xshift=-\ys@frame@radius-8.828\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north east)--++(-45:2\ys@frame@linewidth)--++(45:2\ys@frame@linewidth)
   ([xshift=-\ys@frame@radius-7.828\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north east)--++(45:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth) %第二节
   --([xshift=-\ys@frame@radius-2\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north east)
   %%
   ([yshift=-\ys@frame@radius-2\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.north east)
   --([yshift=-\ys@frame@radius-5\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.north east) --++(-135:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth)
   ([yshift=-\ys@frame@radius-6\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.north east)--++(-45:2\ys@frame@linewidth)--++(-135:2\ys@frame@linewidth) %第一节
   --([xshift=-\ys@frame@sep]frame.south east)

   ([yshift=-\ys@frame@radius-2\ys@frame@linewidth,xshift=\ys@frame@sep]frame.north west)
   --([yshift=-\ys@frame@radius-5\ys@frame@linewidth,xshift=\ys@frame@sep]frame.north west) --++(-45:2\ys@frame@linewidth)--++(-135:2\ys@frame@linewidth)
   ([yshift=-\ys@frame@radius-6\ys@frame@linewidth,xshift=\ys@frame@sep]frame.north west)--++(-135:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth) %第一节
   --([xshift=\ys@frame@sep]frame.south west);}
\def\ys@frame@middleinner{%
   \path[draw=framegolden,line width=.5\ys@frame@linewidth,line cap=round]
   ([xshift=-\ys@frame@sep]frame.north east)--([xshift=-\ys@frame@sep]frame.south east)
   ([xshift=\ys@frame@sep]frame.north west)--([xshift=\ys@frame@sep]frame.south west);}
\def\ys@frame@lastinner{%
   \path[draw=framegolden,line width=.5\ys@frame@linewidth,line cap=round]
   ([xshift=-\ys@frame@sep]frame.north east)
   --([yshift=\ys@frame@radius+8.828\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.south east)--++(-45:2\ys@frame@linewidth)--++(-135:2\ys@frame@linewidth)
   ([yshift=\ys@frame@radius+7.828\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.south east)--++(-135:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth) %第二节
   %
   --([yshift=\ys@frame@radius+2\ys@frame@linewidth,xshift=-\ys@frame@sep]frame.south east)
   %
   ([xshift=\ys@frame@radius+2\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south west)
   --([xshift=\ys@frame@radius+5\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south west) --++(-45:2\ys@frame@linewidth)--++(45:2\ys@frame@linewidth)
   ([xshift=\ys@frame@radius+6\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south west)--++(45:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth) %第一节
   --([xshift=-\ys@frame@radius-8.828\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south east)--++(45:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth)
   ([xshift=-\ys@frame@radius-7.828\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south east)--++(-45:2\ys@frame@linewidth)--++(45:2\ys@frame@linewidth) %第二节
   --([xshift=-\ys@frame@radius-2\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south east)
   %
   ([xshift=\ys@frame@sep]frame.north west)
   --([yshift=\ys@frame@radius+8.828\ys@frame@linewidth,xshift=\ys@frame@sep]frame.south west)--++(-135:2\ys@frame@linewidth)--++(-45:2\ys@frame@linewidth)
   ([yshift=\ys@frame@radius+7.828\ys@frame@linewidth,xshift=\ys@frame@sep]frame.south west)--++(-45:2\ys@frame@linewidth)--++(-135:2\ys@frame@linewidth) %第二节
   --([yshift=\ys@frame@radius+2\ys@frame@linewidth,xshift=\ys@frame@sep]frame.south west);}
%endregion
%region corner
\def\ys@frame@unbrokencorner{%
   \path[draw=framegolden,line width=1.5\ys@frame@linewidth,line cap=round]
   ([xshift=\ys@frame@radius-2.7\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north west)
   --([xshift=\ys@frame@sep,yshift=-\ys@frame@sep]frame.north west)
   --([xshift=\ys@frame@sep,yshift=-\ys@frame@radius+2.7\ys@frame@linewidth]frame.north west)
   ([xshift=-\ys@frame@radius+2.7\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north east)
   --([xshift=-\ys@frame@sep,yshift=-\ys@frame@sep]frame.north east)
   --([xshift=-\ys@frame@sep,yshift=-\ys@frame@radius+2.7\ys@frame@linewidth]frame.north east)
   ([xshift=-\ys@frame@radius+2.7\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south east)
   --([xshift=-\ys@frame@sep,yshift=\ys@frame@sep]frame.south east)
   --([xshift=-\ys@frame@sep,yshift=\ys@frame@radius-2.7\ys@frame@linewidth]frame.south east)
   ([xshift=\ys@frame@radius-2.7\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south west)
   --([xshift=\ys@frame@sep,yshift=\ys@frame@sep]frame.south west)
   --([xshift=\ys@frame@sep,yshift=\ys@frame@radius-2.7\ys@frame@linewidth]frame.south west);}
\def\ys@frame@firstcorner{%
   \path[draw=framegolden,line width=1.5\ys@frame@linewidth,line cap=round]
   ([xshift=\ys@frame@radius-2.7\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north west)
   --([xshift=\ys@frame@sep,yshift=-\ys@frame@sep]frame.north west)
   --([xshift=\ys@frame@sep,yshift=-\ys@frame@radius+2.7\ys@frame@linewidth]frame.north west)
   ([xshift=-\ys@frame@radius+2.7\ys@frame@linewidth,yshift=-\ys@frame@sep]frame.north east)
   --([xshift=-\ys@frame@sep,yshift=-\ys@frame@sep]frame.north east)
   --([xshift=-\ys@frame@sep,yshift=-\ys@frame@radius+2.7\ys@frame@linewidth]frame.north east);}
\def\ys@frame@middlecorner{}
\def\ys@frame@lastcorner{%
   \path[draw=framegolden,line width=1.5\ys@frame@linewidth,line cap=round]
   ([xshift=-\ys@frame@radius+2.7\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south east)
   --([xshift=-\ys@frame@sep,yshift=\ys@frame@sep]frame.south east)
   --([xshift=-\ys@frame@sep,yshift=\ys@frame@radius-2.7\ys@frame@linewidth]frame.south east)
   ([xshift=\ys@frame@radius-2.7\ys@frame@linewidth,yshift=\ys@frame@sep]frame.south west)
   --([xshift=\ys@frame@sep,yshift=\ys@frame@sep]frame.south west)
   --([xshift=\ys@frame@sep,yshift=\ys@frame@radius-2.7\ys@frame@linewidth]frame.south west);}
%endregion
\def\ys@frame@star#1#2#3{%
   \begin{scope}[shift={([xshift=#1,yshift=#2]#3)},scale=\ys@frame@ratio*0.1]
      \path[draw=framegolden,fill=white,
         line width=.7\ys@frame@linewidth,line join=round]
      (1,1)..controls(0.3,0.5) and (-0.3,0.5)..
      (-1,1)..controls(-0.5,0.3) and (-0.5,-0.3)..
      (-1,-1)..controls(-0.3,-0.5) and (0.3,-0.5)..
      (1,-1)..controls(0.5,-0.3) and (0.5,0.3)..(1,1)--cycle;
      \path[scale=0.45,fill=framegolden,line join=round]
      (1,1)..controls(0.3,0.7) and (-0.3,0.7)..
      (-1,1)..controls(-0.7,0.3) and (-0.7,-0.3)..
      (-1,-1)..controls(-0.3,-0.7) and (0.3,-0.7)..
      (1,-1)..controls(0.7,-0.3) and (0.7,0.3)..(1,1)--cycle;
   \end{scope}}
\def\ys@frame@segmentation{%
   \draw[color=framegolden,path fading=ys circle]
   ([xshift=5\ys@frame@radius]segmentation.west) to[ornament=88]
   ([xshift=-5\ys@frame@radius]segmentation.east);}

\tcbset{
   % 控制是否在断点处的线不画出来
   ys/frame/not at break/.code=\let\ys@frame@remove@middleline\ys@frame@draw@middleline,
   ys/frame/fill opacity/.store in=\ys@frame@fill@opacity,
   ys/frame/draw at break/.code=\let\ys@frame@remove@middleline\@gobbletwo,
   % 控制线宽
   ys/frame/line width/.code={\pgfmathsetlength\ys@frame@linewidth{#1}},
   ys/frame/line width=1.4pt,
   % 控制圆弧大小，应为数字，而非长度
   ys/frame/radius/.code={\pgfmathparse{#1}\let\ys@frame@ratio\pgfmathresult
         \pgfmathsetlength\ys@frame@radius{(#1)*1em}%
         \pgfmathsetlength\ys@frame@sep{(#1)*0.5ex}},
   ys/frame/radius=2,
   ys/frame/unbroken/.style={
         interior code={%
               \ys@frame@unbrokenouter % 外框
               \foreach \ii/\jj/\kk in \ys@frame@star@list {\ys@frame@star{\ii}{\jj}{\kk}} % 星
               \ys@frame@unbrokeninner % 内线
               \ys@frame@unbrokencorner % 四角
            },
         interior titled code={%
               \ys@frame@unbrokenouter % 外框
               \foreach \ii/\jj/\kk in \ys@frame@star@list {\ys@frame@star{\ii}{\jj}{\kk}} % 星
               \ys@frame@unbrokeninner % 内线
               \ys@frame@unbrokencorner % 四角
            }
      },
   ys/frame/first/.style={
         interior code={%
               \ys@frame@firstouter
               \foreach \ii/\jj/\kk in \ys@frame@star@list@t {\ys@frame@star{\ii}{\jj}{\kk}}
               \ys@frame@firstinner
               \ys@frame@firstcorner},
         interior titled code={%
               \ys@frame@firstouter
               \foreach \ii/\jj/\kk in \ys@frame@star@list@t {\ys@frame@star{\ii}{\jj}{\kk}}
               \ys@frame@firstinner
               \ys@frame@firstcorner},
      },
   ys/frame/middle/.style={
         interior code={%
               \ys@frame@middleouter
               \ys@frame@middleinner
               \ys@frame@middlecorner}
      },
   ys/frame/last/.style={
         interior code={%
               \ys@frame@lastouter
               \foreach \ii/\jj/\kk in \ys@frame@star@list@b {\ys@frame@star{\ii}{\jj}{\kk}}
               \ys@frame@lastinner
               \ys@frame@lastcorner}
      },
   ys/frame style/unbroken/.style={
         boxsep=2\ys@frame@sep,
         left={.8\ys@frame@radius},right={.8\ys@frame@radius},
         ys/frame/unbroken,title hidden,
         segmentation code=\ys@frame@segmentation
      },
   ys/frame style/first/.style={ys/frame/first,title hidden,segmentation code=\ys@frame@segmentation},
   ys/frame style/middle/.style={ys/frame/middle,segmentation code=\ys@frame@segmentation},
   ys/frame style/last/.style={ys/frame/last,segmentation code=\ys@frame@segmentation},
   ys style/.style={frame hidden,
         ys/frame style/unbroken,
         extras first={ys/frame style/first},
         extras middle={ys/frame style/middle},
         extras last={ys/frame style/last},
      },
}
\makeatother
\newtcolorbox{fancybox}[1][]{enhanced,ys style,breakable,pad at break=2mm,
   ys/frame/not at break,ys/frame/fill opacity=0,#1,fontupper=\itshape}
% /* -------------------------------------------------------------------------- */


% /* -------------------------------------------------------------------------- */
% /*                                   定理环境设置                                   */
% /* -------------------------------------------------------------------------- */
\makeatletter
% /* ---------------------------------- 第一种定理 --------------------------------- */
\definecolor{CyaN}{HTML}{dbe1e5}
\colorlet{OrangE}{yellow!20!orange}
\colorlet{BluE}{cyan!70!blue}
\colorlet{ReD}{red!20!orange}
\colorlet{GreeN}{yellow!40!green}
\tcbset{my@basic@thm/.style={enhanced jigsaw, breakable,
         enlarge left by=-3.5mm, width=\textwidth+3.5mm, boxrule=0pt,
         top=2pt, bottom=2pt, left=2.5mm, frame hidden}}
\newcommand{\@my@newtheorem@n}[1]{\ERROR}
\newcommand{\@my@newtheorem@nn}[2]{%
   \@ifundefined{#1}{\@my@newtheorem{#1}#2}{\@my@renewtheorem{#1}#2}}
\NewDocumentCommand{\@my@newtheorem}{ m m o +m }
{\IfNoValueTF{#3}{\newtheorem{#1}{#2}}{\newtheorem{#1}{#2}[#3]}%
   \tcbset{my@#1@thmstyle/.style={#4}}%
   \tcolorboxenvironment{#1}{my@basic@thm, my@#1@thmstyle}}
\NewDocumentCommand{\@my@renewtheorem}{ m m o +m }
{\IfNoValueTF{#3}{\renewtheorem{#1}{#2}}{\renewtheorem{#1}{#2}[#3]}%
   \tcbset{my@#1@thmstyle/.style={#4}}}

% ---------------------------------------------------------------------------------- %
% /* ---------------------------------- 第二种定理 --------------------------------- */
\tcbset{my@basic@tcbthm/.style={detach title,}}
\newcommand{\@my@newtcbtheorem@n}[1]{\ERROR}
\newcommand{\@my@newtcbtheorem@nn}[2]{%
   \@ifundefined{#1}{\@my@newtcbtheorem{#1}{#2}}{\@my@renewtcbtheorem{#1}{#2}}}
\newcommand{\@my@newtcbtheorem}[2]{%
   \edef\my@curr@thmenvname{#1}% 它保存当前定理环境的名称
   \mytcbtheoremset{#2}%
   \NewTColorBox{#1}{ O{} O{} o }
   {my@basic@tcbthm, my@#1@tcbthmstyle, title={##2}, IfNoValueF={##3}{label={##3}}, ##1}}
\newcommand{\@my@renewtcbtheorem}[2]{\edef\my@curr@thmenvname{#1}\mytcbtheoremset{#2}}

% 键值设置
\pgfkeys{/mytcbtheorem/.is family}
\newcommand{\mytcbtheoremset}{\pgfqkeys{/mytcbtheorem}}
\mytcbtheoremset{
name/.code=\@namedef{\my@curr@thmenvname @name}{#1}, %无效
counter/.code=\@namedef{my@\my@curr@thmenvname @counter}{#1}\newcounter{#1}[chapter], % 计数器遇到subsection就会自动归零 % https://zhuanlan.zhihu.com/p/57454848#circle=on
the counter/.code=\@namedef{the\@nameuse{my@\my@curr@thmenvname @counter}}{#1},
autoref name/.code=\@namedef{\@nameuse{my@\my@curr@thmenvname @counter}autorefname}{#1},
style/.code=\tcbset{my@\my@curr@thmenvname @tcbthmstyle/.style={#1}},
thmcolor/.code=\@namedef{\my@curr@thmenvname @thmcolor}{#1}, %无效
lemcolor/.code=\@namedef{\my@curr@thmenvname @lemcolor}{#1}, %无效
}
% 存储键值 (LaTeX3)
\ExplSyntaxOn
\cs_new_protected:Npn \mynewtheorem
{ \keyval_parse:NNn \@my@newtheorem@n \@my@newtheorem@nn }
\cs_new_protected:Npn \mynewtcbtheorem
{ \keyval_parse:NNn \@my@newtcbtheorem@n \@my@newtcbtheorem@nn }
\ExplSyntaxOff

%%  Overlay Settings
\newcommand{\my@theorem@overlay@unbroken}[2]{
   %%============== First ==============%%
   \fill[black!60] ([xshift=1cm,yshift=5pt]frame.north west)-- ([xshift=0.8cm,yshift=0cm]frame.north west)--([xshift=1.2cm,yshift=0cm]frame.north west)--cycle;
   \node[rectangle, text=white, blur shadow={shadow blur steps=10,shadow xshift=2pt, shadow yshift=-1pt,shadow blur radius=1.5pt,shadow opacity=35}, inner sep=1.5mm,fill=#2,
      anchor=west,rounded corners=3pt,font=\bfseries\normalsize] at ([xshift=0cm,yshift=-3.mm]frame.north west) {\hspace*{1.5em}#1.\ \ifdefvoid{\tcbtitletext}{}{(\itshape\tcbtitletext)}};
   \fill[color=#2,blur shadow={shadow blur steps=10,shadow xshift=1pt, shadow yshift=-1pt,shadow blur radius=1.5pt,shadow opacity=35}]
   ([xshift=1cm,yshift=5pt]frame.north west) {[rounded corners=3pt]--++(-1cm-5pt,0)}--++(0,-1cm-5pt)--cycle;
   \fill[color=black!60] ([xshift=-5pt,yshift=-1cm]frame.north west)--([xshift=0cm,yshift=-0.8cm]frame.north west)-- ([xshift=0cm,yshift=-1.2cm]frame.north west)--cycle;
   %%============== End ==============%%
   \fill[#2,blur shadow={shadow blur steps=10,shadow xshift=-3pt, shadow yshift=1pt,shadow blur radius=1.5pt,shadow opacity=35}]
   ([xshift=-0.05\linewidth,yshift=-5pt]frame.south east) {[rounded corners=3pt]--++(0.05\linewidth+5pt,0)}--++(0,0.05\linewidth+5pt)--cycle;
   \fill[black!60] ([xshift=-0.05\linewidth,yshift=-5pt]frame.south east) -- ([xshift=-0.04\linewidth,yshift=0pt]frame.south east)-- ([xshift=-0.06\linewidth,yshift=0pt]frame.south east)--cycle;
   \fill[black!60] ([xshift=5pt,yshift=0.05\linewidth]frame.south east)-- ([yshift=0.04\linewidth]frame.south east) -- ([yshift=0.06\linewidth]frame.south east)--cycle;
}
\newcommand{\my@theorem@overlay@first}[2]{
   \fill[black!60] ([xshift=1cm,yshift=5pt]frame.north west)-- ([xshift=0.8cm,yshift=0cm]frame.north west)--([xshift=1.2cm,yshift=0cm]frame.north west)--cycle;
   \node[rectangle, text=white, blur shadow={shadow blur steps=10,shadow xshift=1pt, shadow yshift=-1pt,shadow blur radius=1.5pt,shadow opacity=35}, inner sep=1.5mm,fill=#2, anchor=west,rounded corners=3pt,font=\bfseries\normalsize] at ([xshift=0cm,yshift=-3.mm]frame.north west) {\hspace*{1.5em}#1.\ \ifdefvoid{\tcbtitletext}{}{(\itshape\tcbtitletext)}};
   \fill[color=#2,blur shadow={shadow blur steps=10,shadow xshift=1pt, shadow yshift=-1pt,shadow blur radius=1.5pt,shadow opacity=35}]
   ([xshift=1cm,yshift=5pt]frame.north west) {[rounded corners=3pt]--++(-1cm-5pt,0)}--++(0,-1cm-5pt)--cycle;
   \fill[color=black!60] ([xshift=-5pt,yshift=-1cm]frame.north west)--([xshift=0cm,yshift=-0.8cm]frame.north west)-- ([xshift=0cm,yshift=-1.2cm]frame.north west)--cycle;
}
\newcommand{\my@theorem@overlay@last}[1]{
   \fill[#1,blur shadow={shadow blur steps=10,shadow xshift=-3pt, shadow yshift=1pt,shadow blur radius=1.5pt,shadow opacity=35}]
   ([xshift=-0.05\linewidth,yshift=-5pt]frame.south east) {[rounded corners=3pt]--++(0.05\linewidth+5pt,0)}--++(0,0.05\linewidth+5pt)--cycle;
   \fill[black!60] ([xshift=-0.05\linewidth,yshift=-5pt]frame.south east) -- ([xshift=-0.04\linewidth,yshift=0pt]frame.south east)-- ([xshift=-0.06\linewidth,yshift=0pt]frame.south east)--cycle;
   \fill[black!60] ([xshift=5pt,yshift=0.05\linewidth]frame.south east)-- ([yshift=0.04\linewidth]frame.south east) -- ([yshift=0.06\linewidth]frame.south east)--cycle;
}

% /* ------------------ Second theorem style overlay settings ----------------- */
%%定义标题文字长度%%
\newlength{\thmtcbtextlen}
%%设置临界长度%%
\newlength{\thmcriticstarlen}
\setlength{\thmcriticstarlen}{1.2\linewidth}
%
\newcommand{\my@lemma@overlay@unbroken}[2]{
   %%============== First ==============%%
   \def\rad{7pt}%
   \begin{scope} %顶部标题
      \path[fill=#2, blur shadow={shadow blur steps=10,shadow xshift=-1pt, shadow yshift=-1pt,shadow blur radius=1.5pt,shadow opacity=35}
      ]node[append after command={
               ([xshift=-1.5*\rad]thmname.north west) to[out=0,in=180,looseness=1] ([xshift=2.5*\rad]thmname.south west) --([xshift=-\rad]thmname.south east) to[out=0,in=180,looseness=1] ([xshift=3*\rad]thmname.north east) --cycle},
         text=white,font=\bfseries,align=center,inner ysep=1.5mm,minimum height=0.7cm,right] (thmname) at ([xshift=\rad,yshift=-.7*\rad]frame.north west) {\hspace*{10pt}#1.\ \ifdefvoid{\tcbtitletext}{}{(\itshape\tcbtitletext)}};
      \pgfextractx{\thmtcbtextlen}{%
         \pgfpointdiff
         {\pgfpointanchor{thmname}{west}}
         {\pgfpointanchor{thmname}{east}}}
      %%============== 两边的阴影/折叠部分 ==============%%
      \begin{pgfonlayer}{bottom}
         % 左侧翅膀样式一
         % \shade[left color=#2!20, right color=#2!80!black]
         % ([xshift=-1.5*\rad]thmname.north west)
         % to[out=180, in=0] ++(-2*\rad, -\rad)
         % -| +(5*\rad,\rad)
         % -- cycle;
         % /* -------------------------------------------------------------------------- */
         % 左侧翅膀样式二：镜像翻转为向上折叠效果
         \shade[left color=#2!20, right color=#2!80!black]
         ([shift={(-.5*\rad,-\rad)}]thmname.north west)
         to[out=180, in=0] ++(-2*\rad, \rad) % 将 -\rad 改为 \rad，使其向上延伸
         -| +(5*\rad, -\rad)                 % 将 \rad 改为 -\rad，使其向下回到主体水平线
         -- cycle;
         % 右侧翅膀：完全镜像处理
         % \shade[right color=#2!20, left color=#2!80!black]
         % ([xshift=3*\rad]thmname.north east) % 注意这里起点需对应你核心代码中的 3*\rad
         % to[out=0, in=180] ++(2*\rad, -\rad) % 镜像：out 180->0, in 0->180, x -2->2
         % -| +(-5*\rad,\rad)                % 镜像：x 5->-5
         % -- cycle;
         % ===== 右翅膀按条件切换 =====
         %判断标题文字长度与临界长度的关系
         \ifdim\thmtcbtextlen>\thmcriticstarlen
            %-------- 右侧小翅膀：上下翻转版本 --------
            \shade[right color=#2!20, left color=#2!80!black]
            ([xshift=2*\rad,yshift=-1*\rad]thmname.north east)
            to[out=0, in=180] ++(2*\rad, \rad)
            -| +(-5*\rad,-\rad)
            -- cycle;
         \else
            % -------- 右侧小翅膀：原版本 --------
            \shade[right color=#2!20, left color=#2!80!black]
            ([xshift=3*\rad]thmname.north east)
            to[out=0, in=180] ++(2*\rad, -\rad)
            -| +(-5*\rad,\rad)
            -- cycle;
         \fi
      \end{pgfonlayer}
   \end{scope}
   %
   %%============== End ==============%%
   \def\tlen{1.5cm}
   \def\Rad{3.5pt}
   \def\theight{0.5cm}
   \begin{scope} % 底部装饰
      \path[fill=#2,drop shadow={opacity=0.3,shadow xshift=.3pt}]
      ([xshift=-2*\rad,yshift=-5pt]frame.south east) coordinate (SE)  to[out=0,in=180] +(4*\rad,5pt+\theight) --([shift={(-\tlen+4*\rad,5pt+\theight)}]SE) to[out=180,in=0] +(-4*\rad,-5pt-\theight) --cycle;
      \begin{pgfonlayer}{bottom}
         % 左侧翅膀：镜像翻转为向上折叠效果
         \shade[left color=#2!20, right color=#2!80!black]
         ([shift={(-1.35*\tlen+\Rad,-5pt)}]frame.south east)
         to[out=180, in=0] ++(-2*\rad, \rad) % 将 -\rad 改为 \rad，使其向上延伸
         -| +(5*\rad, -\rad)                 % 将 \rad 改为 -\rad，使其向下回到主体水平线
         -- cycle;
      \end{pgfonlayer}
   \end{scope}
}
% /* -------------------------------------------------------------------------- */
\newcommand{\my@lemma@overlay@first}[2]{
   %%============== First ==============%%
   \def\rad{7pt}%
   \begin{scope} %顶部标题
      \path[fill=#2, blur shadow={shadow blur steps=10,shadow xshift=-1pt, shadow yshift=-1pt,shadow blur radius=1.5pt,shadow opacity=35}
      ]node[append after command={
               ([xshift=-1.5*\rad]thmname.north west) to[out=0,in=180,looseness=1] ([xshift=2.5*\rad]thmname.south west) --([xshift=-\rad]thmname.south east) to[out=0,in=180,looseness=1] ([xshift=3*\rad]thmname.north east) --cycle},
         text=white,font=\bfseries,align=center,inner ysep=1.5mm,minimum height=0.7cm,right] (thmname) at ([xshift=\rad,yshift=-.7*\rad]frame.north west) {\hspace*{10pt}#1.\ \ifdefvoid{\tcbtitletext}{}{(\itshape\tcbtitletext)}};
      \pgfextractx{\thmtcbtextlen}{%
         \pgfpointdiff
         {\pgfpointanchor{thmname}{west}}
         {\pgfpointanchor{thmname}{east}}}
      %%============== 两边的阴影/折叠部分 ==============%%
      \begin{pgfonlayer}{bottom}
         % 左侧翅膀样式一
         % \shade[left color=#2!20, right color=#2!80!black]
         % ([xshift=-1.5*\rad]thmname.north west)
         % to[out=180, in=0] ++(-2*\rad, -\rad)
         % -| +(5*\rad,\rad)
         % -- cycle;
         % /* -------------------------------------------------------------------------- */
         % 左侧翅膀样式二：镜像翻转为向上折叠效果
         \shade[left color=#2!20, right color=#2!80!black]
         ([shift={(-.5*\rad,-\rad)}]thmname.north west)
         to[out=180, in=0] ++(-2*\rad, \rad) % 将 -\rad 改为 \rad，使其向上延伸
         -| +(5*\rad, -\rad)                 % 将 \rad 改为 -\rad，使其向下回到主体水平线
         -- cycle;
         % 右侧翅膀：完全镜像处理
         % \shade[right color=#2!20, left color=#2!80!black]
         % ([xshift=3*\rad]thmname.north east) % 注意这里起点需对应你核心代码中的 3*\rad
         % to[out=0, in=180] ++(2*\rad, -\rad) % 镜像：out 180->0, in 0->180, x -2->2
         % -| +(-5*\rad,\rad)                % 镜像：x 5->-5
         % -- cycle;
         % ===== 右翅膀按条件切换 =====
         %判断标题文字长度与临界长度的关系
         \ifdim\thmtcbtextlen>\thmcriticstarlen
            %-------- 右侧小翅膀：上下翻转版本 --------
            \shade[right color=#2!20, left color=#2!80!black]
            ([xshift=2*\rad,yshift=-1*\rad]thmname.north east)
            to[out=0, in=180] ++(2*\rad, \rad)
            -| +(-5*\rad,-\rad)
            -- cycle;
         \else
            % -------- 右侧小翅膀：原版本 --------
            \shade[right color=#2!20, left color=#2!80!black]
            ([xshift=3*\rad]thmname.north east)
            to[out=0, in=180] ++(2*\rad, -\rad)
            -| +(-5*\rad,\rad)
            -- cycle;
         \fi
      \end{pgfonlayer}
   \end{scope}
}
% /* -------------------------------------------------------------------------- */
\newcommand{\my@lemma@overlay@last}[1]{
   %%============== End ==============%%
   \def\tlen{1.5cm}
   \def\Rad{3.5pt}
   \def\theight{0.5cm}
   \def\rad{7pt}%
   \begin{scope} % 底部装饰
      \path[fill=#1,drop shadow={opacity=0.3,shadow xshift=.3pt}]
      ([xshift=-2*\rad,yshift=-5pt]frame.south east) coordinate (SE)  to[out=0,in=180] +(4*\rad,5pt+\theight) --([shift={(-\tlen+4*\rad,5pt+\theight)}]SE) to[out=180,in=0] +(-4*\rad,-5pt-\theight) --cycle;
      \begin{pgfonlayer}{bottom}
         % 左侧翅膀：镜像翻转为向上折叠效果
         \shade[left color=#1!20, right color=#1!80!black]
         ([shift={(-1.35*\tlen+\Rad,-5pt)}]frame.south east)
         to[out=180, in=0] ++(-2*\rad, \rad) % 将 -\rad 改为 \rad，使其向上延伸
         -| +(5*\rad, -\rad)                 % 将 \rad 改为 -\rad，使其向下回到主体水平线
         -- cycle;
      \end{pgfonlayer}
   \end{scope}
}
\makeatother

% /* -------------------------------------------------------------------------- */

% /* ------------------------------- 一种垂直线状列表样式 ------------------------------- */
% https://tex.stackexchange.com/questions/454744/bulleted-list-with-vertical-lines?noredirect=1&lq=1
\RequirePackage{tikzpagenodes,refcount} % 页面定位宏包
\newcounter{mylist} % new counter for amount of lists
\newcounter{mycnt}[mylist] % create new item counter
\newcounter{mytmp}[mylist] % tmp counter needed for checking before/after current item

\newcommand{\drawoptionsconn}{outermarginfgcolor, shorten <= .5mm, shorten >= .5mm, thick,dotted}
\newcommand{\drawoptionsshort}{outermarginfgcolor, shorten <= .5mm, shorten >= -1mm, thick,dotted}

\newcommand{\myitem}{% Modified `\item` to update counter and save nodes
   \stepcounter{mycnt}%
   \item[\linkedlist{%
                  i\alph{mylist}\arabic{mycnt}}]%
   \label{item-\alph{mylist}\arabic{mycnt}}%
   \ifnum\value{mycnt}>1%
      \ifnum\getpagerefnumber{item-\alph{mylist}\arabic{mytmp}}<\getpagerefnumber{item-\alph{mylist}\arabic{mycnt}}%
         \begin{tikzpicture}[remember picture,overlay]%
            \expandafter\draw\expandafter[\drawoptionsshort] (i\alph{mylist}\arabic{mycnt}) --
            ++(0,3mm) --
            (i\alph{mylist}\arabic{mycnt} |- current page text area.north);% draw short line
         \end{tikzpicture}%
      \else%
         \begin{tikzpicture}[remember picture,overlay]%
            \expandafter\draw\expandafter[\drawoptionsconn] (i\alph{mylist}\arabic{mytmp}) -- (i\alph{mylist}\arabic{mycnt});% draw the connecting lines
         \end{tikzpicture}%
      \fi%
   \fi%
   \addtocounter{mytmp}{2}%
   \IfRefUndefinedExpandable{item-\alph{mylist}\arabic{mytmp}}{}{% defined
      \ifnum\getpagerefnumber{item-\alph{mylist}\arabic{mytmp}}>\getpagerefnumber{item-\alph{mylist}\arabic{mycnt}}%
         \begin{tikzpicture}[remember picture,overlay]%
            \expandafter\draw\expandafter[\drawoptionsshort] (i\alph{mylist}\arabic{mycnt}) --
            ++(0,-3mm) --
            (i\alph{mylist}\arabic{mycnt} |- current page text area.south);% draw short line
         \end{tikzpicture}%
      \fi%
   }%
   \addtocounter{mytmp}{-1}%
}

\newcommand{\linkedlist}[1]{
   \raisebox{0pt}[0pt][0pt]{\begin{tikzpicture}[remember picture]%
         \node (#1) [ball color=outermarginfgcolor,circle,fill,inner sep=1.5pt, shading=ball]{};
         \draw[outermarginfgcolor] (#1) circle (3.25pt);
      \end{tikzpicture}}%
}

\newenvironment{myitemize}{%
   % Create new `myitemize` environment to keep track of the counters
   \stepcounter{mylist}% increment list counter
   \begin{itemize}
      }{\end{itemize}%
}
% /* -------------------------------------------------------------------------- */

% 功能其实很简单，就是给\mathbb 之类的变体提供一个shortcut。思路也不难，用了递归的宏展开。效果如下：

% \bbR/\bR
% \bsR
% \calR
% \frakR
% \rmR
% \bfR

% ---------------------------------------------------------------------------- %
\makeatletter
\def\@buildmath#1{
   \expandafter\def\csname b#1\endcsname{\mathbb{#1}}
   \expandafter\def\csname bs#1\endcsname{\boldsymbol{#1}}
   \expandafter\def\csname scr#1\endcsname{\mathscr{#1}}
   \expandafter\def\csname cal#1\endcsname{\mathcal{#1}}
   \expandafter\def\csname frak#1\endcsname{\mathfrak{#1}}
   \expandafter\def\csname rm#1\endcsname{\mathrm{#1}}
   \expandafter\def\csname bf#1\endcsname{\mathbf{#1}}
}
% Cycle through letters
\def\@buildmathletters#1{
   \ifx#1\relax\else
      \@buildmath{#1}
      \expandafter\@buildmathletters
   \fi
}
\@buildmathletters ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqstuvwxyz\relax
\makeatother %如果用了bprod包，有\br命令冲突就去掉r即可！
% ---------------------------------------------------------------------------- %

% 定义了\remember{#1}{#2} 和 \recall{#1} 两个命令。
% \remember的作用是把#2 的公式打上#1 的tag，并且定义一个宏记住这个公式。
% 这个定义好的公式可以通过\recall{#1}原样呈现出来。
% 比如
%     Remember an equation:
%     \begin{equation}
%     \remember{thm:pythagorean}{
%         a^2 + b^2 = c^2
%     }
%     \end{equation}

%     Another equation:
%     \begin{equation}
%     a^2 + b^2 = c^2 - 2ab\cos C\label{thm:cosine}
%     \end{equation}

%     Now we recall the first equation:
%     \begin{equation}
%     \recall{thm:pythagorean}
%     \end{equation}---------------------------------------------------------------------------- %
\newcommand\remember[2]{
   % \makeatletter
   \expandafter\gdef\csname @labeled:#1\endcsname{#2}\label{#1}#2
   % \makeatother
}

\newcommand\recall[1]{
   % \makeatletter
   \csname @labeled:#1\endcsname\tag{\ref{#1}}
   % \makeatother
}
% /* -------------------------------------------------------------------------- */

% /* ---------------------------- 第三套定理环境-见textbook --------------------------- */

% /* ----------------------------------- 定理主题颜色默认值 ---------------------------------- */
\newcommand\thmcolor{teal}
\newcommand\thmtitlecolor{teal!80!black}
\newcommand\thmbackcolor{teal}
% -----------------------------------------------------------%
\tcbset{%
   thm color/.store in=\thmcolor, % The whole theme color
   thm title color/.store in=\thmtitlecolor, % The color of boxtitle
   thm back color/.store in=\thmbackcolor, % The color of background
   % ----------------------------------------------------------%
   thm colors/.style={
         thm color,
         thm title color,
         thm back color,
      },
   % /* -------------------------------------------------------- */
   thmstyle/.style={%
         breakable,%
         skin=enhancedlast jigsaw,%
         before skip=2mm,%
         enhanced,%
         width=\textwidth,
         after skip=3mm,%
         % left skip=2mm,%
         % right skip=2mm,%
         rounded corners,sharp corners=northwest, %
         opacityframe=0.5,opacityback=0.25,opacitybacktitle=0.5,
         colframe=\thmcolor!15!white,
         colbacktitle=\thmtitlecolor!80!black,
         interior style={
               top color=\thmbackcolor!10!white,
               middle color=\thmbackcolor!7!white,
               bottom color=\thmbackcolor!4!white
            },
         boxrule=0pt,
         left=1.5ex,%
         right=1.5ex,%
         segmentation style={draw=\thmcolor!70,dashed,thick},
         attach boxed title to top left={xshift=0.29cm,%
               yshift*=1mm-\tcboxedtitleheight},%
         boxed title style={frame code={
                     \path[fill=\thmcolor!30]
                     ([yshift=-1mm,xshift=-1mm]frame.north west)
                     arc[start angle=0,end angle=180,radius=1mm]
                     ([yshift=-1mm,xshift=1mm]frame.north east)
                     arc[start angle =180,end angle=0,radius=1mm];
                     \path[fill=\thmcolor]
                     ([xshift=-2mm]frame.north west) -- ([xshift=2mm]frame.north east)
                     [rounded corners=1mm]-- ([xshift=1mm,yshift=-1mm]frame.north east)
                     -- (frame.south east) -- (frame.south west)
                     -- ([xshift=-1mm,yshift=-1mm]frame.north west)[sharp corners]-- cycle;},interior engine=empty,
            },
         fonttitle=\bfseries,
         % before skip balanced=5pt,after skip balanced=20pt,
         fuzzy shadow={-0.6mm}{0.6mm}{0mm}{0.3mm}{white!50!gray},% 上
         fuzzy shadow={0.6mm}{-0.6mm}{0mm}{0.3mm}{fill=white!40!gray},%下
      },
}
% /* -------------------------------------------------------------------------- */
\endinput