/***
Installing package dependency
=============================

The following R packages are dependencies of rcallstringdist.
***/

github install haghish/rcall, stable
rcall_check
rcall: install.packages("stringdist", repos="http://cran.us.r-project.org")

cap which gtools
if c(rc) {
	ssc install gtools
	gtools, upgrade
}

net install pr0046, from("http://www.stata-journal.com/software/sj9-1/")
