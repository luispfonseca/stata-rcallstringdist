# RCALLSTRINGDIST: Call R's stringdist package from Stata using rcall
**unpolished for now, but works**
- Current version: 0.2.0 16apr2019
- Contents: [`updates`](#updates) [`description`](#description) [`install`](#install) [`usage`](#usage) [`to do`](#to-do) [`author`](#author)

-----------

## Updates
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
net install rcallstringdist, from("https://raw.githubusercontent.com/luispfonseca/stata-rcallstringdist/master/")
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

Commands from [`gtools`](https://github.com/mcaceresb/stata-gtools) by Mauricio Caceres Bravo are used to speed up the command when available. Follow the instructions in their pages to install them, especially if you are dealing with large datasets with repeated strings.

## Usage
To write

## To do:
* Write helpfile

## Author
Luís Fonseca
<br>London Business School
<br>lfonseca london edu
<br>https://luispfonseca.com
