/***
Installing package dependency
=============================

The following R packages are required by rcall. rcall attempts to detect R 
Statistical Software on your system automatically and install the dependency 
R packages. If the installation fails, read the rcall help file and install 
the dependencies manually.
***/

net install pr0046.pkg
ssc install gtools
github install haghish/rcall, stable
rcall_check
rcall: install.packages("stringdist", repos="http://cran.us.r-project.org")
