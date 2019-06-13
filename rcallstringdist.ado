*! version 0.2.3 13jun2019 Luís Fonseca, https://github.com/luispfonseca
*! -rcallstringdist- Call R's stringdist package from Stata using rcall

program define rcallstringdist
	version 14

	syntax varlist(min=1 max=2 string), [Method(string) usebytes Weight(numlist max=4 min=4 <=1) q(integer -999) p(numlist min=1 max=1 >=0 <=0.25) bt(numlist max=1 min=1) nthread(integer -999) debug MATrix DUPLicates GENerate(string) SORTWords]

	* parse number of variables to distinguish the two matrix cases: crossing one variable with itself, or one variable with another
	local numvars: word count `varlist'
	if "`matrix'" == "" & "`numvars'" == "1" {
		di as error "You only passed one variable but did not specify the matrix option."
		error 198
	}

	* avoid naming conflicts
	if "`generate'" == "" {
		local generate "strdist"
	}
	capture confirm new variable `generate'
	if c(rc) {
		di as error "You already have a variable named `generate'. Please rename it or provide a different name to option gen(varname)"
		error 198
	}

	* confirm that rcall is installed only after all errors and conflicts checked
	cap which rcall
	if c(rc) {
		di as error "The package Rcall is required for this package to work. Follow the instructions in https://github.com/haghish/rcall"
		di as error "The following commands should work:"
		di as error `"net install github, from("https://haghish.github.io/github/") replace"'
		di as error "gitget rcall"
		error 9
	}
	else { // additional checks of dependencies
		rcall_check stringdist>=0.9.5.1, r(2.15.3) rcall(1.3.3)
		// 0.9.5.1 is current version of stringdist. have not tested earlier versions
		// 2.15.3 is what stringdist authors specify as the R version required
		// 1.3.3 is the current version of rcall. have not tested earlier versions
	}

	* confirm commands used for sortwords are installed
	if "`sortwords'" != "" {
		cap which rowsort
		if c(rc) {
			di as error "You need to install rowsort for the sortwords option. There are two rowsort packages available, and only one allows the use of strings. To install that one, run {bf:net install pr0046.pkg}"
			error
		}
	}

	* options and defaults to pass to stringdist in R
	if "`method'" == "" {
		local method = "osa"
	}

	if "`method'" == "qgram" | "`method'" == "jaccard" | "`method'" == "cosine" {
		if `q' < 0 {
			di as error "Option q for the size of the q-gram must be invoked for methods qgram, jaccard or cosine. It must be a nonnegative integer."
			error
		}
	}
	else {
		if `q' != -999 {
			di as error "Ignoring your choice for q, as it does not apply to the method you chose."
		}
		local q 0
	}

	if "`method'" == "jw" {
		if "`p'" == "" {
			local p = 0
		}
		if "`bt'" == "" {
			local bt = 0
		}
	}
	else {
		if "`p'" != "" {
			di as error "Ignoring your choice for p, as it does not apply to the method you chose."
			local p 0
		}
		if "`bt'" != "" {
			di as error "Ignoring your choice for bt, as it does not apply to the method you chose."
			local bt 0
		}
	}

    if "`weight'" == "" {
		local d_opt = 1
		local i_opt = 1
		local s_opt = 1
		local t_opt = 1
    }
    else {
		tokenize "`weight'"
		local d_opt = `1'
		mac shift
		local i_opt = `1'
		mac shift
		local s_opt = `1'
		mac shift
		local t_opt = `1'
	}


	if "`usebytes'" == "" {
		local usebytes_opt = "FALSE"
	}
	else {
		local usebytes_opt = "TRUE"
	}

	if `nthread' == -999 {
		local nthread_opt = ""
	}
	else {
		local nthread_opt = ", nthread = `nthread'"
	}

	if "`duplicates'" != "" & ("`matrix'" == "" | "`numvars'" == "2") {
		di as error "Ignoring the duplicates option, as it applies only in the matrix method when 1 variable is passed"
	}


	* prepare list of unique names to send; use gduplicates if possible
	tokenize "`varlist'"
	if "`matrix'" != "" & "`numvars'" == "1" {
		local useNames_opt = `", useNames = c("none")"'
		local 2 = "`1'"
		* qui use "`origdata'", clear // not needed if no changes introduced after saving
	}
	di as result "Preparing data to send to R"

	cap which gtools
	if !c(rc) {
		local g "g"
		local hash "hash"
	}
	qui `g'duplicates drop

	* sort words inside each string
	if "`sortwords'" != "" {
		tokenize "`varlist'"
		forvalues k = 1/`numvars' {
			qui split ``k'', g(__stringsplit1_)
			unab x : __stringsplit1_*
			local numwords: word count `x'
			cap rowsort __stringsplit1_*, gen(___stringsplit1_s1-___stringsplit1_s`numwords')
			if c(rc) {
				di as error "The version of rowsort you have installed does not allow the use of strings. Install a version that does by running {bf:net install pr0046}"
				error
			}
			unab x : ___stringsplit1_s*
			tempvar finalstring`k'
			egen X___finalstring`k' = concat(`x'), punct(" ")
			drop ___stringsplit1_s*  __stringsplit1_*
		}
		local 1 X___finalstring1
		local 2 X___finalstring`numvars' //need the X as R doesn't take variables starting with _
	}

	* store dataset to later merge, or restore if error
	tempfile origdata
	qui save "`origdata'", replace

	* for case of matrix separate the two variables when exporting.
	* this can save a lot of time and space when the two lists have different sizes
	* no need importing a large vector with empty strings, which will make the matrix large
	if "`matrix'" == "" {
		keep `1' `2'
		qui export delimited _Rdatarcallstrdist_in.csv, replace
	}
	else {
		keep `1'
		qui drop if mi(`1')
		qui export delimited _Rdatarcallstrdist_in_1.csv, replace
		use "`origdata'", clear
		keep `2'
		qui drop if mi(`2')
		qui export delimited _Rdatarcallstrdist_in_2.csv, replace
	}

	* call R
	di as result "Calling R..."
	if "`matrix'" == "" {
		cap noi rcall vanilla: ///
			library(stringdist); ///
			print(paste0("Using stringdist package version: ", packageVersion("stringdist"))); ///
			rcalldata <- read.csv("_Rdatarcallstrdist_in.csv", fileEncoding = "utf8", na.strings = ""); ///
			rcalldata\$`generate' <- stringdist(rcalldata\$`1',rcalldata\$`2', method = '`method'', useBytes = `usebytes_opt', weight = c(d = `d_opt', i = `i_opt', s = `s_opt', t = `t_opt'), q = `q', p = `p', bt = `bt' `nthread_opt'); ///
			write.csv(rcalldata, file= "_Rdatarcallstrdist_out.csv", row.names=FALSE, fileEncoding="utf8", na = ""); ///
			rm(list=ls())
	}
	else { // need to separate rcall for matrix option as this one is saving the data in a slightly different way and I can't add a $ to a local macro in Stata to make the code flexbile enough for both cases
		// I get some error, likely due to rcall (as code runs fine in R): "too few quotes". but output goes through anyway. error 132
		cap noi rcall vanilla: ///
			library(stringdist); ///
			print(paste0("Using stringdist package version: ", packageVersion("stringdist"))); ///
			rcalldata1 <- read.csv("_Rdatarcallstrdist_in_1.csv", fileEncoding = "utf8", na.strings = ""); ///
			rcalldata2 <- read.csv("_Rdatarcallstrdist_in_2.csv", fileEncoding = "utf8", na.strings = ""); ///
			dataout <- stringdistmatrix(rcalldata1\$`1', rcalldata2\$`2', method = '`method'', useBytes = `usebytes_opt', weight = c(d = `d_opt', i = `i_opt', s = `s_opt', t = `t_opt'), q = `q', p = `p', bt = `bt', useNames = c("none") `nthread_opt'); ///
			write.csv(c(dataout), file= "_Rdatarcallstrdist_out.csv", row.names=FALSE, fileEncoding="utf8", na = ""); ///
			rm(list=ls())
	}
	if c(rc) > 0 {
		di as error "Error when calling R. Check the error message above"
		di as error "Restoring original data"
		qui use "`origdata'", clear
		cap erase "`origdata'"
		error 
	}
	if "`debug'" == "" {
		cap erase _Rdatarcallstrdist_in.csv
		cap erase _Rdatarcallstrdist_in_1.csv
		cap erase _Rdatarcallstrdist_in_2.csv
		cap erase stata.output // due to error 132
	}

	* treat data not in the case of matrix
	if "`matrix'" == "" {
		capture confirm file _Rdatarcallstrdist_out.csv
		if c(rc) {
			di as error "Restoring original data because file with the converted data was not found. Report to https://github.com/luispfonseca/stata-rcallstringdist/issues"
			qui use "`origdata'", clear
			cap erase "`origdata'"
			error 601
		}
		qui import delimited _Rdatarcallstrdist_out.csv, clear encoding("utf-8") varnames(1) case(preserve) rowrange(1:)
		if "`debug'" == "" {
			cap erase _Rdatarcallstrdist_out.csv
		}

		* store in dta file
		qui `g'duplicates drop
		qui	save _Rdatarcallstrdist_instata, replace

		* merge results
		di as result "Merging the data"
		qui use "`origdata'", clear

		tempvar numobs
		gen `numobs' = _n
		qui merge m:1 `1' `2' using _Rdatarcallstrdist_instata, keepusing(`generate')

		if "`debug'" == "" {
			cap erase _Rdatarcallstrdist_instata.dta
		}

		* check merging occurred as expected
		cap assert _merge == 3
		if c(rc) == 9 { // more helpful message if assertion fails
			di as error "Merging of data did not work as expected. Please provide a minimal working example at https://github.com/luispfonseca/stata-rcallstrdist/issues"
			di as error "There was a problem with these entries:"
			tab `namevar' if !(_merge == 3)
			di as error "Restoring original data"
			qui use "`origdata'", clear
			cap erase "`origdata'"
			error 9
		}

		drop _merge

		* restore original sort destroyed by calling merge
		sort `numobs'
		cap erase "`origdata'"
	}
	else { // matrix option
		* import the csv (moved away from st.load() due to issues with encodings and accents (issue #1 rcallcountrycode))
		capture confirm file _Rdatarcallstrdist_out.csv
		if c(rc) {
			di as error "Restoring original data because file with the converted data was not found. Report to https://github.com/luispfonseca/stata-rcallstringdist/issues"
			qui use "`origdata'", clear
			cap erase "`origdata'"
			error 601
		}
		qui import delimited _Rdatarcallstrdist_out.csv, clear encoding("utf-8") varnames(1) case(preserve) rowrange(1:)
		if "`debug'" == "" {
			cap erase _Rdatarcallstrdist_out.csv
		}

		* merge results
		di as result "Merging the data"

		* store in dta file
		gen long obsnum = _n
		qui	save _Rdatarcallstrdist_instata, replace

		qui use "`origdata'", clear
		tokenize "`varlist'"
		if "`numvars'" == "1" {
			local 2 `1'
		}
		keep `1' `2'

		*qui `g'duplicates drop
		tempfile strings
		qui save "`strings'", replace

		keep `1'
		qui drop if mi(`1')
		rename `1' string1
		tempvar strnum1
		gen `strnum1' = _n
		tempfile cross
		qui save "`cross'", replace
		qui use "`strings'", clear
		keep `2'
		qui drop if mi(`2')
		tempvar strnum2
		gen `strnum2' = _n
		rename `2' string2
		cross using "`cross'"
		sort `strnum2' `strnum1'

		gen long obsnum = _n
		qui merge 1:1 obsnum using _Rdatarcallstrdist_instata, assert(match) nogen
		qui drop if mi(x)
		if "`debug'" == "" {
			cap erase _Rdatarcallstrdist_instata.dta
			cap erase "`cross'"
			cap erase "`strings'"

		}
		rename x `generate'
		drop obsnum

		order *1 *2 `generate'

		if "`numvars'" == "1" {
			qui drop if string1 == string2
		}

		if "`duplicates'" == "" | "`numvars'" == "2" {

			tempvar first second
			gen `first' = cond(string1 < string2, string1, string2)
			gen `second' = cond(string2 < string1, string1, string2)

			tempvar pair_id
			qui `g'egen `pair_id' = group(`first' `second')

			* keep only one string of the same pair, where string1 is the first, alphabetically
			`hash'sort `pair_id' `string1' `string2'
			tempvar pair_obs
			bysort `pair_id': gen `pair_obs' = _n
			qui drop if `pair_obs' > 1
		}

		`hash'sort `generate' string1 string2 // sorting is hard-coded to make it clear for users that, with matrix option, they should not expect the command to give him back the same order of strings they fed in, as duplicates and missing strings are dropped in the matrix option

		qui compress
	}

	cap drop X___finalstring* // in the sortwords option

end
