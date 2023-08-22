* Construct immigration shock

global base_dir "C:\Users\churn_5stexhd\Documents\UCSD\Projects\immigration_search_rationing"
global code_dir "${base_dir}/code"
global raw_dir "${base_dir}/rawdata"
global clean_dir "${base_dir}/cleandata"

use "${clean_dir}/ancestry.dta", clear
merge m:1 statefip using "${clean_dir}/census_division.dta", nogenerate


* Add historical immigration
rename ancestry_country_code country_code
merge m:1 statefip using "${clean_dir}/euro_immigration.dta", nogenerate
merge m:1 census_division country_code using "${clean_dir}/noneuro_immigration.dta", nogenerate

* Generate historical immigration pattern predictor
forvalues y = 1810(10)2020 {
	generate I`y' = immig_outside`y'*euro_immig_share`y'
	replace I`y' = 0 if immig_outside`y' == .
}

* Regress
generate ancestry_hat = .
destring census_division, replace

forvalues y = 2005(1)2009 {
	reghdfe ancestry_pop I18* I19* if year == `y', absorb(country_code#census_division continent#statefip, savefe) 
	predict ancestry_pred
	replace ancestry_hat = ancestry_pred if year == `y'
	drop ancestry_pred
}


forvalues y = 2010(1)2019 {
	reghdfe ancestry_pop I18* I19* I2000 if year == `y', absorb(census_division#country_code continent#statefip, savefe) 
	predict ancestry_pred
	replace ancestry_hat = ancestry_pred if year == `y'
	drop ancestry_pred
}

forvalues y = 2020(1)2021 {
	reghdfe ancestry_pop I18* I19* I2000 I2010 if year == `y', absorb(census_division#country_code continent#statefip, savefe) 
	predict ancestry_pred
	replace ancestry_hat = ancestry_pred if year == `y'
	drop ancestry_pred
}

* Reshape wide for regression
keep statefip year country_code ancestry_hat
drop if year == .
reshape wide ancestry_hat, i(statefip country_code) j(year)

save "${clean_dir}/ancestry_pred.dta", replace

