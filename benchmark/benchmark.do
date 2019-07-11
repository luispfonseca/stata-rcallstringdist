clear
set seed 2312
set obs 1000000
gen random_string1 = char(runiformint(65,90)) + ///
    string(runiformint(0,9)) + ///
    char(runiformint(65,90)) + ///
    char(runiformint(65,90)) + ///
    string(runiformint(0,9)) + ///
    char(runiformint(65,90))
gduplicates drop
gen long obsnum = _n
save list1, replace

clear
set seed 2312
set obs 10
gen random_string2 = char(runiformint(65,90)) + ///
    string(runiformint(0,9)) + ///
    char(runiformint(65,90)) + ///
    char(runiformint(65,90)) + ///
    string(runiformint(0,9)) + ///
    char(runiformint(65,90))
gduplicates drop
gen long  obsnum = _n
save list2, replace


** matrix benchmark
use list1, clear
merge 1:1 obsnum using list2, nogen

keep if _n <= 5000

timer clear

preserve
cap program drop rcallstringdist
qui do rcallstringdist_v0.2.2.ado
timeit 1: rcallstringdist random_string1 random_string2, matrix

restore
cap program drop rcallstringdist
qui do rcallstringdist_new.ado
timeit 2: rcallstringdist random_string1 random_string2, matrix


timer list


** non-matrix benchmark
use list1, clear
gen random = runiform()
sort random
drop obsnum random
gen long obsnum = _n
rename random_string1 random_string2

merge 1:1 obsnum using list1, nogen

keep if _n <= 500000

timer clear

preserve
cap program drop rcallstringdist
qui do rcallstringdist_v0.2.1.ado
timeit 1: rcallstringdist random_string1 random_string2

restore
preserve
cap program drop rcallstringdist
qui do rcallstringdist_v0.2.2.ado
timeit 2: rcallstringdist random_string1 random_string2

restore
cap program drop rcallstringdist
qui do rcallstringdist_v0.2.3.ado
timeit 3: rcallstringdist random_string1 random_string2

timer list
