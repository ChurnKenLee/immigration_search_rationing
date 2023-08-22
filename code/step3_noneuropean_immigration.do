* Construct immigration from non-European countries

global base_dir "C:\Users\churn_5stexhd\Documents\UCSD\Projects\immigration_search_rationing"
global code_dir "${base_dir}/code"
global raw_dir "${base_dir}/rawdata"
global clean_dir "${base_dir}/cleandata"

********************************************************************************
* Non-European immigration
********************************************************************************

* Obtain Census divisions
import excel "${raw_dir}/state-geocodes-v2019.xlsx", cellrange(A6) firstrow clear
keep StateFIPS Division
rename StateFIPS statefip
rename Division census_division
destring statefip, replace
drop if statefip == 0
tempfile census_division
save "${clean_dir}/census_division.dta", replace

* Add Census division to immigration data
use "${clean_dir}/ipums_usa_foreign_born.dta", clear
merge m:1 statefip using "${clean_dir}/census_division.dta", nogenerate

* We only want non-European immigration
drop if inrange(bpl, 400, 499)

* Sum immigration by Census divisions
generate immig = 1
gcollapse (sum) immig [pw = perwt], by(census_division yrimmig_bucket bpl)
drop if census_division == ""
drop if yrimmig_bucket == .

decode bpl, generate(bpl_country)
replace bpl_country = "Australia" if bpl_country == "Australia and New Zealand"
replace bpl_country = "Israel" if bpl_country == "Israel/Palestine"
replace bpl_country = "Yemen" if bpl_country == "Yemen Arab Republic (North)"
replace bpl_country = "Yemen" if bpl_country == "Yemen, PDR (South)"

* Decipher countries if possible
kountry bpl_country, from(other) marker stuck
keep if MARKER == 1
drop MARKER

rename _ISO3N_ country_code

keep census_division yrimmig_bucket country_code immig


* Calculate immigration from country outside of census divisions
preserve
gcollapse (sum) immig, by(yrimmig_bucket country_code)
rename immig immig_total
tempfile immig_total
save `immig_total'
restore

merge m:1 yrimmig_bucket country_code using `immig_total', nogenerate
generate immig_outside = immig_total - immig

* Reshape into wide for running regressions
keep census_division yrimmig_bucket country_code immig_outside
reshape wide immig_outside, i(census_division country_code) j(yrimmig_bucket)

save "${clean_dir}/noneuro_immigration.dta", replace



