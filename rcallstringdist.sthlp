{smcl}
{* *! version 0.3.0 11jul2019}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "rcallstringdist##syntax"}{...}
{viewerjumpto "Description" "rcallstringdist##description"}{...}
{viewerjumpto "Methods" "rcallstringdist##methods"}{...}
{viewerjumpto "Other R options" "rcallstringdist##ropt"}{...}
{viewerjumpto "Examples" "rcallstringdist##examples"}{...}
{title:Title}

{phang}
{bf:rcallstringdist} {hline 2} Call R's stringdist package from Stata using rcall

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{opt rcallstringdist} {it:varlist} [, {opt m:ethod}({it:method}) {opt w:eight}({it:numlist}) {opt q}({it:integer}) {opt p}({it:numlist}) {opt bt}({it:numlist})  {opt usebytes} {opt nthread}({it:integer}) {opt mat:rix} {opt dup:licates} {opt gen:erate}({it:varname}) {opt sortw:ords} {opt debug}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
Options to pass to stringdist in R:
{synopt:{opt m:ethod}}Method for distance calculation. The default is {it:osa}. See {help rcallstrindist##method:available methods}{p_end}
{synopt:{opt w:eight}}Penalty for deletion, insertion, substitution and transposition{p_end}
{synopt:{opt q}}Size of the q-gram{p_end}
{synopt:{opt p}}Penalty factor for Jaro-Winkler distance{p_end}
{synopt:{opt bt}}Winkler's boost threshold{p_end}
{synopt:{opt usebytes}}Pass {opt useBytes} option to R{p_end}
{synopt:{opt nthread}}Pass {opt nthread} argument to R{p_end}
{synopt:{opt mat:rix}}Compares all possible pairs of strings between two variables or within a single variable. {bf:Warning! This option clears your working dataset from memory}{p_end}
{synoptline}
Additional options
{synopt:{opt keepdup:licates}}Keeps both orderings of permuations ((A,B) and (B,A)) when {opt matrix} is called with 1 variable passed{p_end}
{synopt:{opt gen:erate}}Name of new variable to store string distance values{p_end}
{synopt:{opt ascii}}Converts to ascii before comparing to eliminate diacritics (e.g. é becomes e){p_end}
{synopt:{opt ignorecase}}Converts every character to lower case before comparing{p_end}
{synopt:{opt whitespace}}Removes excess whitespace before comparing{p_end}
{synopt:{opt punct:uation}}Removes punctuation before comparing{p_end}
{synopt:{opt cl:ean}}Applies the {opt ascii}, {opt ignorecase}, {opt whitespace} and {opt punctuation} options before comparing{p_end}
{synopt:{opt sortw:ords}}Sorts words alphabetically within each string before comparing{p_end}
{synopt:{opt debug}}Keeps intermediate files to help debug{p_end}
{synopt:{opt check:rcall}}Runs rcall_check to ensure rcall is working correctly and the required R packages are installed{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}This command makes use of {help rcall} to call the R package {cmd:stringdist} inside Stata.

{pstd}This command has a few dependencies. Learn more about them at the GitHub repo page at {browse "https://github.com/luispfonseca/stata-rcallstringdist"}.

{marker methods}{...}
{title:Methods}

{pstd}As of version 0.9.5.1 of stringdist (the R package), these are the available methods:

{p2colset 9 22 24 2}{...}
{p2col :{opt Method}}Description{p_end}
{synoptline}
{p2col :{opt osa}}Optimal string aligment, (restricted Damerau-Levenshtein distance){p_end}
{p2col :{opt lv}}Levenshtein distance (as in R's native adist){p_end}
{p2col :{opt dl}}Full Damerau-Levenshtein distance{p_end}
{p2col :{opt hamming}}Hamming distance (a and b must have same nr of characters){p_end}
{p2col :{opt lcs}}Longest common substring distance{p_end}
{p2col :{opt qgram}}q-gram distance{p_end}
{p2col :{opt cosine}}cosine distance between q-gram profile{p_end}
{p2col :{opt jaccard}}Jaccard distance between q-gram profile{p_end}
{p2col :{opt jw}}Jaro, or Jaro-Winker distance{p_end}
{p2col :{opt soundex}}Distance based on soundex encoding{p_end}
{p2colreset}{...}

{marker ropt}{...}
{title:Other R options}

{pstd}For more information on other arguments that can be passed to the R package stringdist, check that package's help file online ({browse "https://www.rdocumentation.org/packages/stringdist/topics/stringdist"}) or in R by running {cmd:??stringdist}.

{marker examples}{...}
{title:Examples}

* Comparing two lists of strings
clear
input str30 nameA
"Gates Bill"
"Gates, Bill"
"bill gates"
"William H. Gates III"
end

input str30 nameB
"Bill Gates"
"Bill Gates"
"Bill Gates"
"William Henry Gates III"

compress

** Comparing two variables, row by row
*** default method (osa), default arguments, default generated variable name
rcallstringdist nameA nameB
*** specific variable names
rcallstringdist nameA nameB, gen(osa)
rcallstringdist nameA nameB, method(cosine) q(3) gen(cosine)
*** sometimes it's worth sorting words within each string. 
*** the first row will now be a perfect match
rcallstringdist nameA nameB, gen(osa_sortw) sortwords
*** it can also be worth cleaning up the strings before feeding them 
****(e.g. lowercase, remove punctuation and diacritics)
gen nameAclean = lower(nameA)
gen nameBclean = lower(nameB)
rcallstringdist nameAclean nameBclean, gen(osa_clean)
rcallstringdist nameAclean nameBclean, gen(osa_clean_sortw) sortwords

** Comparing two variables, all possible combinations
*** by calling the matrix option, we can compare all possible combinations 
*** of strings from one variable with the other variable
*** be aware: this option will clear your current working dataset from memory
*** see the following example
clear
input str30 nameA
"Gates Bill"
"Gates, Bill"
"bill gates"
"William H. Gates III"
"Bill Gates"
"Bill Gates"
end

input str30 nameB
"Bill Gates"
"William Henry Gates III"
"Bill Gates"
end

compress

save example_dataset

*** each string of nameA will be compared with each string of nameB
*** nameA has 5 unique strings, while name B has 2
*** 10 pairs will be compared
rcallstringdist nameA nameB, matrix

* Comparing one list of strings with itself, all possible combinations
*** if only one variable is passed, compare all pairs of strings within
*** we have 5 unique strings, 5x4/2=10 combinations
use example_dataset, clear
rcallstringdist nameA, matrix
*** to keep all permutations (5x4=20), we can use the keepduplicates option
use example_dataset, clear
rcallstringdist nameA, matrix keepduplicates


{title:Author}

{pstd}Luís Fonseca, London Business School.

{pstd}Website: {browse "https://luispfonseca.com"}

{title:Website}

{pstd}{cmd:rcallstringdist} is maintained at {browse "https://github.com/luispfonseca/stata-rcallstringdist"}{p_end}
