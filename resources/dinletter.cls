\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{dinletter}

\RequirePackage[a4paper]{geometry}
\RequirePackage{graphicx}
\RequirePackage{siunitx}
\RequirePackage{array}
\RequirePackage[hidelinks, bookmarks]{hyperref}
\RequirePackage{pgf}
\RequirePackage{pgfpages}
\RequirePackage{color}
\RequirePackage{textpos}
\RequirePackage{eso-pic}
\RequirePackage{scrextend}
\RequirePackage{soul}
\RequirePackage{etoolbox}
\RequirePackage{lastpage}
\RequirePackage{xcolor,colortbl}
\RequirePackage{booktabs}
\RequirePackage{tabu}
\RequirePackage{longtable}
\RequirePackage{polyglossia}


\RequirePackage[bold-style=ISO]{unicode-math}

\sisetup{locale=DE, detect-weight=true, detect-family=true}
\DeclareSIUnit[number-unit-product = \,]{\euro}{€}

\setmainlanguage{german}

\setmainfont
[
	BoldFont={Open Sans Semibold},
	ItalicFont={Open Sans Italic},
	BoldItalicFont={Open Sans Semibold Italic}
]{Open Sans}
\setsansfont{Open Sans}

\setmathfont{Open Sans}
\setmathfont[version=bold]{Open Sans Semibold}

\newfontfamily\headingseries{Open Sans Semibold}
\newfontfamily\logoseries{Open Sans}

\setmonofont[Scale=MatchLowercase]{Open Sans}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Options
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newcommand\@ptsize{}

\DeclareOption{10pt}{\renewcommand\@ptsize{0}}
\DeclareOption{11pt}{\renewcommand\@ptsize{1}}
\DeclareOption{12pt}{\renewcommand\@ptsize{2}}
\ExecuteOptions{10pt}
\ProcessOptions

\input{size1\@ptsize.clo}

\pagenumbering{arabic}

\geometry{left=25mm,right=25mm,bottom=45mm,top=0mm,headheight=45mm,headsep=0mm,footskip=0mm,includeheadfoot}

\makeatletter

\def\sendername#1{\def\@sendername{#1}}
\sendername{Absender}
\def\senderstreet#1{\def\@senderstreet{#1}}
\senderstreet{Str.~1}
\def\sendertown#1{\def\@sendertown{#1}}
\sendertown{10000~Stadt}

\def\receivernotesone#1{\def\@receivernotesone{#1}}
\receivernotesone{~}
\def\receivernotestwo#1{\def\@receivernotestwo{#1}}
\receivernotestwo{~}
\def\receivernotesthree#1{\def\@receivernotesthree{#1}}
\receivernotesthree{~}

\def\receivercompany#1{\def\@receivercompany{#1}}
\receivercompany{~}
\def\receivertitle#1{\def\@receivertitle{#1}}
\receivertitle{Frau}
\def\receivername#1{\def\@receivername{#1}}
\receivername{Empfänger}
\def\receiverstreet#1{\def\@receiverstreet{#1}}
\receiverstreet{Str.~2}
\def\receivertown#1{\def\@receivertown{#1}}
\receivertown{20000~Stadt}
\def\receivercountry#1{\def\@receivercountry{#1}}
\receivercountry{~}

\def\bullet#1{\def\@bullet{#1}}
\bullet{~·~}

\def\subject#1{\def\@subject{#1}}
\subject{Subject}

\def\date#1{\def\@date{#1}}
\date{\today}

\def\invoicenumber#1{\def\@invoicenumber{#1}}
\invoicenumber{0}

\def\location#1{\def\@location{#1}}
\location{Location}

\def\header#1{\def\@header{#1}}
\header{\colorbox{black!5}{\parbox[t][45mm]{\paperwidth}{~}}}

\def\footer#1{\def\@footer{#1}}
\footer{\colorbox{black!5}{\parbox[t][50mm]{\paperwidth}{~}}}

