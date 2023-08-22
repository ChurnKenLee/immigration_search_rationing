* Construct immigration shock

global base_dir "C:\Users\churn_5stexhd\Documents\UCSD\Projects\immigration_search_rationing"
global code_dir "${base_dir}/code"
global raw_dir "${base_dir}/rawdata"
global clean_dir "${base_dir}/cleandata"

********************************************************************************
* Ancestry
********************************************************************************

* Load IPUMS data
use "${raw_dir}/ipums/ipums_usa.dta", clear

* Keep only modern observations
keep if year > 2000

* Collapse by reported ancestry
generate pop = 1
gcollapse (sum) pop [pw=perwt], by(statefip year ancestr1)

* Add country of ancestry
merge m:1 ancestr1 using "${raw_dir}/AncestryCountryMatrix.dta", nogenerate

* Calculate ancestry counts within each state
vl create country_vars = (country_*)
foreach c of global country_vars {
	replace `c' = `c'*pop
}
gcollapse (sum) country_*, by(statefip year)

* Reshape into long and save
drop if statefip == .
drop if year == .
keep statefip year country_*
greshape long country_, i(statefip year) j(ancestry_country_code)
rename country_ ancestry_pop

* Add continent information
kountry ancestry_country_code, from(iso3n) geo(un)
encode GEO, generate(continent)
drop GEO

save "${clean_dir}/ancestry.dta", replace
