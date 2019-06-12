program drop rcallstringdist
qui do rcallstringdist.ado

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
rcallstringdist nameA nameB, matrix

* Comparing one list of strings with itself, all possible combinations
*** if only one variable is passed, compare all pairs of strings within
*** we have 5 unique strings, 5x4/2=10 combinations
use example_dataset, clear
rcallstringdist nameA, matrix
*** to keep all permutations (5x4=20), we can use the duplicates option
use example_dataset, clear
rcallstringdist nameA, matrix duplicates
