# RCALLSTRINGDIST: Call R's stringdist package from Stata using rcall
**unpolished for now, but works**
- Current version: 0.2.1 24apr2019
- Contents: [`updates`](#updates) [`description`](#description) [`install`](#install) [`usage`](#usage) [`to do`](#to-do) [`author`](#author)

-----------

## Major updates
* **0.2.0 16apr2019**:
	- adds several options: matrix (for one and two variables), duplicates, and sortwords
* **0.1.0 15apr2019**:
	- first version of the command

## Description
This command uses [`rcall`](https://github.com/haghish/rcall) to call R's [`stringdist`](https://github.com/markvanderloo/stringdist). I don't know of any widely-used Stata command that can compute distance between strings for measures other than edit distance (such as `ustrdist`).

I'd like to thank the authors of both packages:
* [`stringdist`](https://github.com/markvanderloo/stringdist) was written by [Mark van der Loo](https://github.com/markvanderloo), [Jan van der Laan](https://github.com/djvanderlaan), [R Core Team](https://www.r-project.org/contributors.html), [Nick Logan](https://github.com/ugexe), and [Chris Muir](https://github.com/ChrisMuir).
* [`rcall`](https://github.com/haghish) was written by [E. F. Haghish](http://www.haghish.com/)

## Install

1. Install R first (see below how)
2. Install this package:
```
cap ado uninstall rcallstringdist
local github "https://raw.githubusercontent.com"
net install rcallstringdist, from(`github'/luispfonseca/stata-rcallstringdist/master/)
```
3. Make sure you install all the dependencies

### Dependencies
For this command to work, you need the following:

#### R
You need to have R installed. You can download RStudio [here](https://www.rstudio.com/products/rstudio/download/), which will install R on your computer and give you a graphical interface. 

You also need to install the [`stringdist`](https://github.com/markvanderloo/stringdist) package in R. Follow the instructions in the page:

> To install the latest release from CRAN, open an R terminal and type
> `install.packages('stringdist')`

#### Stata
Install [`rcall`](https://github.com/haghish/rcall) following the instructions in the page. The following commands currently work:
```
net install github, from("https://haghish.github.io/github/") replace
gitget rcall
```

The command `rowsort` is needed when the `sortwords` option is called. There are two rowsort packages available, and only one allows the use of strings. To install that one, run:
```
net install pr0046.pkg
```

Commands from [`gtools`](https://github.com/mcaceresb/stata-gtools) by Mauricio Caceres Bravo are used to speed up the command when available. Follow the instructions in their pages to install them, especially if you are dealing with large datasets with repeated strings.

## Usage
``` stata
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

save example_dataset, replace

*** each string of nameA will be compared with each string of nameB
*** nameA has 5 unique strings, while name B has 2
*** 10 pairs will be compared
rcallstringdist nameA nameB, matrix duplicates

* Comparing one list of strings with itself, all possible combinations
*** if only one variable is passed, compare all pairs of strings within
*** we have 5 unique strings, 5x4/2=10 combinations
use example_dataset, clear
rcallstringdist nameA, matrix
*** to keep all permutations (5x4=20), we can use the duplicates option
use example_dataset, clear
rcallstringdist nameA, matrix duplicates
```

## To do:
* suggestions?

## Author
Luís Fonseca
<br>London Business School
<br>lfonseca london edu
<br>https://luispfonseca.com
