* Construct immigration shock

global base_dir "C:\Users\churn_5stexhd\Documents\UCSD\Projects\immigration_search_rationing"
global code_dir "${base_dir}/code"
global raw_dir "${base_dir}/rawdata"
global clean_dir "${base_dir}/cleandata"


use "${clean_dir}/immigration_modern.dta", clear
merge m:1 statefip using "${clean_dir}/census_division.dta", nogenerate
merge m:1 statefip using "${clean_dir}/euro_immigration_modern.dta", nogenerate
merge m:1 census_division country_code using "${clean_dir}/noneuro_immigration_modern.dta", nogenerate
merge m:1 statefip country_code using "${clean_dir}/ancestry_pred.dta", nogenerate


* Generate modern immigration pattern predictor
forvalues y = 2005(1)2021 {
	generate I`y' = ancestry_hat`y'*immig_outside`y'*euro_immig_share`y'
	replace I`y' = 0 if immig_outside`y' == .
}

* Regress
generate immig_hat = .
destring census_division, replace

forvalues y = 2005(1)2021 {
	reghdfe immig I* if yrimmig == `y', absorb(census_division#country_code continent#statefip yrimmig, savefe) 
	predict immig_pred
	replace immig_hat = immig_pred if yrimmig == `y'
	drop immig_pred
}

* Sum across origins to get total predicted immigration
gcollapse (sum) immig immig_hat, by(statefip yrimmig)

* Save
rename statefip state_fips
rename yrimmig year
save "${clean_dir}/immigration_pred.dta", replace

* Scatterplot of predicted vs actual immigration counts
twoway (scatter immig_hat immig) if immig < 200000, ///
xtitle("Actual immigration", size(medlarge) height(5)) ytitle("Instrumented immigration", size(medlarge) height(5)) ///
graphregion(color(white)) plotregion(fcolor(white)) bgcolor(white) ///
legend(off)
graph export "${base_dir}/iv_performance.png",  replace


