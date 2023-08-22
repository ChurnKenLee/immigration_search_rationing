* Construct immigration distribution using European immigrants

global base_dir "C:\Users\churn_5stexhd\Documents\UCSD\Projects\immigration_search_rationing"
global code_dir "${base_dir}/code"
global raw_dir "${base_dir}/rawdata"
global clean_dir "${base_dir}/cleandata"


********************************************************************************
* European immigration
********************************************************************************
* Load IPUMS data
use "${raw_dir}/ipums/ipums_usa.dta", clear

* Construct ancestry prediction variables
* Keep only foreign born with year of immigration
keep if bpl > 99
keep if yrimmig != .

* Create year of immigration buckets
generate yrimmig_bucket = .
forvalues y = 1800(10)2020 {
	replace yrimmig_bucket = `y' if inrange(yrimmig, `y', `y'+9)
}

save "${clean_dir}/ipums_usa_foreign_born.dta", replace

* Create European migration variables
generate euro_immig = 0
replace euro_immig = 1 if inrange(bpl, 400, 499)

* Total European immigration by state-year
gcollapse (sum) euro_immig [pw=perwt], by(statefip yrimmig_bucket)

* Total European immigration by year
preserve
gcollapse (sum) euro_immig, by(yrimmig_bucket)
rename euro_immig euro_immig_total
tempfile euro_total
save `euro_total'
restore

* Share of total European immigration
merge m:1 yrimmig_bucket using `euro_total', nogenerate
generate euro_immig_share = euro_immig/euro_immig_total

* Reshape into wide for running regressions
keep statefip yrimmig_bucket euro_immig_share
drop if yrimmig_bucket == .
reshape wide euro_immig_share, i(statefip) j(yrimmig_bucket)

save "${clean_dir}/euro_immigration.dta", replace
*/





