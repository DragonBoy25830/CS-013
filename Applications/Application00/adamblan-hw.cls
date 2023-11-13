\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{adamblan-hw}

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}

\DeclareOption{nopagenumbers}{\AtBeginDocument{\nopagenumbers}}
\DeclareOption{noquestionnumbers}{\AtBeginDocument{\noquestionnumbers}}
\DeclareOption{verification}{\AtBeginDocument{\verification}}

\ProcessOptions\relax
\LoadClass{article}

\usepackage{amsmath, amsfonts, amsthm, amssymb}  % Some math symbols
\usepackage{fullpage, xcomment}
\usepackage{refcount}
\usepackage[x11names, rgb]{xcolor}
\usepackage{graphicx}
\usepackage{tikz}
\usetikzlibrary{decorations,arrows,shapes}

\usepackage{etoolbox}
\usepackage{xparse, ifthen, environ}
\usepackage{enumitem}
\usepackage{listings}

\usepackage{environ}
\newsavebox{\saveblock}

\setlength{\parindent}{0pt}
\setlength{\parskip}{5pt plus 1pt}

\newcommand{\nopagenumbers}{
    \pagestyle{empty}
}

\def\indented#1{\list{}{}\item[]}
\let\indented=\endlist

\providetoggle{questionnumbers}
\settoggle{questionnumbers}{true}
\newcommand{\noquestionnumbers}{
    \settoggle{questionnumbers}{false}
}

