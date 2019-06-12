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
net install github, from("https://haghish.github.io/github/") replace
github install luispfonseca/stata-rcallstringdist
```
3. The Stata package requires an R package, that is specified in [_dependency.do_](https://github.com/haghish/stata-rcallstringdist/blob/master/dependency.do) file. This file is executed automatically after installing `rcallstringdist` package. 

### Dependencies
For this command to work, you need R, an R package named [`stringdist`](https://github.com/markvanderloo/stringdist), and a Stata package named [`rcall`](https://github.com/haghish/rcall) that enables you to use the R package within Stata. 
- The command `rowsort` is needed when the `sortwords` option is called. 
- Commands from [`gtools`](https://github.com/mcaceresb/stata-gtools) by Mauricio Caceres Bravo are used to speed up the command when available. Follow the instructions in their pages to install them, especially if you are dealing with large datasets with repeated strings.

If R is installed on your machine, these dependencies will be automatically installed! See the [_dependency.do_](https://github.com/haghish/stata-rcallstringdist/blob/master/dependency.do) file. __make sure R is installed on your machine before you attempt to install these packages on Stata__. 




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
