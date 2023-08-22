* Import and combine JOLTS + LAUS data

global base_dir "C:\Users\churn_5stexhd\Documents\UCSD\Projects\immigration_search_rationing"
global code_dir "${base_dir}/code"
global raw_dir "${base_dir}/rawdata"
global clean_dir "${base_dir}/cleandata"

/*
********************************************************************************
* JOLTS
********************************************************************************
* Import JOLTS
import excel "${raw_dir}/jolts/jolts_state.xlsx", cellrange(A4) firstrow clear

* Create state and series type variable
generate state_fips = substr(SeriesID, 10, 2)

* Drop unneeded variables
drop SeriesID

* Reshape into long
foreach x of var * { 
	rename `x' UO`x'
}
rename UOstate_fips state_fips
greshape long UO, i(state_fips) j(time) string

* Save JOLTS
save "${clean_dir}/jolts.dta", replace

********************************************************************************
* LAUS
********************************************************************************
* Import LAUS
import excel "${raw_dir}/laus/laus_state.xlsx", cellrange(A4) firstrow clear

* Create state and series type variable
generate state_fips = substr(SeriesID, 6, 2)

generate measure_code = substr(SeriesID, 19, 2)
generate measure = ""
replace measure = "unemp_rate" if measure_code == "03"
replace measure = "unemp" if measure_code == "04"
replace measure = "emp" if measure_code == "05"
replace measure = "labforce" if measure_code == "06"
replace measure = "emppop_ratio" if measure_code == "07"
replace measure = "lfpr" if measure_code == "08"
drop measure_code

* Drop unneeded variables
drop SeriesID

* Reshape into long
foreach x of var * { 
	rename `x' laus`x'
}
rename lausstate_fips state_fips
rename lausmeasure measure
greshape long laus, i(state_fips measure) j(time) string

* Reshape back into wide so that each obs is a state-time
greshape wide laus, i(state_fips time) j(measure) string
renpfix laus

* Save LAUS
* Save JOLTS
save "${clean_dir}/laus.dta", replace
*/

********************************************************************************
* Merge JOLTS and LAUS
********************************************************************************
use "${clean_dir}/jolts.dta", clear
merge 1:1 state_fips time using "${clean_dir}/laus.dta", nogenerate









