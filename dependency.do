/***
Installing package dependency
=============================

The following R packages are dependencies of rcallstringdist.
***/

github install haghish/rcall, stable
rcall_check
rcall vanilla: ///
	install.packages("stringdist", repos="http://cran.us.r-project.org"); ///
	install.packages("haven", repos="http://cran.us.r-project.org")

cap which gtools
if c(rc) {
	ssc install gtools
	gtools, upgrade
}
