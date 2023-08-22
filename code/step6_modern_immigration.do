* Construct immigration shock

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

* Keep only modern immigration
keep if yrimmig >= 2005

* Create European migration variables
generate euro_immig = 0
replace euro_immig = 1 if inrange(bpl, 400, 499)

* Total European immigration by state-year
gcollapse (sum) euro_immig [pw=perwt], by(statefip yrimmig)

* Total European immigration by year
preserve
gcollapse (sum) euro_immig, by(yrimmig)
rename euro_immig euro_immig_total
tempfile euro_total
save `euro_total'
restore

* Share of total European immigration
merge m:1 yrimmig using `euro_total', nogenerate
generate euro_immig_share = euro_immig/euro_immig_total

* Reshape into wide for running regressions
keep statefip yrimmig euro_immig_share
drop if yrimmig == .
reshape wide euro_immig_share, i(statefip) j(yrimmig)

merge m:1 statefip using "${clean_dir}/census_division.dta", nogenerate

save "${clean_dir}/euro_immigration_modern.dta", replace


********************************************************************************
* Non-European immigration
********************************************************************************
* Load IPUMS data
use "${raw_dir}/ipums/ipums_usa.dta", clear

* Construct ancestry prediction variables
* Keep only foreign born with year of immigration
keep if bpl > 99
keep if yrimmig != .

* Keep only modern immigration
keep if yrimmig >= 2005

* Add Census division to immigration data
merge m:1 statefip using "${clean_dir}/census_division.dta", nogenerate

* We only want non-European immigration
drop if inrange(bpl, 400, 499)

* Sum immigration by Census divisions
generate immig = 1
gcollapse (sum) immig [pw = perwt], by(census_division yrimmig bpl)
drop if census_division == ""
drop if yrimmig == .

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

keep census_division yrimmig country_code immig


* Calculate immigration from country outside of census divisions
preserve
gcollapse (sum) immig, by(yrimmig country_code)
rename immig immig_total
tempfile immig_total
save `immig_total'
restore

merge m:1 yrimmig country_code using `immig_total', nogenerate
generate immig_outside = immig_total - immig

* Reshape into wide for running regressions
keep census_division yrimmig country_code immig_outside
reshape wide immig_outside, i(census_division country_code) j(yrimmig)

save "${clean_dir}/noneuro_immigration_modern.dta", replace


********************************************************************************
* Modern immigration
********************************************************************************
* Load IPUMS data
use "${raw_dir}/ipums/ipums_usa.dta", clear

* Construct ancestry prediction variables
* Keep only foreign born with year of immigration
keep if bpl > 99
keep if yrimmig != .

* Keep only modern immigration
keep if yrimmig >= 2005

* We only want non-European immigration
drop if inrange(bpl, 400, 499)

* Sum immigration by state
generate immig = 1
gcollapse (sum) immig [pw = perwt], by(statefip yrimmig bpl)
drop if statefip == .
drop if yrimmig == .

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

keep statefip yrimmig country_code immig

merge m:1 statefip using "${clean_dir}/census_division.dta", nogenerate

* Add continent information
kountry country_code, from(iso3n) geo(un)
encode GEO, generate(continent)
drop GEO

save "${clean_dir}/immigration_modern.dta", replace

