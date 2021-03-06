*! version 0.3.0 11jul2019 Luís Fonseca, https://github.com/luispfonseca
*! -rcallstringdist- Call R's stringdist package from Stata using rcall

program define rcallstringdist
	version 14

	syntax varlist(min=1 max=2 string), [Method(string) usebytes Weight(numlist max=4 min=4 <=1) q(integer -999) p(numlist min=1 max=1 >=0 <=0.25) bt(numlist max=1 min=1) nthread(integer -999) debug MATrix KEEPDUPLicates GENerate(string) SORTWords ascii ignorecase whitespace PUNCTuation CLean CHECKrcall]

	* confirm that rcall is installed only after all errors and conflicts checked
	cap which rcall
	if c(rc) {
		di as error "The package Rcall is required for this package to work. Follow the instructions in https://github.com/haghish/rcall"
		di as error "The following commands should work:"
		di as error `"net install github, from("https://haghish.github.io/github/") replace"'
		di as error "gitget rcall"
		error 9
	}
	* check only if called explicitly, to save time
	if "`checkrcall'" != "" { // additional checks of dependencies
		rcall_check stringdist>=0.9.5.1 haven>=2.1.0, r(3.2) rcall(1.3.3)
		// 0.9.5.1 is current version of stringdist. have not tested earlier versions
		// 2.15.3 is what stringdist authors specify as the R version required
		// 2.1.0 is the version of haven when command was first written, seems to work
		// 3.2 is the R version required by haven as of writing
		// 1.3.3 is the current version of rcall. have not tested earlier versions
		di "rcall seems to be working fine. You should be able to run rcallstringdist without issues."
		exit
	}

	* parse rcallstringdist options
	local numvars: word count `varlist'
	if "`matrix'" == "" & "`numvars'" == "1" {
		di as error "You only passed one variable but did not specify the matrix option."
		error 198
	}

	if "`generate'" == "" {
		local generate "strdist"
	}
	cap confirm new variable `generate'
	if c(rc) {
		di as error "You already have a variable named `generate'. Please rename it or provide a different name to option gen(varname)"
		error 198
	}

	if "`keepduplicates'" != "" & ("`matrix'" != "" & "`numvars'" == "1") {
		di as error "Ignoring the keepduplicates option, as it applies only in the matrix method when 1 variable is passed"
	}

	if "`clean'" != "" {
		local ignorecase "ignorecase"
		local ascii "ascii"
		local whitespace "whitespace"
		local punctuation "punctuation"
	}

	tokenize "`varlist'"
	if "`matrix'" != "" & "`numvars'" == "1" {
		local useNames_opt = `", useNames = c("none")"'
		local 2 = "`1'"
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

	di "Preparing data to send to R"

	cap which gtools
	if !c(rc) {
		local g "g"
		local hash "hash"
	}

	* store dataset to later merge, or restore if error
	tempfile origdata
	qui save "`origdata'", replace

	* for case of matrix separate the two variables when exporting.
	* avoids importing large vector with empty strings
	if "`matrix'" == "" {
		keep `1' `2'
		qui `g'duplicates drop
		qui save _Rdatarcallstrdist_in.dta, replace
	}
	else if "`matrix'" != "" {
		keep `1'
		qui drop if mi(`1')
		qui `g'duplicates drop
		qui save _Rdatarcallstrdist_in_1.dta, replace
		if "`numvars'" == "1" {
			qui save _Rdatarcallstrdist_in_2.dta, replace
		}
		else if "`numvars'" == "2" {
			use "`origdata'", clear
			keep `2'
			qui drop if mi(`2')
			qui `g'duplicates drop
			qui save _Rdatarcallstrdist_in_2.dta, replace
		}
	}

	* call R
	di "Calling R..."

	* code is repetitive to avoid multiple calls to R, which is the main bottleneck
	if "`matrix'" == "" {
		cap noi rcall vanilla: ///
			library(stringdist); ///
			library(haven); ///
			print(paste0("Using stringdist package version: ", packageVersion("stringdist"))); ///
			rcalldata <- haven::read_dta("_Rdatarcallstrdist_in.dta"); ///
			rcalldata\$final_1 <- rcalldata\$`1'; ///
			rcalldata\$final_2 <- rcalldata\$`2'; ///
			if ("`ascii'" != "") { ; ///
				rcalldata\$final_1 <- iconv(rcalldata\$final_1, from = "UTF-8", to='ASCII//TRANSLIT'); ///
				rcalldata\$final_2 <- iconv(rcalldata\$final_2, from = "UTF-8", to='ASCII//TRANSLIT'); ///
			}; ///
			if ("`ignorecase'" != "") { ; ///
				rcalldata\$final_1 <- tolower(rcalldata\$final_1); ///
				rcalldata\$final_2 <- tolower(rcalldata\$final_2); ///
			}; ///
			if ("`punctuation'" != "") { ; ///
				rcalldata\$final_1 <- gsub('[[:punct:]]', '', rcalldata\$final_1); ///
				rcalldata\$final_2 <- gsub('[[:punct:]]', '', rcalldata\$final_2); ///
			}; ///
			if ("`whitespace'" != "") { ; ///
				rcalldata\$final_1 <- gsub("\\s+", " ", trimws(rcalldata\$final_1)); ///
				rcalldata\$final_2 <- gsub("\\s+", " ", trimws(rcalldata\$final_2)); ///
			}; ///
			if ("`sortwords'" != "") { ; ///
				rcalldata\$final_1 <- unlist(lapply(lapply(strsplit(rcalldata\$final_1, ' '), 'sort'), 'paste', collapse=' ')); ///
				rcalldata\$final_2 <- unlist(lapply(lapply(strsplit(rcalldata\$final_2, ' '), 'sort'), 'paste', collapse=' ')); ///
			}; ///
			rcalldata\$`generate' <- c(stringdist(rcalldata\$final_1, rcalldata\$final_2, method = '`method'', useBytes = `usebytes_opt', weight = c(d = `d_opt', i = `i_opt', s = `s_opt', t = `t_opt'), q = `q', p = `p', bt = `bt' `nthread_opt')); ///
			haven::write_dta(rcalldata, "_Rdatarcallstrdist_out.dta"); ///
			rm(list=ls())
	}
	else if "`matrix'" != "" { // need to separate rcall for matrix option as this one is saving the data in a slightly different way and I can't add a $ to a local macro in Stata to make the code flexbile enough for both cases
		// I get some error, likely due to rcall (as code runs fine in R): "too few quotes". but output goes through anyway. error 132
		cap noi rcall vanilla: ///
			library(stringdist); ///
			library(haven); ///
			print(paste0("Using stringdist package version: ", packageVersion("stringdist"))); ///
			rcalldata1 <- haven::read_dta("_Rdatarcallstrdist_in_1.dta"); ///
			rcalldata2 <- haven::read_dta("_Rdatarcallstrdist_in_2.dta"); ///
			rcalldata1\$final_1 <- rcalldata1\$`1'; ///
			rcalldata2\$final_2 <- rcalldata2\$`2'; ///
			if ("`ascii'" != "") { ; ///
				rcalldata1\$final_1 <- iconv(rcalldata1\$final_1, from = "UTF-8", to='ASCII//TRANSLIT'); ///
				rcalldata2\$final_2 <- iconv(rcalldata2\$final_2, from = "UTF-8", to='ASCII//TRANSLIT'); ///
			}; ///
			if ("`ignorecase'" != "") { ; ///
				rcalldata1\$final_1 <- tolower(rcalldata1\$final_1); ///
				rcalldata2\$final_2 <- tolower(rcalldata2\$final_2); ///
			}; ///
			if ("`whitespace'" != "") { ; ///
				rcalldata1\$final_1 <- gsub("\\s+", " ", trimws(rcalldata1\$final_1)); ///
				rcalldata2\$final_2 <- gsub("\\s+", " ", trimws(rcalldata2\$final_2)); ///
			}; ///
			if ("`punctuation'" != "") { ; ///
				rcalldata1\$final_1 <- gsub('[[:punct:]]', '', rcalldata1\$final_1); ///
				rcalldata2\$final_2 <- gsub('[[:punct:]]', '', rcalldata2\$final_2); ///
			}; ///
			if ("`sortwords'" != "") { ; ///
				rcalldata1\$final_1 <- unlist(lapply(lapply(strsplit(rcalldata1\$final_1, ' '), 'sort'), 'paste', collapse=' ')); ///
				rcalldata2\$final_2 <- unlist(lapply(lapply(strsplit(rcalldata2\$final_2, ' '), 'sort'), 'paste', collapse=' ')); ///
			}; ///
			rcalldata      <- expand.grid(string1 = rcalldata1\$`1'    , string2 = rcalldata2\$`2'        , stringsAsFactors = FALSE); ///
			rcalldata\$`generate' <- c(stringdistmatrix(rcalldata1\$final_1, rcalldata2\$final_2, method = '`method'', useBytes = `usebytes_opt', weight = c(d = `d_opt', i = `i_opt', s = `s_opt', t = `t_opt'), q = `q', p = `p', bt = `bt' `nthread_opt')); ///
			haven::write_dta(rcalldata, "_Rdatarcallstrdist_out.dta"); ///
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
		cap erase _Rdatarcallstrdist_in.dta
		cap erase _Rdatarcallstrdist_in_1.dta
		cap erase _Rdatarcallstrdist_in_2.dta
	}

	* merge results
	di "Importing results"

	cap confirm file _Rdatarcallstrdist_out.dta
	if c(rc) {
		di as error "Could not find R's output file. Restoring original data. Report to https://github.com/luispfonseca/stata-rcallstringdist/issues"
		qui use "`origdata'", clear
		cap erase "`origdata'"
		error 601
	}

	if "`matrix'" == "" {
		qui use "`origdata'", clear

		tempvar numobs
		gen `numobs' = _n  // to later keep sorting order

		tempvar rcallstringdist_merge
		qui merge m:1 `1' `2' using _Rdatarcallstrdist_out.dta, keepusing(`generate') gen(`rcallstringdist_merge')
		qui compress `generate'

		* check merging occurred as expected
		cap assert `rcallstringdist_merge' == 3
		if c(rc) == 9 { // more helpful message if assertion fails
			list if !(_merge == 3)
			di as error "Merging of data did not work as expected. Please provide a minimal working example at https://github.com/luispfonseca/stata-rcallstrdist/issues"
			di as error "There was a problem with the entries listed above"
			di as error "Restoring original data"
			qui use "`origdata'", clear
			cap erase "`origdata'"
			error 9
		}

		* restore original sort destroyed by calling merge
		sort `numobs'
		cap erase "`origdata'"
	}
	else if "`matrix'" != "" {

		qui use _Rdatarcallstrdist_out, clear

		* imported dataset unfortunately changes string formatting. this is a workaround
		forvalues k = 1/2 {
			tempvar length`k'
			qui gen byte length`k' = length(string`k')
			qui sum length`k'
			format string`k' %`r(max)'s
			drop length`k'
		}

		if "`numvars'" == "2" {
			tokenize `varlist'
			rename string1 `1'
			rename string2 `2'
			keep `1' `2' `generate'
			`hash'sort `generate' `1' `2' // sorting is hard-coded to make it clear for users that, with matrix option, they should not expect the command to give him back the same order of strings they fed in, as duplicates and missing strings are dropped in the matrix option
		}
		else if "`numvars'" == "1" {
			keep string1 string2 `generate'
			qui drop if string1 == string2

			* remove duplicates if keepduplicates not called and we have one variable
			if "`keepduplicates'" == "" & "`numvars'" == "1" {

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

			`hash'sort `generate' string1 string2 // see earlier comment
		}

		if "`debug'" == "" {
			cap erase _Rdatarcallstrdist_out.dta
			cap erase "`cross'"
			cap erase "`strings'"
		}

		qui compress
	}

end