\newcommand{\checkedjudgements}{0}
\newboolean{matchesanynotdone}
\newcommand{\ifmatches}[3]{\ifthenelse{\boolean{matchesanynotdone}}{\ifnum#1=#2#3\setboolean{matchesanynotdone}{false}\fi}{}}
\newcommand{\ifmatchesanyint}{}
\NewDocumentCommand{\ifmatchesany}{m > {\SplitList{,}} m m}{%
    \setboolean{matchesanynotdone}{true}%
    \renewcommand{\ifmatchesanyint}[1]{\ifmatches{#1}{##1}{#3}}%
    \ProcessList{#2}{\ifmatchesanyint}%
}

\newcommand{\optionalcheck}[1]{\ifmatchesany{\arabic#1}{\checkedjudgements}{$\times$}}%
\newcommand{\judgementcheckcell}[1]{(\makebox[12pt]{\optionalcheck{#1}})}
\newlist{judgements}{enumerate}{1}
\setlist[judgements]{itemsep=0.6em, label={\footnotesize\arabic*} \judgementcheckcell*, style=standard}
\newcommand{\resetjudgements}{\global\def\checkedjudgements{0}}
\NewDocumentCommand{\judge}{o m}{%
    \text{\scriptsize\color{red}(#2)\IfValueT{#1}{ [#1]}}%
    \global\edef\checkedjudgements{\checkedjudgements,#2}%
}%

% Usage:
% \newrubric{shortname}{Human Readable Name}{
%   \item Judgement 1
%   \item Judgement 2
%   \item Judgement 3
% }
\newcommand{\newrubric}[3]{%
    \expandafter\newcommand\csname #1@rubricname \endcsname{#2}%
    \expandafter\newcommand\csname #1@rubriccontent \endcsname{#3}%
}

\newcommand{\getrubricname}[1]{\csname #1@rubricname \endcsname}
\newcommand{\getrubriccontent}[1]{\csname #1@rubriccontent \endcsname}

% Usage:
% \makerubric{shortname} or \makerubric[resume]{shortname}
% Assumes that it is used inside a description environment.
\newcommand{\makerubric}[2][]{%
    \item[\getrubricname{#2}]\
    \begin{judgements}[#1]
        \getrubriccontent{#2}
    \end{judgements}
}

\newboolean{firstrubric}
% wrapper for makerubric which uses a boolean to determine whether to resume
\newcommand{\makeveriint}[1]{%
    \ifthenelse{\boolean{firstrubric}}{%
        \makerubric{#1}%
    }{%
        \makerubric[resume]{#1}%
    }%
    
    %\makerubric[\ifthen{\boolean{notfirstrubric}}{resume}]{#1}W
    %\item[\getrubricname{#1}]
    \setboolean{firstrubric}{false}%
}

\NewDocumentCommand{\makeveri}{> {\SplitList{,}} m}{%
    \textbf{Directions:} \emph{For each ``judgement'' in this
    rubric, determine if it applies anywhere to the above proof.  If it does apply, check the box and note the number on the proof itself where the error occurs.}
    \vspace{1em}
    
    \setboolean{firstrubric}{true}%
    \begin{description}%
        \ProcessList{#1}{\makeveriint}
    \end{description}%
    \resetjudgements%
}

\newcommand{\setveri}[2]{
    \global\expandafter\def\csname veri@#1 \endcsname{\makeveri{#2}}
}

\newcommand{\firstoftwo}[2]{#1}
\newcommand{\secondoftwo}[2]{#2}
\let\ifverificationthenelse\secondoftwo
\newcommand{\verification}{
    \let\ifverificationthenelse\firstoftwo
    \input{verification.tex}
}

\newcounter{questionCounter}
\setcounter{questionCounter}{0}
\newboolean{veri-is-defined}
\newcommand{\curveri}{}
\NewDocumentEnvironment{question}{O{\arabic{questionCounter}} m +b}{%

     \vspace{.25in} \hrule \vspace{0.4em}%
         \noindent{\bf \iftoggle{questionnumbers}{#1: }{}#2}%
     \vspace{0.8em} \hrule \vspace{.10in}%
    \addtocounter{questionCounter}{1}%
    \setcounter{partCounter}{0}%
    \ifverificationthenelse{% in verification mode
        \ifcsname veri@#1 \endcsname%
            \setboolean{veri-is-defined}{true}%
            \renewcommand{\curveri}{\csname veri@#1 \endcsname}%
        \else
            \setboolean{veri-is-defined}{false}%
        \fi%
        \ifthenelse{\boolean{veri-is-defined}}{%
            \vspace{.25in} \hrule \vspace{0.4em}%
            \noindent{\bf \iftoggle{questionnumbers}{#1: }{}#2}%
            \vspace{0.8em} \hrule \vspace{.10in}%
        }{%
            % \begin{comment}
        }
    }{
    #3
  \ifnum\the\value{partCounter}=0{
  \begin{lrbox}{\saveblock}
    \begin{minipage}{\linewidth}
     #3
    \end{minipage}
  \end{lrbox}%
  \ifdim\dimexpr\ht\saveblock+\dp\saveblock < 600 pt  \else       
  \begin{tikzpicture}[remember picture,overlay]
\node[rotate=75,color=red,scale=10,text opacity=1]
at (current page.center) {TOO LONG};
\end{tikzpicture}
                 \begin{center}
             \color{red}\textbf{This question is too long. 
 It cannot be longer than a single page by itself. Your document has been truncated.}
        \end{center}
\end{document}
\fi
    }\else{}\fi
    }
}{%
    \ifverificationthenelse{% in verification mode
        \ifthenelse{\boolean{veri-is-defined}}{%
            \phantom{}\AtBeginPage{}
            \newpage
            \curveri
            \newpage
        }{%
            % \end{comment}
        }%
    }{% not in verification mode, just render the body
        \phantom{}
        \newpage
    }%
}

\newcounter{partCounter}[questionCounter]
%\RenewDocumentEnvironment{part}{O{\alph{partCounter}}}{%


\RenewEnviron{part}{%
    \addtocounter{partCounter}{1}%
    \vspace{.10in}%
    \begin{indented}%
       {\bf (\alph{partCounter})}
  \begin{lrbox}{\saveblock}
    \begin{minipage}{\linewidth}
      \BODY
    \end{minipage}
  \end{lrbox}%
  \ifdim\dimexpr\ht\saveblock+\dp\saveblock < 600 pt {\BODY} \else {   
\BODY
        \begin{tikzpicture}[remember picture,overlay]
\node[rotate=75,color=red,scale=10,text opacity=1]
at (current page.center) {TOO LONG};
\end{tikzpicture}
        \begin{center}
             \color{red}\textbf{This part is too long. 
 It cannot be longer than a single page by itself. Your document has been truncated.}
        \end{center}

\end{document}}\fi
        %\end{page-checker}
    \end{indented}
}


\edef\oldtt{\ttdefault}
\usepackage[scaled]{beramono}
\usepackage[T1]{fontenc}
\renewcommand*\ttdefault{\oldtt}

\lstdefinelanguage{Scheme}{
  morekeywords=[1]{define, define-syntax, define-macro, lambda, define-stream, stream-lambda},
  morekeywords=[2]{begin, call-with-current-continuation, call/cc,
    call-with-input-file, call-with-output-file, case, cond,
    do, else, for-each, if,
    let*, let, let-syntax, letrec, letrec-syntax,
    let-values, let*-values,
    and, or, not, delay, force,
    quasiquote, quote, unquote, unquote-splicing,
    map, fold, syntax, syntax-rules, eval, environment, query },
  morekeywords=[3]{import, export},
  alsodigit=!\$\%&*+-./:<=>?@^_~,
  sensitive=true,
  morecomment=[l]{;},
  morecomment=[s]{\#|}{|\#},
  morestring=[b]",
  basicstyle=\small\ttfamily,
  keywordstyle=\bf\ttfamily\color[rgb]{0,.3,.7},
  commentstyle=\color[rgb]{0.133,0.545,0.133},
  stringstyle={\color[rgb]{0.75,0.49,0.07}},
  upquote=true,
  breaklines=true,
  breakatwhitespace=true,
  literate=*{`}{{`}}{1}
}

\lstdefinelanguage{JavaScript}{
  morekeywords={typeof, new, true, false, catch, function, return, null, catch, switch, var, if, in, while, do, else, case, break},
  morecomment=[s]{/*}{*/},
  morecomment=[l]//,
  morestring=[b]",
  morestring=[b]'
}

\lstset{ %
    language=Java, numbers=left, numberstyle=\footnotesize, stepnumber=1,
    numbersep=8pt, showspaces=false, showstringspaces=false, tabsize=4,
    breaklines=true, breakatwhitespace=false,
    basicstyle=\footnotesize\fontfamily{fvm}\selectfont, columns=flexible,
    mathescape=true, escapeinside={(*}{*)},
    %morekeywords={},
    keywordstyle=[2]\color{magenta}, keywords=[2]{FlipCoin, RollDie},
    otherkeywords={@requires, @ensures},
    moredelim=**[is][{\btHL[fill=yellow]}]{`}{`},
}

\newcommand{\codefont}{\fontfamily{fvm}\selectfont}

\newcommand{\textcode}[1]{\text{\it\codefont#1}}

\lstdefinestyle{tinycode}{numbers=none,basicstyle=\tiny\fontfamily{fvm}\selectfont}
\lstdefinestyle{smallcode}{numbers=none,basicstyle=\scriptsize\fontfamily{fvm}\selectfont}
\newcommand{\bgcol}{black}
\lstdefinestyle{smallcoden}{numberstyle=\color{\bgcol}\tiny,basicstyle=\scriptsize\fontfamily{fvm}\selectfont}
\lstdefinestyle{largecode}{basicstyle=\Large\fontfamily{fvm}\selectfont}
\lstdefinestyle{nonumbers}{numbers=none}

\newrubric{style}{Writing Style}{
    \item Cites that steps are ``trivial'', ``obvious'' or ``by definition'' when they require justification
    \item Omits a justification that is an application of a theorem or definition
    \item The proof does not have a conclusion
    \item Uses implication arrows between steps
    \item Mixes mathematical symbols and words in sentences
    \item Confuses equals signs with implication (or bi-implication) arrows
}

\newrubric{variables}{Well-defining Variables}{
    \item Uses a variable without declaration or quantification
    \item Variable declaration or quantification does not match the declaration/quantification in the claim.
    \item Quantifies a variable multiple times (both ``arbitrary'' and ``a specific thing'')
    \item Instantiates variables in the wrong order (or makes a variable dependent on an undefined variable)
    \item Chooses a set of values for an existential instead of a single one
    
    \item Starts a chain of equations with ``let'' or ``assume'' (this does not make sense)
    \item Lacks at least one conclusion
    \item The proof does not provide any justifications for any step of the mathematical derivation
}

\newrubric{logic}{Logical Errors}{
    \item Typo in the proof changes the meaning of the proof.
    \item The proof contains inconsistent or undefined notation (e.g., uses $f(n)$ and $f_n$ interchangeably without defining notation).
    \item The proof misuses mathematical symbols (e.g., $\in$ instead of $\subseteq$).
    \item Proof makes an assumption without explicitly stating that assumption.
    \item Several consecutive steps of the proof are unrelated or unconnected.
    \item Starts from the conclusion and arrives at something which is true instead of going forward.  (This is ``backwards reasoning''.) % rephrase for clarity
    \item Attempts to prove something false (instead of proving something true)
    \item Proves the converse of the statement instead of the intended statement.
    \item Lacks proofs in both directions for an if-and-only-if.
    \item Uses proof by contradiction when it is unnecessary (this usually happens when the contradiction is the claim they were trying to prove).
    \item $\implies$ does not use two truth statements (e.g., a set definition instead of declaring membership in that set).
}

\newrubric{induction}{Induction}{
    \item Uses $P(n)$ or refers to ``the claim'' without defining it.
    \item Uses a function as a statement or the reverse (e.g. proves ``$P(n) = n + 1$'' by induction on $n$)
    \item Has a mismatch between variables in the definition of $P(n)$ or the IH.
    \item Induction step increments the wrong variable in strong induction.
    % Base Cases
    \item Too few (but at least one) base case(s) are given to establish the induction hypothesis.
    \item The proof includes an unnecessary base case.
    % Induction Hypothesis
    \item The induction hypothesis states ``assume $P(k)$'' without defining $k$ (either before or after)
    \item The induction hypothesis quantifies at least one variable incorrectly.
    \item The induction hypothesis assumes the conclusion of the proof.
    \item The induction hypothesis does not say ``assume,'' ``suppose,'' or something similar.
    \item The induction hypothesis assumes $P(k) \implies P(k+1)$ instead of just $P(k)$.
    %\item The induction hypothesis assumes the statement holds for ``some $k \leq L$, $k \geq 0$'' instead of ``all $k \leq L, k \geq 0$'' where $L$ is the variable inducted on in the strong induction hypothesis.
    %\item States in the IH ``assume for some $L$ that $P(k)$ is true for all $0 \leq k \leq L$'', but then goes on in the Induction Step to show that $P(k+1)$ is true.
    % Induction Step
    \item The induction step assumes the conclusion (independently of the induction hypothesis).
    \item The proof does not explicitly invoke the induction hypothesis.
    \item The induction step invokes the induction hypothesis in a part of the argument unrelated to the induction hypothesis.
}

\renewcommand{\documentclass}{}