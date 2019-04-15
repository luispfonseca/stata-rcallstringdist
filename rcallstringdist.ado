*! version 0.1.0 15apr2019 Luís Fonseca, https://github.com/luispfonseca
*! -rcallstringdist- Call R's stringdist package from Stata using rcall

program define rcallstringdist
	version 14
	
	syntax varlist(min=2 max=2 string), [Method(string) usebytes Weight(numlist max=4 min=4 <=1) q(integer -999) p(numlist min=1 max=1 >=0 <=0.25) bt(numlist max=1 min=1) nthread(string)]


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

	* options
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

	if "`nthread'" == "" {
		local nthread_opt = ""
	}
	else {
		local nthread_opt = ", nthread = `nthread'"
	}

	* store dataset to later merge, or restore if error
	tempfile origdata
	qui save "`origdata'", replace

	* prepare list of unique names to send; use gduplicates if possible
	di as result "Preparing data to send to R"
	tokenize "`varlist'"
	keep `1' `2'
	cap which gduplicates
	if !c(rc) {
		local g "g"
	}
	qui `g'duplicates drop

	qui export delimited _Rdatarcallstrdist_in.csv, replace

	* call R
	di as result "Calling R..."
	cap noi rcall vanilla: ///
	library(stringdist); ///
	print(paste0("Using stringdist package version: ", packageVersion("stringdist"))); ///
	data <- read.csv("_Rdatarcallstrdist_in.csv", fileEncoding = "utf8", na.strings = ""); ///
	data\$`generate' <- stringdist(data\$`1',data\$`2', method = '`method'', useBytes = `usebytes_opt', weight = c(d = `d_opt', i = `i_opt', s = `s_opt', t = `t_opt'), q = `q', p = `p', bt = `bt' `nthread_opt'); ///
	write.csv(data, file= "_Rdatarcallstrdist_out.csv", row.names=FALSE, fileEncoding="utf8", na = "")
	
	if c(rc) {
		di as error "Error when calling R. Check the error message above"
		di as error "Restoring original data"
		use "`origdata'", clear
		cap erase "`origdata'"
		error 
	}
	if "`debug'" == "" {
		cap erase _Rdatarcallstrdist_in.csv
	}

	* import the csv (moved away from st.load() due to issue #1 with encodings and accents)
	capture confirm file _Rdatarcallstrdist_out.csv
	if c(rc) {
		di as error "Restoring original data because file with the converted data was not found. Report to https://github.com/luispfonseca/stata-rcallstringdist/issues"
		use "`origdata'", clear
		cap erase "`origdata'"
		error 601
	}
	qui import delimited _Rdatarcallstrdist_out.csv, clear encoding("utf-8") varnames(1) case(preserve)
	if "`debug'" == "" {
		cap erase _Rdatarcallstrdist_out.csv
	}

	* store in dta file
	qui	save _Rdatarcallstrdist_instata, replace

	* merge results
	di as result "Merging the data"
	use "`origdata'", clear

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
		use "`origdata'", clear
		cap erase "`origdata'"
		error 9
	}

	drop _merge

	* restore original sort when calling merge
	sort `numobs'
	cap erase "`origdata'"

end