\def\showcorners#1{\def\@showcorners{#1}}
\showcorners{1}

\newcommand\formateuro[1]%
{
	\sisetup{%
  group-separator={.},
  round-precision=2,
  round-mode=places,
  group-minimum-digits=1,
  round-integer-to-decimal}
  \SI{#1}{\euro}
}

\newcommand\informationentry[2]%
{%
	\fontsize{8pt}{10pt}\selectfont
	#1:~#2%
	\par%
}

\newcommand\informationentrysingle[1]%
{%
	\fontsize{8pt}{10pt}\selectfont
	#1%
	\par%
}

\newcommand\informationheading[1]%
{%
	\vspace*{12pt}%
	\fontsize{8pt}{10pt}\selectfont\textbf{#1}%
	\par%
	\vspace*{4pt}%
}

\newcounter{infocount}
\newcommand\setinformation[3]%
{%
	\csdef{information#1}{\informationentry{#2}{#3}}%
}
\newcommand\addinformation[2]%
{%
	\stepcounter{infocount}%
	\csdef{information\theinfocount}{\informationentry{#1}{#2}}%
}
\newcommand\addinformationsingle[1]%
{%
	\stepcounter{infocount}%
	\csdef{information\theinfocount}{\informationentrysingle{#1}}%
}
\newcommand\addinformationspacer[0]%
{%
	\stepcounter{infocount}%
	\csdef{information\theinfocount}{\vspace*{4pt}}%
}
\newcommand\addinformationbigspacer[0]%
{%
	\stepcounter{infocount}%
	\csdef{information\theinfocount}{\vspace*{8pt}}%
}
\newcommand\addinformationheading[1]%
{%
	\stepcounter{infocount}%
	\csdef{information\theinfocount}{\informationheading{#1}}%
}
\newcommand\getinformation[1]%
{%
	\csuse{information#1}%
}

\newcommand{\window}[0]
{%
	%\colorbox{black!5}%
	{%
	\begin{minipage}[t][45mm]{85mm}%
		\linespread{1}%
		\hspace{5mm}%
		\begin{minipage}[t][5mm][b]{\textwidth}%
			\color{black!50}%
			\fontsize{8pt}{8pt}\selectfont\textbf{\@sendername}\@bullet\@senderstreet\@bullet\@sendertown%
		\end{minipage}%

		\nointerlineskip%
		\hspace{5mm}%
		\begin{minipage}[t][40mm][c]{\textwidth-5mm}%
			\fontsize{10pt}{12pt}\selectfont%
			\@receivernotesthree\par%
			\@receivernotestwo\par%
			\@receivernotesone\par%
			\textbf{\@receivercompany}\par%
			\@receivertitle\par%
			\@receivername\par%
			\@receiverstreet\par%
			\@receivertown\par%
			\MakeUppercase{\@receivercountry}%
		\end{minipage}%
	\end{minipage}%
	}%
}

\newcounter{colnum}%

\newcommand{\informationblock}[0]
{%
	%\colorbox{black!5}%
	{%
	\begin{minipage}[t][][t]{35mm}%
		\vspace*{-12pt}%
		\color{black!50}%
		\linespread{1}%
		\setcounter{colnum}{0}%
		\whileboolexpr%
			{ test {\ifnumcomp{\value{colnum}}{<}{\theinfocount}} }%
			{\stepcounter{colnum}\getinformation{\thecolnum}}%
	\end{minipage}%
	}%
}

\newcounter{invoicepos}

\newcommand{\invoice}[1]
{%
	%\colorbox{black!5}%
	{%
		\tabulinesep=6pt%
		\taburulecolor{black!20}%
		\begin{longtabu}{p{1cm}p{1.5cm}X>{\hfill}p{2cm}>{\hfill}p{2cm}>{\hfill}p{2.5cm}}%
			\bfseries Pos. & \bfseries Menge & \bfseries Bezeichnung & \bfseries Einzelpreis & \bfseries MwSt. & \bfseries Netto\\\myrule{1.5pt}%
			#1%
			\myrule{1.5pt}%
		\end{longtabu}%
	}%
}

\newcommand*{\ov}[1]%
{%
	$\m@th\overline{\mbox{#1}\raisebox{5mm}{}}$%
}

\newcommand{\myrule}[1]
{%
	\tabucline[#1]{-}%
}

\newcommand{\invoiceitem}[5]
{%
  \stepcounter{invoicepos}%
  \theinvoicepos & #1 & #2 & \formateuro{#3} & \SI{#4}{\percent} & \formateuro{#5}\\\myrule{0.4pt}%
}%

\newcommand{\invoicetotalline}[2]
{%
	\multicolumn{5}{l}{#1} & \formateuro{#2}\\%
}%

\newcommand{\invoicetotalboldline}[2]
{%
	\multicolumn{5}{l}{\bfseries #1} & \textbf{\formateuro{#2}}\\%
}%

\newcommand{\invoicetotal}[2]
{%
	\hfill #1 & \formateuro{#2}\\%
}%

\newcommand{\invoicetotalbold}[2]
{%
	\hfill\bfseries #1 & \textbf{\SI{#2}{\euro}}\\%
}%

\AddToShipoutPicture%
{%
	{%
		\unitlength=1mm%
		\color{black!20}%
		\linethickness{0.4pt}%
		\put(0, 87)%
		{%
			\line(1, 0){7.5}%
		}%
		\put(0, 192)%
		{%
			\line(1, 0){7.5}%
		}%
		\put(0, 148.5)%
		{%
			\line(1, 0){10}%
		}%
	}%
}

\AddToShipoutPicture%
{%
	\unitlength=1mm%
	\put(0, 252)%
	{%
		\makebox(210, 45)[lt]{\@header}%
	}%
	\put(0, 0)%
	{%
		\makebox(210, 35.77)[lt]{\@footer}%
	}%
	\ifnum\getpagerefnumber{LastPage}>1%
	{%
		\put(165, 30.77)%
		{%
			\makebox(40, 10)[lb]{\fontsize{10pt}{10pt}\selectfont{Seite~\thepage~von~\pageref{LastPage}}}%
		}%
	}%
	\fi%
}

\AddToShipoutPicture*%
{%
	\unitlength=1mm%
	\put(20, 252)%
	{%
		\vbox{\window}%
	}%
	\put(145, 252)%
	{%
		\vbox{\informationblock}%
	}%
	\ifnum\@showcorners=1%
	{%
		\color{black!20}%
		\put(20, 207)%
		{%
			\line(0, 1){2}%
			\line(1, 0){2}%
		}%
		\put(105, 207)%
		{%
			\line(0, 1){2}%
			\line(-1, 0){2}%
		}%
		\put(105, 252)%
		{%
			\line(0, -1){2}%
			\line(-1, 0){2}%
		}%
		\put(20, 252)%
		{%
			\line(0, -1){2}%
			\line(1, 0){2}%
		}%
	}%
	\fi%
}

\newcommand{\heading}[1]
{%
	{\headingseries\fontsize{11pt}{11pt}\selectfont #1}%
	\par%
	\vspace*{24pt}%
}

\newcommand{\salutation}[1]
{%
	#1%
	\par%
	\vspace*{12pt}%
}

\newcommand{\valediction}[1]
{%
	\vspace*{12pt}%
	#1%
	\par%
	\vspace*{24pt}%
}

\newcommand{\signature}[1]
{%
	#1%
}

\AtBeginDocument%
{%
	\vspace*{60mm}
	\vspace*{-12pt}
	\heading{\@subject}%
}

\makeatother

\linespread{1.25}
\tabcolsep=0pt
\parindent=0pt
\parsep=0pt
\parskip=12pt
\topskip=0pt
\abovedisplayskip=0pt
\belowdisplayskip=0pt
\fboxrule=0pt
\fboxsep=0pt
