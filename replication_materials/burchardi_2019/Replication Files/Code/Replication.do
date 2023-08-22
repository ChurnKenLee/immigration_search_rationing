/*
Info: This file generates tables and figures of `Migrants, Ancestors and Investments' by Konrad Burchardi, Thomas Chaney and Tarek Hassan, 
      published in The Review of Economice Studies. 
	  It creates all tables and figures both in the paper and online appendix.
*/

***************************************************************************************************************************
* List of Required Data and Do Files
***************************************************************************************************************************
/*
Files Called:
Input/Replication.dta
Input/EthnicityFirmDataForRegression_State.dta
Input/EthnicityDataForRegression_Table5A.dta
Input/EthnicityDataForRegression_Table7PanAB.dta
Input/EthnicityDataForRegression_Table7PanC.dta
Input/EthnicityDataForRegression_Table8.dta
Input/EthnicityDataForRegression_Figure2and3.dta
Input/EthnicityDataForRegression_Figure6.dta
Input/EthnicityDataForRegression_AppTable14PanA.dta
Input/EthnicityDataForRegression_AppTable14PanB.dta
Input/EthnicityDataForRegression_AppTable8.dta
Input/EthnicityDataForRegression_AppTable24.dta
Input/EthnicityDataForRegression_AppTable25.dta
Input/EMIT_DMA_Table1and8.dta
Input/EthnicityFirmDataForRegression_AppTable18B1.dta
Input/EthnicityFirmDataForRegression_AppTable18B2.dta
Input/EthnicityDataForRegression_NAICS`code'.dta (20 files, one for each NAICS code)
Input/EthnicityDataForRegression_`cutoff'.dta (4 files, one for each cutoff)
Input/EthnicityDataForRegression_AppTable18_`code'.dta (6 files, one for each sector)
Input/List-UNcountries1990.dta
Input/US-County-Population-1990.dta
Input/NAICS.dta

Files Generated:
Output/EMIT-91-PullFactorCounterfactuals.dta
Output/2010TotalAncestry.dta
Output/FirmRegByCounty.dta
Output/EMITdataset_2014fdi_EMByCountry.dta
Output/2010TotalLanguage.dta
Output/EMITdataset_2010language_EMByCountry.dta
Output/Counterfactual_China.dta
Output/Maps/XXXX.csv - multiple files
Output/PushFactorCounterfactuals.dta
Output/SectorFunnelPlot.dta
Output/BootstrapResults_`a'.dta (3 files, one for each SE)

Do Files:
Do - HDFE
*/

***************************************************************************************************************************
* Replication Code
***************************************************************************************************************************

clear all
set more off
set matsize 11000
set maxvar 32767

*** Enter the directory in which the file Replication.do is saved (e.g. D:\Users\name\Replication Files\)
global wkdir = ""
cd "${wkdir}"

***************************************************************************************************************************
* Required Programs and Do Files for Running this Code
***************************************************************************************************************************

* Do Files
qui do "Code/Do - HDFE"

*Set up program to collect statistics for output
capture program drop getcoeffs
program define getcoeffs, rclass
args number name
	return local coeff : di %5.3fc `name'_b_`number'[1,1]
	return local se : di %5.3fc sqrt(`name'_V_`number'[1,1])
	return local N : di %9.0fc ${`name'_N_`number'}
	local nofstars = ///
		(abs(`name'_b_`number'[1,1]/sqrt(`name'_V_`number'[1,1])) > invttail(${`name'_df_`number'},0.1/2)) + ///
		(abs(`name'_b_`number'[1,1]/sqrt(`name'_V_`number'[1,1])) > invttail(${`name'_df_`number'},0.05/2)) + ///
		(abs(`name'_b_`number'[1,1]/sqrt(`name'_V_`number'[1,1])) > invttail(${`name'_df_`number'},0.01/2))
	if `nofstars' == 1 {
		return local stars = "*"
	}
	if `nofstars' == 2 {
		return local stars = "**"
	}
	if `nofstars' == 3 {
		return local stars = "***"
	}
	if `nofstars' == 0 {
		return local stars = ""
	}
end

*Program to add stars
capture program drop getstars
program define getstars, rclass
args coeff se df name
	local nofstars = ///
		(abs(`coeff'/`se') > invttail(`df',0.1/2)) + ///
		(abs(`coeff'/`se') > invttail(`df',0.05/2)) + ///
		(abs(`coeff'/`se') > invttail(`df',0.01/2))
	if `nofstars' == 1 {
		return local stars_`name' = "*"
	}
	if `nofstars' == 2 {
		return local stars_`name' = "**"
	}
	if `nofstars' == 3 {
		return local stars_`name' = "***"
	}
	if `nofstars' == 0 {
		return local stars_`name' = ""
	}
end

*****************************************************************************************************************
*****************************************************************************************************************
************************************ TABLES START ************************************************************
*****************************************************************************************************************
*****************************************************************************************************************

***************************************************************************************************************************
* Table 1: Summary Statistics 
***************************************************************************************************************************
*-----------------------------------*
* Summary Statistics Table, Panel A *
*-----------------------------------*
cd "${wkdir}"
use "Input/Replication.dta", clear
// Generate quintiles
qui xtile quintile = ancestry_2010 if ancestry_2010 > 0, n(5)
sort state_county_code_1990 country_code1990

// Reduce the scale of employees by 1000
replace subsidiarynumberemployees = subsidiarynumberemployees / 1000
replace ussubsidiary_numberofemployees = ussubsidiary_numberofemployees / 1000

// Assign meaningful labels
label var ancestry_2010 "Ancestry 2010 (in thousands)"
label var cum_immigrants_2010 "Foreign-born 2010 (in thousands)"
label var immigrants_2000 "Immigrants between 1990-2000 (in thousands)"
label var immigrants_2010 "Immigrants between 2000-2010 (in thousands)"
label var Dist "Geographic Distance (km)"
label var Distance_lat "Latitude Difference (degree)"
label var country_dummy "FDI Dummy"
label var fdi_total "\# of FDI Relationships"
label var subsidiarycount "\# of Subsidiaries in Origin"
label var usparent_firmcount "\# of Parents in Destination" 
label var subsidiarynumberemployees "\# of Workers Employed at Subsidiary in Origin (in thousands)"
label var ussubsidiary_firmcount "\# of Subsidiaries in Destination"
label var shareholdercount "\# of Parents in Origin" 
label var ussubsidiary_numberofemployees "\# of Workers Employed at Subsidiary in Destination (in thousands)"

capture program drop sumStatA
program define sumStatA
	capture log close
	capture erase "Output/Table1A.prn"
	quietly log using "Output/Table1A.prn", text
	foreach x in country_dummy ancestry_2010 immigrants_2000 immigrants_2010 ///
	cum_immigrants_2010 Dist Distance_lat fdi_total subsidiarycount usparent_firmcount ///
	subsidiarynumberemployees ussubsidiary_firmcount shareholdercount ussubsidiary_numberofemployees ///
	information_index {

		*Select correct format
		if "`x'" == "Dist" {
			local f = "%9.3fc"
		}
		else {
			local f = "%5.3f"
		}
		
		*Special case; need to take DMA-country data
		if "`x'" == "information_index" {
			preserve
				cd "${wkdir}"
				use "Input/EMIT_DMA_Table1and8.dta", clear

				la var index_std "Information Demand Index (standardized)*"

				qui xtile quintile = ancestry2010 if ancestry2010 > 0, n(5)

				// Column One
				qui sum index_std
				local mean1 : di `f' r(mean)
				local sd1 : di `f' r(sd)
				local N1 : di %10.0fc r(N)
				// Column Two
				qui sum index_std if ancestry2010 > 0 & ancestry2010 != .
				local mean2 : di `f' r(mean)
				local sd2 : di `f' r(sd)
				local N2 : di %10.0fc r(N)
				// Column Three
				qui sum index_std if quintile == 1
				local mean3 : di `f' r(mean)
				local sd3 : di `f' r(sd)
				local N3 : di %10.0fc r(N)
				// Column Four
				qui sum index_std if quintile == 5
				local mean4 : di `f' r(mean)
				local sd4 : di `f' r(sd)
				local N4 : di %10.0fc r(N)
				display as text `"`: var label index_std'"' "&" /*
				*/ as result /*
				*/ "`mean1'" "&" /*
				*/ "`mean2'" "&" /*
				*/ "`mean3'" "&" /*
				*/ "`mean4'" "\\" 
				display as result /*
				*/ "& (" "`sd1'" ")" /*
				*/ "& (" "`sd2'" ")" /*
				*/ "& (" "`sd3'" ")" /*
				*/ "& (" "`sd4'" ") \\"
			restore
		}
		else {
			// Column One
			qui sum `x'
			local mean1 : di `f' r(mean)
			local sd1 : di `f' r(sd)
			local N1 : di %10.0fc r(N)
			// Column Two
			qui sum `x' if ancestry_2010 > 0 & ancestry_2010 != .
			local mean2 : di `f' r(mean)
			local sd2 : di `f' r(sd)
			local N2 : di %10.0fc r(N)
			// Column Three
			qui sum `x' if quintile == 1
			local mean3 : di `f' r(mean)
			local sd3 : di `f' r(sd)
			local N3 : di %10.0fc r(N)
			// Column Four
			qui sum `x' if quintile == 5
			local mean4 : di `f' r(mean)
			local sd4 : di `f' r(sd)
			local N4 : di %10.0fc r(N)
			// Output to screen
			display as text `"`: var label `x''"' "&" /*
			*/ as result /*
			*/ "`mean1'" "&" /*
			*/ "`mean2'" "&" /*
			*/ "`mean3'" "&" /*
			*/ "`mean4'" "\\" 
			display as result /*
			*/ "& (" "`sd1'" ")" /*
			*/ "& (" "`sd2'" ")" /*
			*/ "& (" "`sd3'" ")" /*
			*/ "& (" "`sd4'" ") \\"
		}
	}
	display as text "N" "&" /*
	*/ as result /*
	*/ "`N1'" "&" /*
	*/ "`N2'" "&" /*
	*/ "`N3'" "&" /*
	*/ "`N4'" "\\"
	qui log close
end

sumStatA

*-----------------------------------*
* Summary Statistics Table, Panel B *
*-----------------------------------*
cd "${wkdir}"
use "Input/Replication.dta", replace

sort state_county_code_1990 country_code1990
bysort country_code1990: egen total_ancestry = total(ancestry_2010)

// Collapse at country level
sort country_code1990 state_county_code_1990 
collapse (mean) total_ancestry colony fst_distance_weighted cognate_weighted lingdist_weighted_formula reldist_weighted_formula Qc gdp_2010_pc country_herfindahl country_diversity, by(country_code1990)
sort country_code1990
rename total_ancestry ancestry_2010

// Generate quintiles
qui xtile quintile = ancestry_2010 if ancestry_2010 > 0, n(5)

// Assign meaningful labels
label var colony "Colony"
label var fst_distance_weighted "Genetic Distance"
label var cognate_weighted "Cognate Distance"
label var lingdist_weighted_formula "Linguistic Distance"
label var reldist_weighted_formula "Religious Distance"
label var Qc "Judicial Quality"
label var gdp_2010_pc "2010 Per Capita GDP (in thousand dollar)"
label var country_herfindahl "2010 Country Fractinalization"
label var country_diversity "2010 Country Diversity"

// Get rid of USA !!!
drop if country_code == 840

capture program drop sumStatB

program define sumStatB
  capture log close
  capture erase "Output/Table1B.prn"
  quietly log using "Output/Table1B.prn", text
  foreach x of varlist fst_distance_weighted lingdist_weighted_formula reldist_weighted_formula Qc country_diversity {
    // Column One
    qui sum `x'
    local mean1 = round(r(mean),.001)
    local sd1   = round(r(sd),.001)
	local N1 : di %10.0fc r(N)
    // Column Two
    qui sum `x' if ancestry_2010 > 0 & ancestry_2010 != .
    local mean2 = round(r(mean),.001)
    local sd2   = round(r(sd),.001)
	local N2 : di %10.0fc r(N)
    // Column Three
    qui sum `x' if quintile == 1
    local mean3 = round(r(mean),.001)
    local sd3   = round(r(sd),.001)		
	local N3 : di %10.0fc r(N)
    // Column Four
    qui sum `x' if quintile == 5
    local mean4 = round(r(mean),.001)
    local sd4   = round(r(sd),.001)
	local N4 : di %10.0fc r(N)
    // Output to screen
    display as text `"`: var label `x''"' "&" /*
	        */ as result /*
	        */ %04.3fc `mean1' "&" /*
			*/ %04.3fc `mean2' "&" /*
			*/ %04.3fc `mean3' "&" /*
			*/ %04.3fc `mean4' "\\" 
    display as result /*
	        */ "& (" %04.3fc `sd1' ")" /*
			*/ "& (" %04.3fc `sd2' ")" /*
			*/ "& (" %04.3fc `sd3' ")" /*
			*/ "& (" %04.3fc `sd4' ") \\" 
	display as text "N" "&" /*
            */ as result /*
		    */ "`N1'" "&" /*
		    */ "`N2'" "&" /*
		    */ "`N3'" "&" /*
		    */ "`N4'" "\\"
  }
  qui log close
end

sumStatB

*-----------------------------------*
* Summary Statistics Table, Panel C *
*-----------------------------------*
cd "${wkdir}"
use "Input/Replication.dta", replace

sort state_county_code_1990 country_code1990
bysort state_county_code_1990: egen total_ancestry = total(ancestry_2010)

// Generate the share of the population who have foreign ancestry 
replace population_2010 = population_2010 / 1000
gen foreign_share = total_ancestry / population_2010 

// Generate Herfindahl index for the diversity of ancestry in the county 
gen ancestry_ratio = ancestry_2010 / total_ancestry
gen ancestry_ratio_2 = ancestry_ratio * ancestry_ratio
bysort state_county_code_1990: egen herfindahl = total(ancestry_ratio_2)
gen diversity = 1 - herfindahl
sort state_county_code_1990 country_code1990

// Reduce the scale of per capita income by 1000
replace per_capita_income = per_capita_income / 1000

// Collapse at county level
collapse (mean) total_ancestry foreign_share herfindahl diversity per_capita_income population_2010, by(state_county_code_1990)
sort state_county_code_1990
rename total_ancestry ancestry_2010

// Assign meaningful labels
label var foreign_share "2010 Share of Population with Foreign Ancestry"
label var herfindahl "2010 Herfindahl Index of Ancestries"
label var diversity "2010 Diversity of Ancestries"

// Generate quintiles
qui xtile quintile = ancestry_2010 if ancestry_2010 > 0, n(5)

capture program drop sumStatC
program define sumStatC
  capture log close
  capture erase "Output/Table1C.prn"
  quietly log using "Output/Table1C.prn", text
  foreach x of varlist foreign_share diversity /*population_2010 per_capita_income*/ {
    // Column One
    qui sum `x'
    local mean1 = round(r(mean),.001)
    local sd1   = round(r(sd),.001)
	local N1 : di %10.0fc r(N)
    // Column Two
    qui sum `x' if ancestry_2010 > 0 & ancestry_2010 != .
    local mean2 = round(r(mean),.001)
    local sd2   = round(r(sd),.001)
	local N2 : di %10.0fc r(N)
    // Column Three
    qui sum `x' if quintile == 1
    local mean3 = round(r(mean),.001)
    local sd3   = round(r(sd),.001)		
	local N3 : di %10.0fc r(N)
    // Column Four
    qui sum `x' if quintile == 5
    local mean4 = round(r(mean),.001)
    local sd4   = round(r(sd),.001)
	local N4 : di %10.0fc r(N)
    // Output to screen
    display as text `"`: var label `x''"' "&" /*
	        */ as result /*
	        */ %4.3fc `mean1' "&" /*
			*/ %4.3fc `mean2' "&" /*
			*/ %4.3fc `mean3' "&" /*
			*/ %4.3fc `mean4' "\\" 
    display as result /*
	        */ "& (" %4.3fc `sd1' ")" /*
			*/ "& (" %4.3fc `sd2' ")" /*
			*/ "& (" %4.3fc `sd3' ")" /*
			*/ "& (" %4.3fc `sd4' ") \\"
  }
  display as text "N" "&" /*
            */ as result /*
		    */ "`N1'" "&" /*
		    */ "`N2'" "&" /*
		    */ "`N3'" "&" /*
		    */ "`N4'" "\\"
  qui log close
end

sumStatC

***************************************************************************************************************************
* Table 2: First-stage: The Effect of Historical Immigration on Ancestry
***************************************************************************************************************************
cd "${wkdir}"
use "Input/Replication.dta", replace

* Generate orthogonal instruments
qui reg immi_nc_d_X_o_ndv_2  immi_nc_d_X_o_ndv_1
predict res_2, r
rename immi_nc_d_X_o_ndv_2 XXXimmi_nc_d_X_o_ndv_2
rename res_2 immi_nc_d_X_o_ndv_2

qui reg immi_nc_d_X_o_ndv_3  immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_3, r
rename immi_nc_d_X_o_ndv_3 XXXimmi_nc_d_X_o_ndv_3
rename res_3 immi_nc_d_X_o_ndv_3

qui reg immi_nc_d_X_o_ndv_4  immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_4, r
rename immi_nc_d_X_o_ndv_4 XXXimmi_nc_d_X_o_ndv_4
rename res_4 immi_nc_d_X_o_ndv_4

qui reg immi_nc_d_X_o_ndv_5  immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_5, r
rename immi_nc_d_X_o_ndv_5 XXXimmi_nc_d_X_o_ndv_5
rename res_5 immi_nc_d_X_o_ndv_5

qui reg immi_nc_d_X_o_ndv_6  immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_6, r
rename immi_nc_d_X_o_ndv_6 XXXimmi_nc_d_X_o_ndv_6
rename res_6 immi_nc_d_X_o_ndv_6

qui reg immi_nc_d_X_o_ndv_7  immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_7, r
rename immi_nc_d_X_o_ndv_7 XXXimmi_nc_d_X_o_ndv_7
rename res_7 immi_nc_d_X_o_ndv_7

qui reg immi_nc_d_X_o_ndv_8  immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_8, r
rename immi_nc_d_X_o_ndv_8 XXXimmi_nc_d_X_o_ndv_8
rename res_8 immi_nc_d_X_o_ndv_8

qui reg immi_nc_d_X_o_ndv_9  immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_9, r
rename immi_nc_d_X_o_ndv_9 XXXimmi_nc_d_X_o_ndv_9
rename res_9 immi_nc_d_X_o_ndv_9

qui reg immi_nc_d_X_o_ndv_10 immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_10, r
rename immi_nc_d_X_o_ndv_10 XXXimmi_nc_d_X_o_ndv_10
rename res_10 immi_nc_d_X_o_ndv_10

* Rename principal components
foreach time of numlist 1/5 {
  rename pcFour`time' pc_`time'
}

* Table Two Column 1
qui reg2hdfe log_ancestry_2010 ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 ///
	, id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990)
estimates store a
reghdfe country_dummy (log_ancestry_2010 = ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9) ///
	, absorb(country_code1990 state_county_code_1990) vce(cluster country_code1990) ffirst
local kp_fstat = e(rkf)
mat first = e(first)
local cd_fstat = first[4,1]
local cvalue5 = 20.53 // needs to be read off the reghdfe output manually
local cvalue10 = 11.46 // needs to be read off the reghdfe output manually
estimates restore a
qui estadd scalar kp_fstat `kp_fstat'
qui estadd scalar cd_fstat `cd_fstat'
qui estadd scalar cvalue5 `cvalue5'
qui estadd scalar cvalue10 `cvalue10'
qui estadd local fe1 "Yes"
qui estadd local fe2 "Yes"
qui estadd local dist "No"
qui estadd local lat "No"
qui estadd local pc "No"
qui estadd local fe3 "No"
qui estadd local fe4 "No"
qui estadd local pol "No"
estimates store a

* Table Two Column 2: same as 1 but add distance and latitude control
qui reg2hdfe log_ancestry_2010 ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 ///
	dist distance_lat, id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990)
estimates store b
reghdfe country_dummy dist distance_lat (log_ancestry_2010 = ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9) ///
	, absorb(country_code1990 state_county_code_1990) vce(cluster country_code1990) ffirst
local kp_fstat = e(rkf)
mat first = e(first)
local cd_fstat = first[4,1]
local cvalue5 = 20.53 // needs to be read off the reghdfe output manually
local cvalue10 = 11.46 // needs to be read off the reghdfe output manually
estimates restore b
qui estadd scalar kp_fstat `kp_fstat'
qui estadd scalar cd_fstat `cd_fstat'
qui estadd scalar cvalue5 `cvalue5'
qui estadd scalar cvalue10 `cvalue10'
qui estadd local fe1 "Yes"
qui estadd local fe2 "Yes"
qui estadd local dist "Yes"
qui estadd local lat "Yes"
qui estadd local pc "No"
qui estadd local fe3 "No"
qui estadd local fe4 "No"
qui estadd local pol "No"
estimates store b

* Table Two Column 3: same as 2 but use destination X continent FE
qui reg2hdfe log_ancestry_2010 ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 ///
	dist distance_lat, id1(country_code1990) id2(county_continent_code) cluster(country_code1990)
estimates store c
reghdfe country_dummy dist distance_lat (log_ancestry_2010 = ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9) ///
	, absorb(country_code1990 county_continent_code) vce(cluster country_code1990) ffirst
local kp_fstat = e(rkf)
mat first = e(first)
local cd_fstat = first[4,1]
local cvalue5 = 20.53 // needs to be read off the reghdfe output manually
local cvalue10 = 11.46 // needs to be read off the reghdfe output manually
estimates restore c
qui estadd scalar kp_fstat `kp_fstat'
qui estadd scalar cd_fstat `cd_fstat'
qui estadd scalar cvalue5 `cvalue5'
qui estadd scalar cvalue10 `cvalue10'
qui estadd local fe1 "Yes"
qui estadd local fe2 "Yes"
qui estadd local dist "Yes"
qui estadd local lat "Yes"
qui estadd local pc "No"
qui estadd local fe3 "Yes"
qui estadd local fe4 "No"
qui estadd local pol "No"
estimates store c

* Table Two Column 4: same as 3 but include region X country FE
qui reg2hdfe log_ancestry_2010 ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 ///
	dist distance_lat, id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store d
reghdfe country_dummy dist distance_lat (log_ancestry_2010 = ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9) ///
	, absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
local kp_fstat = e(rkf)
mat first = e(first)
local cd_fstat = first[4,1]
local cvalue5 = 20.53 // needs to be read off the reghdfe output manually
local cvalue10 = 11.46 // needs to be read off the reghdfe output manually
estimates restore d
qui estadd scalar kp_fstat `kp_fstat'
qui estadd scalar cd_fstat `cd_fstat'
qui estadd scalar cvalue5 `cvalue5'
qui estadd scalar cvalue10 `cvalue10'
qui estadd local fe1 "Yes"
qui estadd local fe2 "Yes"
qui estadd local dist "Yes"
qui estadd local lat "Yes"
qui estadd local pc "No"
qui estadd local fe3 "Yes"
qui estadd local fe4 "Yes"
qui estadd local pol "No"
estimates store d

* Table Two Column 5: same as 4, add pc's (standard specification)
qui reg2hdfe log_ancestry_2010 ///
immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 ///
pc_* dist distance_lat, id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store e
reghdfe country_dummy dist distance_lat (log_ancestry_2010 = ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 pc_*) ///
	, absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
local kp_fstat = e(rkf)
mat first = e(first)
local cd_fstat = first[4,1]
local cvalue5 = 21.18 // needs to be read off the reghdfe output manually
local cvalue10 = 11.52 // needs to be read off the reghdfe output manually
estimates restore e
qui estadd scalar kp_fstat `kp_fstat'
qui estadd scalar cd_fstat `cd_fstat'
qui estadd scalar cvalue5 `cvalue5'
qui estadd scalar cvalue10 `cvalue10'
qui estadd local fe1 "Yes"
qui estadd local fe2 "Yes"
qui estadd local dist "Yes"
qui estadd local lat "Yes"
qui estadd local pc "Yes"
qui estadd local fe3 "Yes"
qui estadd local fe4 "Yes"
qui estadd local pol "No"
estimates store e

* Table Two Column 6: same as 5 but add polynomial terms
qui reg2hdfe log_ancestry_2010 ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 ///
	pc_* dist dist2 dist3 distance_lat distance_lat2 distance_lat3, id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store f
reghdfe country_dummy dist dist2 dist3 distance_lat distance_lat2 distance_lat3 (log_ancestry_2010 = ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 pc_*) ///
	, absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
local kp_fstat = e(rkf)
mat first = e(first)
local cd_fstat = first[4,1]
local cvalue5 = 21.18 // needs to be read off the reghdfe output manually
local cvalue10 = 11.52 // needs to be read off the reghdfe output manually
estimates restore f
qui estadd scalar kp_fstat `kp_fstat'
qui estadd scalar cd_fstat `cd_fstat'
qui estadd scalar cvalue5 `cvalue5'
qui estadd scalar cvalue10 `cvalue10'
qui estadd local fe1 "Yes"
qui estadd local fe2 "Yes"
qui estadd local dist "Yes"
qui estadd local lat "Yes"
qui estadd local pc "Yes"
qui estadd local fe3 "Yes"
qui estadd local fe4 "Yes"
qui estadd local pol "Yes"
estimates store f

* Table Two Column 7: same as 5 but add 2010 immigration term
qui reg2hdfe log_ancestry_2010 ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_10 ///
	pc_* dist distance_lat, id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store g
reghdfe country_dummy dist distance_lat (log_ancestry_2010 = ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_10 pc_*) ///
	, absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
local kp_fstat = e(rkf)
mat first = e(first)
local cd_fstat = first[4,1]
local cvalue5 = 21.23 // needs to be read off the reghdfe output manually
local cvalue10 = 11.51 // needs to be read off the reghdfe output manually
estimates restore g
qui estadd scalar kp_fstat `kp_fstat'
qui estadd scalar cd_fstat `cd_fstat'
qui estadd scalar cvalue5 `cvalue5'
qui estadd scalar cvalue10 `cvalue10'
qui estadd local fe1 "Yes"
qui estadd local fe2 "Yes"
qui estadd local dist "Yes"
qui estadd local lat "Yes"
qui estadd local pc "Yes"
qui estadd local fe3 "Yes"
qui estadd local fe4 "Yes"
qui estadd local pol "No"
estimates store g

* Table Two Column 9: same as 5 but use ancestry instead of log ancestry
qui reg2hdfe ancestry_2010 ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 ///
	pc_* dist distance_lat, id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store i
reghdfe country_dummy dist distance_lat (ancestry_2010 = ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 pc_*) ///
	, absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
local kp_fstat = e(rkf)
mat first = e(first)
local cd_fstat = first[4,1]
local cvalue5 = 21.18 // needs to be read off the reghdfe output manually
local cvalue10 = 11.52 // needs to be read off the reghdfe output manually
estimates restore i
qui estadd scalar kp_fstat `kp_fstat'
qui estadd scalar cd_fstat `cd_fstat'
qui estadd scalar cvalue5 `cvalue5'
qui estadd scalar cvalue10 `cvalue10'
qui estadd local fe1 "Yes"
qui estadd local fe2 "Yes"
qui estadd local dist "Yes"
qui estadd local lat "Yes"
qui estadd local pc "Yes"
qui estadd local fe3 "Yes"
qui estadd local fe4 "Yes"
qui estadd local pol "No"
estimates store i

* Table Two Column 8: same as 5 but exclude 1880 immigration
use "Input/Replication.dta", replace

* Generate proper (!) orthogonal instruments
qui reg immi_nc_d_X_o_ndv_3  immi_nc_d_X_o_ndv_2
predict res_3, r
rename immi_nc_d_X_o_ndv_3 XXXimmi_nc_d_X_o_ndv_3
rename res_3 immi_nc_d_X_o_ndv_3

qui reg immi_nc_d_X_o_ndv_4  immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2
predict res_4, r
rename immi_nc_d_X_o_ndv_4 XXXimmi_nc_d_X_o_ndv_4
rename res_4 immi_nc_d_X_o_ndv_4

qui reg immi_nc_d_X_o_ndv_5  immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2
predict res_5, r
rename immi_nc_d_X_o_ndv_5 XXXimmi_nc_d_X_o_ndv_5
rename res_5 immi_nc_d_X_o_ndv_5

qui reg immi_nc_d_X_o_ndv_6  immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2
predict res_6, r
rename immi_nc_d_X_o_ndv_6 XXXimmi_nc_d_X_o_ndv_6
rename res_6 immi_nc_d_X_o_ndv_6

qui reg immi_nc_d_X_o_ndv_7  immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2
predict res_7, r
rename immi_nc_d_X_o_ndv_7 XXXimmi_nc_d_X_o_ndv_7
rename res_7 immi_nc_d_X_o_ndv_7

qui reg immi_nc_d_X_o_ndv_8  immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2
predict res_8, r
rename immi_nc_d_X_o_ndv_8 XXXimmi_nc_d_X_o_ndv_8
rename res_8 immi_nc_d_X_o_ndv_8

qui reg immi_nc_d_X_o_ndv_9  immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2
predict res_9, r
rename immi_nc_d_X_o_ndv_9 XXXimmi_nc_d_X_o_ndv_9
rename res_9 immi_nc_d_X_o_ndv_9

qui reg immi_nc_d_X_o_ndv_10 immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2
predict res_10, r
rename immi_nc_d_X_o_ndv_10 XXXimmi_nc_d_X_o_ndv_10
rename res_10 immi_nc_d_X_o_ndv_10


* Rename principal components
foreach time of numlist 1/5 {
  rename pcFour`time' pc_`time'
}

qui reg2hdfe log_ancestry_2010 ///
	immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 ///
	pc_* dist distance_lat, id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store h
reghdfe country_dummy dist distance_lat (log_ancestry_2010 = ///
	immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 pc_*) ///
	, absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
local kp_fstat = e(rkf)
mat first = e(first)
local cd_fstat = first[4,1]
local cvalue5 = 21.10 // needs to be read off the reghdfe output manually
local cvalue10 = 11.52 // needs to be read off the reghdfe output manually
estimates restore h
qui estadd scalar kp_fstat `kp_fstat'
qui estadd scalar cd_fstat `cd_fstat'
qui estadd scalar cvalue5 `cvalue5'
qui estadd scalar cvalue10 `cvalue10'
qui estadd local fe1 "Yes"
qui estadd local fe2 "Yes"
qui estadd local dist "Yes"
qui estadd local lat "Yes"
qui estadd local pc "Yes"
qui estadd local fe3 "Yes"
qui estadd local fe4 "Yes"
qui estadd local pol "No"
estimates store h

* Write output
estout a b c d e f g h i using "Output/Table2.tex", ///
cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") ///
stats(kp_fstat cvalue5 cvalue10 r2 N fe1 fe2 dist lat fe3 fe4 pc pol, fmt(%9.3f %9.2f %9.2f %9.2f %9.0fc %7.3g %7.3g %7.3g %7.3g %7.3g %7.3g %7.3g %7.3g) ///
labels("\addlinespace Kleibergen Wald rk statistic" "Stock-Yogo 5\% critical values" "Stock-Yogo 10\% critical values" "\addlinespace\$R^2\$" "\$N\$" ///
"\addlinespace Destination FE" "Origin FE" "Distance" "Latitude Difference" ///
"Destination \$\times\$ Continent FE" "Origin \$\times\$ Census Region FE" "Principal Components" "3rd order poly in dist and lat")) ///
msign(--) style(tex) collabels(,none) ///
substitute(\_ _) starlevel(* 0.10 ** 0.05 *** 0.01) replace ///
mlabels(,none) numbers ///
mgroups("Log ancestry 2010" "Ancestry 2010", ///
pattern(1 0 0 0 0 0 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span}) span) ///
prehead("\begin{tabular}{l*{@M}{rr}}" "\hline\hline\addlinespace") ///
posthead("\hline\addlinespace") prefoot("\addlinespace\hline\addlinespace") ///
postfoot("\addlinespace\hline\hline\addlinespace \end{tabular}") ///
keep(immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 ///
immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 ///
immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_10) ///
order(immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 ///
immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 ///
immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_10) ///
varlabels(immi_nc_d_X_o_ndv_1 "\$I_{o,-r(d)}^{1880}\times\frac{I_{-c(o),d}^{1880}}{I_{-c(o)}^{1880}}\$" ///
immi_nc_d_X_o_ndv_2 "\$I_{o,-r(d)}^{1900}\times\frac{I_{-c(o),d}^{1900}}{I_{-c(o)}^{1900}}\$" ///
immi_nc_d_X_o_ndv_3 "\$I_{o,-r(d)}^{1910}\times\frac{I_{-c(o),d}^{1910}}{I_{-c(o)}^{1910}}\$" ///
immi_nc_d_X_o_ndv_4 "\$I_{o,-r(d)}^{1920}\times\frac{I_{-c(o),d}^{1920}}{I_{-c(o)}^{1920}}\$" ///
immi_nc_d_X_o_ndv_5 "\$I_{o,-r(d)}^{1930}\times\frac{I_{-c(o),d}^{1930}}{I_{-c(o)}^{1930}}\$" ///
immi_nc_d_X_o_ndv_6 "\$I_{o,-r(d)}^{1970}\times\frac{I_{-c(o),d}^{1970}}{I_{-c(o)}^{1970}}\$" ///
immi_nc_d_X_o_ndv_7 "\$I_{o,-r(d)}^{1980}\times\frac{I_{-c(o),d}^{1980}}{I_{-c(o)}^{1980}}\$" ///
immi_nc_d_X_o_ndv_8 "\$I_{o,-r(d)}^{1990}\times\frac{I_{-c(o),d}^{1990}}{I_{-c(o)}^{1990}}\$" ///
immi_nc_d_X_o_ndv_9 "\$I_{o,-r(d)}^{2000}\times\frac{I_{-c(o),d}^{2000}}{I_{-c(o)}^{2000}}\$" ///
immi_nc_d_X_o_ndv_10 "\$I_{o,-r(d)}^{2010}\times\frac{I_{-c(o),d}^{2010}}{I_{-c(o)}^{2010}}\$")

***************************************************************************************************************************
* Table 3: Second-stage: The effect of Ancestry on FDI
***************************************************************************************************************************
cd "${wkdir}"
use "Input/Replication.dta", replace

// Get rid of 2010 immigration
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

*************************** Table Three Panel A ********************************

// Panel A Column One
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableThreeA_1
 
// Panel A Column Two
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_*  pcFour*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableThreeA_2

// Panel A Column Three
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableThreeA_3

// Panel A Column Four
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableThreeA_4

// Panel A Column Five
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3 dist_Cosine) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableThreeA_5

// Panel A Column Six
rename XXimmi_nc_d_X_o_ndv_10 immi_nc_d_X_o_ndv_10
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableThreeA_6
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

// Panel A Column Seven
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(state_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableThreeA_7

*************************** Table Three Panel B ********************************

// Panel B Column One & Two
qui reg2hdfe country_dummy log_ancestry_2010 dist distance_lat, id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990)
estimates store TableThreeB_1, title(" ")
estimates store TableThreeB_2, title(" ")

// Panel B Column Three & Six
qui reg2hdfe country_dummy log_ancestry_2010 dist distance_lat, id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableThreeB_3, title(" ")
estimates store TableThreeB_6, title(" ")

// Panel B Column Four 
qui reg2hdfe country_dummy log_ancestry_2010 dist dist2 dist3 distance_lat distance_lat2 distance_lat3, id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableThreeB_4, title(" ")

// Panel B Column Five 
qui reg2hdfe country_dummy log_ancestry_2010 dist dist2 dist3 distance_lat distance_lat2 distance_lat3 dist_Cosine, id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableThreeB_5, title(" ")

// Panel B Column Seven
qui reg2hdfe country_dummy log_ancestry_2010 dist distance_lat, id1(state_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableThreeB_7, title(" ")

cd "${wkdir}"
estout TableThreeA_* using "./Output/Table3A.tex", replace style(tex) ///
keep(log_ancestry_2010 dist) order(log_ancestry_2010 dist) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0g) labels("N")) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

estout TableThreeA_* using "./Output/AppTable7A.tex", replace style(tex) ///
keep(log_ancestry_2010) order(log_ancestry_2010) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0g) labels("N")) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

estout TableThreeB_1 TableThreeB_2 TableThreeB_3 TableThreeB_4 TableThreeB_5 TableThreeB_6 TableThreeB_7 ///
using "./Output/Table3B.tex", replace style(tex) keep(log_ancestry_2010) ///
order(log_ancestry_2010) ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) ///
stats(r2 N,fmt(%9.4f %9.0g) labels("\$R^2\$" "N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

*************************** IVProbit Regression ********************************
/*
* Note: This result is reported in the note to Table 3, it is commented out due to the
* amount of time it takes to run.
* Mark countries with zero FDI (set A)
bysort country_code1990: egen country_fdi = total(country_dummy)
gen setA = 0
replace setA = 1 if country_fdi == 0

* Mark counties with zero FDI (set B)
bysort state_county_code_1990: egen county_fdi = total(country_dummy)
gen setB = 0
replace setB = 1 if county_fdi == 0

* Show ivprobit results on the screen
ivprobit country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*) i.country_code1990 i.state_county_code_1990 if setA == 0 & setB == 0, twostep
margins, dydx(log_ancestry_2010) atmeans
*/

***************************************************************************************************************************
* Table 4: The Effect of Ancestry on FDI: The Case of Communist Countries
***************************************************************************************************************************
use "Input/Replication.dta", replace

/* 
Region			Period		Scenario (1)	Scenario (2)	Scenario (3)
Soviet Union	1918-1990	1930-1990		1920-1990		1930-1990
China			1945-1980	1980			1970-1980		1970-1980
Vietnam			1975-1996	1990			1980-2000		1980-2000
Eastern Eur.	1945-1989	1980			1970-1990		1970-1990
*/

*** This code will generate Table 4 for each of 3 scenarios - for the paper, Scenario 1 was chosen
foreach opt of numlist 1/1{

	*** Keep selected countries only
	keep if country_code == 810 | country_code == 156 | country_code == 100 | ///
	country_code == 200 | country_code == 348 | country_code == 616 | ///
	country_code == 642 | country_code == 8 | country_code == 704

	*** Case One: Soviet Union
	preserve
		keep if country_code1990 == 810
		local start = 5-1*(`opt'==2)
		foreach time of numlist `start'/8 {
		  rename immi_nc_d_X_o_ndv_`time' EX_immi_nc_d_X_o_ndv_`time'
		}

		ivreg2 country_dummy dist distance_lat (log_ancestry_2010 = EX_immi_nc_d_X_o_ndv_*), robust
		estimates store TableFour_`opt'_1
	restore

	*** Case Two: People's Republic of China
	preserve
		keep if country_code1990 == 156
		local start= 6+1*(`opt'==1)
		foreach time of numlist `start'/7 {
		  rename immi_nc_d_X_o_ndv_`time' EX_immi_nc_d_X_o_ndv_`time'
		}

		ivreg2 country_dummy dist distance_lat (log_ancestry_2010 = EX_immi_nc_d_X_o_ndv_*), r
		estimates store TableFour_`opt'_2
	restore

	*** Case Three: Vietnam
	preserve
		keep if country_code1990 == 704
		local start= 7+1*(`opt'==1)
		local stop= 9-1*(`opt'==1)
		*local stop= 8 //drop 9th wave
		foreach time of numlist `start'/`stop' {
		  rename immi_nc_d_X_o_ndv_`time' EX_immi_nc_d_X_o_ndv_`time'
		}
		ivreg2 country_dummy dist distance_lat (log_ancestry_2010 = EX_immi_nc_d_X_o_ndv_*), r
		estimates store TableFour_`opt'_3
	restore

	*** Case Four: Eastern Europe Countries
	preserve
		* Drop Soviet Union, China and Vietnam
		drop if country_code1990 == 810 | country_code == 156 | country_code == 704
		local start= 6+1*(`opt'==1)
		local stop= 8-1*(`opt'==1)
		foreach time of numlist `start'/`stop' {
		  rename immi_nc_d_X_o_ndv_`time' EX_immi_nc_d_X_o_ndv_`time'
		}

		ivreg2 country_dummy  dist distance_lat i.country_code1990 (log_ancestry_2010 = EX_immi_nc_d_X_o_ndv_*), cl(country_code1990)
		ereturn list
		estimates store TableFour_`opt'_4
	restore

	*** Case Five: all countries together with dest FE
	// Generate dummy variables for each region to pull correct time periods
	preserve
	foreach time of numlist 1/10 {
	  gen dummy_`time' = 0
	  *** Soviet Union
	  local start = 5-1*(`opt'==2)
	  if (`time' >=`start' & `time' <= 8) {
		replace dummy_`time' = 1 if country_code1990 == 810 
	  }
	  *** China
	  local start= 6+1*(`opt'==1)
	  if (`time' >=`start' & `time' <= 7) {
		replace dummy_`time' = 1 if country_code1990 == 156 
	  }
	  *** Vietnam
	  local start= 7+1*(`opt'==1)
	  local stop= 9-1*(`opt'==1)
	  *local stop= 8 //drop 9th wave
	  if (`time' >= `start' & `time' <= `stop') {
		replace dummy_`time' = 1 if country_code1990 == 704 
	  }
	  *** Eastern Europe
	  local start= 6+1*(`opt'==1)
	  local stop= 8-1*(`opt'==1)
	  if (`time' >= `start' & `time' <= `stop') {
		replace dummy_`time' = 1 if (country_code1990 != 810 & country_code1990 != 156 ///
		& country_code1990 != 704)
	  }
	 
	// Generate the excluded immigration  
	gen EX_immi_nc_d_X_o_ndv_`time' = immi_nc_d_X_o_ndv_`time' * dummy_`time'

	// Generate the included immigration
	gen IN_immi_nc_d_X_o_ndv_`time' = immi_nc_d_X_o_ndv_`time' * (1-dummy_`time')

	}
	*ivreg2 country_dummy dist distance_lat i.country_code1990 i.state_county_code_1990 IN_immi_nc_d_X_o_ndv_* (log_ancestry_2010 = EX_immi_nc_d_X_o_ndv_*), ///
	*robust cl(country_code1990)
	reghdfe country_dummy dist distance_lat (log_ancestry_2010 = EX_immi_nc_d_X_o_ndv_*), ///
	absorb(i.country_code1990 state_county_code_1990) vce(robust)
	ereturn list
	estimates store TableFour_`opt'_5, title(" ")
	restore
	
	estout TableFour_`opt'_* using "Output/Table4.tex", replace style(tex) ///
	keep(log_ancestry_2010) order(log_ancestry_2010) ml( ,none) collabels(, none) ///
	cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0fc) ///
	labels("\addlinespace N")) ///
	starlevels(* 0.10 ** 0.05 *** 0.01) label
}

****************************************************************************************************
* Table 5: Variations of leave-out: Consolidated table                         
****************************************************************************************************

*---------*
* Panel A *
*---------*
est clear
use "Input/EthnicityDataForRegression_Table5A.dta", replace

// Get rid of 2010 immigration
rename immi_nc_d_X_o_naj_10 XXimmi_nc_d_X_o_naj_10

// Panel D Column Three of Appendix table on alternative leave-out's
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) ///
	iv(immi_nc_d_X_o_naj_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
matrix B_b_1 = e(b)
matrix B_V_1 = e(V)
global B_df_1 = e(Fdf2)
cd "${wkdir}" // Needed because ivreg2hdfe changes dir

*-----------*
* Panel A/B *
*-----------*
use "Input/Replication.dta", replace

// Get rid of 2010 immigration
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10
rename immi_LO4_d_X_o_ndv_10 XXimmi_LO4_d_X_o_ndv_10
rename immi_LO8_d_X_o_ndv_10 XXimmi_LO8_d_X_o_ndv_10

*Panel E Column Three of Appendix table on alternative leave-out's
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat)  iv(immi_LO4_d_X_o_ndv_* pcLO4*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
matrix C_b_1 = e(b)
matrix C_V_1 = e(V)
global C_df_1 = e(Fdf2)

*Panel F Column Three of Appendix table on alternative leave-out's
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat)  iv(immi_LO8_d_X_o_ndv_* pcLO8*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
matrix A_b_1 = e(b)
matrix A_V_1 = e(V)
global A_df_1 = e(Fdf2)

*Only 1880, 1900, 1910, 1920, and 1930
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) ///
	iv(immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 ///
	immi_nc_d_X_o_ndv_5) ///
	id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
matrix D_b_1 = e(b)
matrix D_V_1 = e(V)
global D_df_1 = e(Fdf2)

*Only 1970, 1980, 1990, 2000
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) ///
	iv(immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9) ///
	id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
matrix E_b_1 = e(b)
matrix E_V_1 = e(V)
global E_df_1 = e(Fdf2)

*Only 1900-2000
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) ///
	iv(immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 ///
	immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9) ///
	id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
matrix F_b_1 = e(b)
matrix F_V_1 = e(V)
global F_df_1 = e(Fdf2)

cd "${wkdir}" // Needed because ivreg2hdfe changes dir


*--------------*
* Write output *
*--------------*
capture file close texfile
file open texfile using "Output/Table5.tex", write replace
file write texfile "& \\\hline\hline\addlinespace" _n
file write texfile "\textsc{Panel A:} Variations of leave-out categories & \textit{FDI 2014 (Dummy)} \\\addlinespace\hline\addlinespace" _n
getcoeffs "1" "C"
file write texfile "Excluding origins with correlated migration flows: \$ I_{o,-r(d)}^{t} \times (I_{-s^1(o),d}^{t} / I_{-s^1(o)}^{t}) \$  & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\\addlinespace" _n
getcoeffs "1" "A"
file write texfile "Excluding origins with correlated 2010 ancestry stock: \$ I_{o,-r(d)}^{t} \times (I_{-s^2(o),d}^{t} / I_{-s^2(o)}^{t}) \$  & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\\addlinespace" _n
getcoeffs "1" "B"
file write texfile "Excluding states adjacent to the destination: \$ I_{o,-adj(d)}^{t} \times (I_{-c(o),d}^{t} / I_{-c(o)}^{t}) \$  & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\\addlinespace\hline\addlinespace" _n
file write texfile "\textsc{Panel B:} Using subsets of instruments for identification & \textit{FDI 2014 (Dummy)} \\\addlinespace\hline\addlinespace" _n
getcoeffs "1" "D"
file write texfile "Only migrations \$ 1880-1930 \$  & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\\addlinespace" _n
getcoeffs "1" "E"
file write texfile "Only migrations \$ 1970-2000 \$  & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\\addlinespace" _n
getcoeffs "1" "F"
file write texfile "Only migrations \$ 1900-2000 \$  & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\\addlinespace\hline\hline" _n
file close texfile


*-----------------------------------------*
* Test of Panel B Coefficients (EMIT-166) *
*-----------------------------------------*

*Orthogonalize the variables with iterated FWL
cd "${wkdir}"
hdfe country_dummy log_ancestry_2010 dist distance_lat immi_nc_d_X_o_ndv_* pcFour*, absorb(region_country_code county_continent_code) generate(orth_) clusterv(country_code1990)

*Run both iv equations and perform cross equation test
gmm (eq1: orth_country_dummy - {b1}*orth_log_ancestry_2010 - {b2}*orth_dist - {b3}*orth_distance_lat - {b0}) ///
	(eq2: orth_country_dummy - {c1}*orth_log_ancestry_2010 - {c2}*orth_dist - {c3}*orth_distance_lat - {c0}), ///
	instruments(eq1: orth_dist orth_distance_lat orth_immi_nc_d_X_o_ndv_1 orth_immi_nc_d_X_o_ndv_2 orth_immi_nc_d_X_o_ndv_3 orth_immi_nc_d_X_o_ndv_4 orth_immi_nc_d_X_o_ndv_5 orth_pcFour*) ///
	instruments(eq2: orth_dist orth_distance_lat orth_immi_nc_d_X_o_ndv_6 orth_immi_nc_d_X_o_ndv_7 orth_immi_nc_d_X_o_ndv_8 orth_immi_nc_d_X_o_ndv_9 orth_pcFour*) ///
	onestep winitial(unadjusted, indep) vce(cluster country_code1990)
estimates store GMM

*Save test for equlity of coefficients
test [b1]_cons==[c1]_cons
local Tab5_chi2_p = r(p)
file open file166 using "Output/Table5B_CoeffEqTest.txt", write replace
file write file166 "The p-value for the test of equality between coefficients is " `"`Tab5_chi2_p'"'
file close file166

***************************************************************************************************************************
* Table 6 Panel A: The Effect of Ancestry on Immigration
***************************************************************************************************************************
use "Input/EthnicityDataForRegression_Table6.dta", replace

*-------------------------*
* 2) For immigration 2000 *
*-------------------------*
* Make 2000 instrument inclusive
rename immi_nc_d_X_o_ndv_10 INimmi_nc_d_X_o_ndv_10
rename immi_nc_d_X_o_ndv_9 INimmi_nc_d_X_o_ndv_9

gen log_immigrants_2000 = log(1+immigrants_2000)

* With I^2000: Regression; level
reghdfe immigrants_2000 dist distance_lat INimmi_nc_d_X_o_ndv_9 (log_ancestry_1990 = immi_nc_d_X_o_ndv_*), ///
absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
mat first = e(first)
estimates store TableTwo_4

* With I^2000: Regression; log
reghdfe log_immigrants_2000 dist distance_lat INimmi_nc_d_X_o_ndv_9 (log_ancestry_1990 = immi_nc_d_X_o_ndv_*), ///
absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
mat first = e(first)
estimates store TableTwo_4log


*-------------------------*
* 3) For immigration 1990 *
*-------------------------*
* Make 1990 instrument inclusive
rename immi_nc_d_X_o_ndv_8 INimmi_nc_d_X_o_ndv_8
gen log_immigrants_1990 = log(1+immigrants_1990)

* With I^1990: Regression
reghdfe log_immigrants_1990 dist distance_lat INimmi_nc_d_X_o_ndv_8 (log_ancestry_1980 = immi_nc_d_X_o_ndv_*), ///
absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
mat first = e(first)
estimates store TableTwo_6log


*--------------*
* Write output *
*--------------*
estout TableTwo_* using "Output/Table6A.tex", replace style(tex) ///
keep(log_ancestry_1990 log_ancestry_1980 INimmi_nc_d_X_o_ndv_9 INimmi_nc_d_X_o_ndv_8) ///
order(log_ancestry_1990 log_ancestry_1980 INimmi_nc_d_X_o_ndv_9 INimmi_nc_d_X_o_ndv_8) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0fc) ///
labels("\addlinespace N")) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

***************************************************************************************************************************
*Table 6 Panel B 
***************************************************************************************************************************
use "./Input/Replication.dta", replace
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

*----------------------------------*
* Replicate App. Table 18 Panel A  *
*----------------------------------*

*Only 1990 and 2000 used as instruments, all others not included
forvalues y=1/9{
	if `y'<8{
		gen  immi_nc_d_X_o_ndv_c`y'=immi_nc_d_X_o_ndv_`y'
		}
	else {
		gen  immi_nc_d_X_o_ndv_I`y'=immi_nc_d_X_o_ndv_`y'
		}
}

* IV 
qui reghdfe log_fditotal dist distance_lat log_fditotalplusone_2007 (log_ancestry_2010 = immi_nc_d_X_o_ndv_I* pcFour*), ///
absorb(i.region_country_code i.county_continent_code) vce(cluster country_code1990) estimator(gmm2s) keepsingletons
estimates store TableSixC_2

*----------------------------*
* Replicate Table 3 Panel A  *
*----------------------------*
// Paper specification (A); Only 1990 and 2000 used as instruments, all others not included (C)

// Panel A Column Three
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat fdi_dummy_2007) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableSixA_3
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat fdi_dummy_2007) iv(immi_nc_d_X_o_ndv_I* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableSixC_3

*--------------*
* Write output *
*--------------*
cd "${wkdir}"

*** Tables for EMIT Paper
estout TableSixA_3 TableSixC_3 TableSixC_2 using "./Output/Table6B.tex", replace style(tex) ///
keep(log_ancestry_2010 fdi_dummy_2007 log_fditotalplusone_2007) order(log_ancestry_2010 fdi_dummy_2007 log_fditotalplusone_2007) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0fc) labels("N")) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

**************************************************************************************************************************
* Table 7: The ``Similarities'' Hypothesis
**************************************************************************************************************************
*------------------------------------------*
* Panel A,B: Final v.s. Intermediate Goods *
*------------------------------------------*
est clear
use "Input/EthnicityDataForRegression_Table7PanAB.dta", replace

// Exclude 2010 push and pull
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

*3) Run regressions
foreach a in final inter {
	qui reghdfe country_dummy_`a' dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
	absorb(region_country_code county_continent_code) vce(cluster country_code1990)
	matrix `a'_b_1 = e(b)
	matrix `a'_V_1 = e(V)
	global `a'_df_1 = e(df_r)
	
	qui count if e(sample)
	global `a'_N_1 = r(N)
}

*5) Run regressions for Inward FDI only. 
foreach a in final inter {
	qui reghdfe shareholder_country_dummy_`a' dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
	absorb(region_country_code county_continent_code) vce(cluster country_code1990)
	matrix `a'I_b_1 = e(b)
	matrix `a'I_V_1 = e(V)
	global `a'I_df_1 = e(df_r)
	
	qui count if e(sample)
	global `a'I_N_1 = r(N)
}

*Write output, full sample 
capture file close texfile
file open texfile using "Output/Table7A.tex", write replace

getcoeffs "1" "final" /* final goods coeff+stars */
file write texfile "Log Ancestry 2010 & `r(coeff)'`r(stars)' & "
getcoeffs "1" "inter" /* intermediate goods coeff+stars */
file write texfile "`r(coeff)'`r(stars)' \\" _n

getcoeffs "1" "final" /* final goods se */
file write texfile "& (`r(se)') & "
getcoeffs "1" "inter" /* intermediate se */
file write texfile "(`r(se)') \\\addlinespace" _n

getcoeffs "1" "final" /* final goods N */
file write texfile "\$N\$ & `r(N)' &"
getcoeffs "1" "inter" /* intermediate goods N */
file write texfile "`r(N)' \\\addlinespace" _n

file write texfile "Sample & Final goods & Intermediate goods \\" _n
file close texfile

*Write output, inward FDI
capture file close texfile
file open texfile using "Output/Table7B.tex", write replace

getcoeffs "1" "finalI" /* final goods coeff+stars */
file write texfile "Log Ancestry 2010 & `r(coeff)'`r(stars)' & "
getcoeffs "1" "interI" /* intermediate goods coeff+stars */
file write texfile "`r(coeff)'`r(stars)' \\" _n

getcoeffs "1" "finalI" /* final goods se */
file write texfile "& (`r(se)') & "
getcoeffs "1" "interI" /* intermediate se */
file write texfile "(`r(se)') \\\addlinespace" _n

*file write texfile "\$p\$-value of \$\chi^2\$ test, H\$_{0}\$: equality of coefficients & \multicolumn{2}{c}{`: di %5.3fc ${chi2_B}'} \\\addlinespace" _n

getcoeffs "1" "finalI" /* final goods N */
file write texfile "\$N\$ & `r(N)' &"
getcoeffs "1" "interI" /* intermediate goods N */
file write texfile "`r(N)' \\\addlinespace" _n

file write texfile "Sample & Final goods & Intermediate goods \\" _n
file close texfile

*-----------------------------------------*
* Test of Panel A Coefficients            *
*-----------------------------------------*
*Orthogonalize the variables with iterated FWL
cd "${wkdir}"
hdfe country_dummy_final country_dummy_intermediate log_ancestry_2010 dist distance_lat immi_nc_d_X_o_ndv_* pcFour*, absorb(region_country_code county_continent_code) generate(orth_) clusterv(country_code1990)

*Run both iv equations and perform cross equation test
gmm (eq1: orth_country_dummy_final - {b1}*orth_log_ancestry_2010 - {b2}*orth_dist - {b3}*orth_distance_lat - {b0}) ///
	(eq2: orth_country_dummy_intermediate - {c1}*orth_log_ancestry_2010 - {c2}*orth_dist - {c3}*orth_distance_lat - {c0}), ///
	instruments(eq1: orth_dist orth_distance_lat orth_immi_nc_d_X_o_ndv_* orth_pcFour*) ///
	instruments(eq2: orth_dist orth_distance_lat orth_immi_nc_d_X_o_ndv_* orth_pcFour*) ///
	onestep winitial(unadjusted, indep) vce(cluster country_code1990)
estimates store GMM

*Save test for equlity of coefficients
test [b1]_cons==[c1]_cons
local Tab7_chi2_p = r(p)
file open file7 using "Output/Table7A_CoeffEqTest.txt", write replace
file write file7 "The p-value for the test of equality between coefficients is " `"`Tab7_chi2_p'"'
file close file7

*--------------------------------*
* Panel C: Industry correlations *
*--------------------------------*
use "Input/EthnicityDataForRegression_Table7PanC.dta", replace

// Get rid of 2010 immigration
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

// Panel C: Regression with correlations as dependent variable
foreach depvar in corr_rank corr_cos {
	qui reghdfe `depvar' dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
	absorb(region_country_code county_continent_code) vce(cluster country_code1990) 
	matrix `depvar'_b_1 = e(b)
	matrix `depvar'_V_1 = e(V)
	global `depvar'_df_1 = e(df_r)
	
	qui count if e(sample)
	global `depvar'_N_1 = r(N)
	
	qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*) if `depvar' != ., ///
	absorb(region_country_code county_continent_code) vce(cluster country_code1990) 
}

*------------------------------------------*
* Write to file                            *
*------------------------------------------*
capture file close texfile
file open texfile using "Output/Table7C.tex", write replace

*Coefficients
getcoeffs "1" "corr_rank"
file write texfile "Log Ancestry 2010 & `r(coeff)'`r(stars)' & "
getcoeffs "1" "corr_cos"
file write texfile "`r(coeff)'`r(stars)' \\" _n

*Standard errors
getcoeffs "1" "corr_rank"
file write texfile "& (`r(se)') & "
getcoeffs "1" "corr_cos"
file write texfile "(`r(se)') \\\addlinespace" _n

*Number of obs
getcoeffs "1" "corr_rank"
file write texfile "\$N\$ & `r(N)' & "
getcoeffs "1" "corr_cos"
file write texfile "`r(N)' \\" _n

file close texfile

*---------------------------*
* Panel D: Judicial Quality *
*---------------------------*
est clear
use "Input/Replication.dta", replace

gen logA_interact_qc = Qc * log_ancestry_2010
label variable logA_interact_qc "Log Ancestry $\times$ Judicial Quality"

qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 logA_interact_qc = immi_nc_d_X_o_ndv_? pcFour?), ///
absorb(country_code1990 county_code_1990) vce(cluster country_code1990)
est sto a

qui reghdfe log_fditotal dist distance_lat (log_ancestry_2010 logA_interact_qc = immi_nc_d_X_o_ndv_? pcFour?), ///
absorb(country_code1990 county_code_1990) vce(cluster country_code1990)
est sto b

estout a b using "Output/Table7D.tex", ///
replace style(tex) keep(logA_interact_qc) ml( ,none) collabels(, none) ///
stats( N,fmt( %9.0fc) labels( "N")) cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

********************************************************************************
* Table 8: The effect of ancestry on differential information demand and language
********************************************************************************
*--------------------------------------*
* Panel A: Information Demand Indicies *
*--------------------------------------*
est clear
use "Input/EMIT_DMA_Table1and8.dta", clear

*Overall index, log ancestry 2010
reghdfe index_std dist distance_lat (log_ancestry2010 = immi_nc_d_X_o_nd_* pcThree*) ///
, vce(cluster country_code) absorb(i.country_code i.dma)
est sto gen1

*Overall index, log ancestry 2010 and foreign born 2010 
reghdfe index_std dist distance_lat log_foreignborn2010 (log_ancestry2010 = immi_nc_d_X_o_nd_* pcThree*) ///
, vce(cluster country_code) absorb(i.country_code i.dma)
est sto gen2

*Overall index, log ancestry 1980
reghdfe index_std dist distance_lat (log_ancestry1980 = immi_nc_d_X_o_nd_* pcThree*) ///
, vce(cluster country_code) absorb(i.country_code i.dma)
est sto gen3

*Actors index, log ancestry 2010
reghdfe actors_index_std dist distance_lat (log_ancestry2010 = immi_nc_d_X_o_nd_* pcThree*) ///
, vce(cluster country_code) absorb(i.country_code i.dma)
est sto gen4

*Athletes index, log ancestry 2010
reghdfe athletes_index_std dist distance_lat (log_ancestry2010 = immi_nc_d_X_o_nd_* pcThree*) ///
, vce(cluster country_code) absorb(i.country_code i.dma)
est sto gen5

*Musicians index, log ancestry 2010
reghdfe musicians_index_std dist distance_lat (log_ancestry2010 = immi_nc_d_X_o_nd_* pcThree*) ///
, vce(cluster country_code) absorb(i.country_code i.dma)
est sto gen6

*Leaders index, log ancestry 2010
reghdfe leaders_index_std dist distance_lat (log_ancestry2010 = immi_nc_d_X_o_nd_* pcThree*) ///
, vce(cluster country_code) absorb(i.country_code i.dma)
est sto gen7

*Write output
estout gen* using "Output/Table8A.tex", ///
replace style(tex) keep(log_ancestry2010 log_foreignborn2010 log_ancestry1980) ml( ,none) collabels(, none) ///
stats(N,fmt(%9.0fc) labels("\$N\$")) cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

*-------------------*
* Panel B: Language *
*-------------------*
use "Input/EthnicityDataForRegression_Table8.dta", replace

// Get rid of 2010 immigration
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10
local fe "i.country_code i.county_code"

*All residents
qui reghdfe language_all dist distance_lat (ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), absorb(i.country_code i.county_code) vce(cluster i.country_code1990) 
estimates store a2010

*US-born
qui reghdfe language_domestic dist distance_lat (ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), absorb(i.country_code i.county_code) vce(cluster i.country_code1990) 
estimates store b2010

*US-born, ancestry 1980
qui reghdfe language_domestic dist distance_lat (ancestry_1980 = immi_nc_d_X_o_ndv_* pcFour*), absorb(i.country_code i.county_code) vce(cluster i.country_code1990) 
estimates store c2010

*US-born restricted to Spanish speaking
qui reghdfe language_domestic dist distance_lat (ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*) if actual_language == 1200, absorb(i.country_code) vce(cluster i.state_code) 
estimates store d2010

*US-born restricted to Arabic-speaking
qui reghdfe language_domestic dist distance_lat (ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*) if actual_language == 5700, absorb(i.country_code) vce(cluster i.state_code) 
estimates store e2010

*US-born restricted to Chinese-speaking
qui reghdfe language_domestic dist distance_lat (ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*) if actual_language == 4300, absorb(i.country_code) vce(cluster i.state_code) 
estimates store f2010

*US-born restricted to Hindi-speaking
qui reghdfe language_domestic dist distance_lat (ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*) if actual_language == 3102, absorb(i.country_code) vce(cluster i.state_code) 
estimates store g2010

estout a2010 b2010 c2010 d2010 e2010 f2010 g2010 using "Output/Table8B.tex", replace style(tex) ///
keep(ancestry_2010 ancestry_1980) order(ancestry_2010 ancestry_1980) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0fc) labels("\$N\$")) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

*************************************************************************************************************
* Table 9: Network Effects
*************************************************************************************************************
*---------------------------------------*
* Prepare spillover effects regressions *
*---------------------------------------*
use "./Input/Replication.dta", replace
keep state_county_code_1990 country_code1990 ancestry_2010 immigrants_*
rename country_code1990 pair_countrycode
rename ancestry_2010 ancestry_nn_d_2010
foreach time of numlist 1/10 {
  if `time' == 1 {
    local year = 1880
  }  
  else if `time' >= 2 & `time' <= 5 {
    local year = 1880 + `time'*10
  }
  else {
    local year = 1910 + `time'*10
  }  
  rename immigrants_`year' immigrants_nn_`year'
}
compress
saveold "./Input/NeighborCountryAncestry.dta", replace

use "./Input/Replication.dta", replace

rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

* Generate log(1+A_{o,s})
bysort country_code1990 state_code_1990: egen ancestry_o_s_2010 = total(ancestry_2010)
gen log_ancestry_o_s_2010 = log(1+ancestry_o_s_2010)
label variable log_ancestry_o_s_2010 "Log Ancestry 2010, State Level"

* Generate I_{-c,s} * I_{o,-div}
pause off
foreach time of numlist 1/9 {
  if `time' == 1 {
    local year = 1880
  }  
  else if `time' >= 2 & `time' <= 5 {
    local year = 1880 + `time'*10
  }
  else {
    local year = 1910 + `time'*10
  }
  bysort state_code_1990: egen double immigration_s_`time' = total(immigrants_`year')
  bysort continent state_code_1990: egen double immigration_c_s_`time' = total(immigrants_`year')
  qui gen double immigration_nc_s_`time' = immigration_s_`time' - immigration_c_s_`time'
  qui gen double immi_nc_s_X_o_ndv_`time' = (immigration_nc_s_`time' / immigration_nc_`time') * immigration_o_ndv_`time'
  qui replace immi_nc_s_X_o_ndv_`time' = 0 if immi_nc_s_X_o_ndv_`time' == .
  qui label variable immi_nc_s_X_o_ndv_`time' "\$I_{o,-r(d)}^{`year'}\frac{I_{-c(o),s(d)}^{`year'}}{I_{-c(o)}^{`year'}}\$"
}
sort state_county_code_1990 country_code1990

* Generate log(1+A_{nn,d})
merge 1:1 state_county_code_1990 pair_countrycode using "./Input/NeighborCountryAncestry.dta"
drop _merge
gen log_ancestry_nn_d_2010 = log(1+ancestry_nn_d_2010)
label variable log_ancestry_nn_d_2010 "Log Ancestry 2010 of Nearest Origin Country"

* Generate I_{-c,d} * I_{nn,-div}
foreach time of numlist 1/9 {
  if `time' == 1 {
    local year = 1880
  }  
  else if `time' >= 2 & `time' <= 5 {
    local year = 1880 + `time'*10
  }
  else {
    local year = 1910 + `time'*10
  }
  bysort pair_countrycode: egen double immigration_nn_`time' = total(immigrants_nn_`year')
  bysort pair_countrycode division: egen double immigration_nn_dv_`time' = total(immigrants_nn_`year')
  qui gen double immigration_nn_ndv_`time' = immigration_nn_`time' - immigration_nn_dv_`time'
  
  qui gen double immi_nc_d_X_nn_ndv_`time' = (immigration_nc_d_`time'/immigration_nc_`time') * immigration_nn_ndv_`time'
  qui replace immi_nc_d_X_nn_ndv_`time' = 0 if immi_nc_d_X_nn_ndv_`time' == .
  qui label variable immi_nc_d_X_nn_ndv_`time' "\$I_{nno,-r(d)}^{`year'}\frac{I_{-c(o),d}^{`year'}}{I_{-c(o)}^{`year'}}\$"
}
sort state_county_code_1990 country_code1990

*-----------------------------------*
* Run spillover effects regressions *
*-----------------------------------*
// Spillover Effect One: Use Additional log(1+A_{o,s})
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010 log_ancestry_o_s_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour* immi_nc_s_X_o_ndv_*) id1(country_code1990) id2(county_code_1990) cluster(country_code1990) 
estimates store TableEleven_B_5
qui ivreg2hdfe, depvar(log_fditotal)  en(log_ancestry_2010 log_ancestry_o_s_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour* immi_nc_s_X_o_ndv_*) id1(country_code1990) id2(county_code_1990) cluster(country_code1990) 
estimates store TableEleven_C_5

// Spillover Effect Two: Use Additional log(1+A_{nn,d})
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010 log_ancestry_nn_d_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour* immi_nc_d_X_nn_ndv_*) id1(country_code1990) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEleven_B_6
qui ivreg2hdfe, depvar(log_fditotal)  en(log_ancestry_2010 log_ancestry_nn_d_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour* immi_nc_d_X_nn_ndv_*) id1(country_code1990) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEleven_C_6

*------------------------*
* Write output (Panel A) *
*------------------------*
cd "${wkdir}"
estout TableEleven_B_5 TableEleven_B_6 TableEleven_C_5 TableEleven_C_6 using ///
"./Output/Table9A.tex", ///
replace style(tex) keep(log_ancestry_2010 log_ancestry_o_s_2010 ///
log_ancestry_nn_d_2010) ///
order(log_ancestry_2010 log_ancestry_o_s_2010 log_ancestry_nn_d_2010 ///
logA_interact*) ///
ml( ,none) collabels(, none) stats( N,fmt( %9.0fc) ///
labels( "N")) cells(b(star fmt(%9.3f)) se(par)) starlevels(* 0.10 ** 0.05 *** 0.01) label

*-------------------------------------------------*
* Prepare diversity effects regressions (Panel B) *
*-------------------------------------------------*
cd "${wkdir}"
use "Input/Replication.dta", replace

* Get rid of 2010 immigration forever
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

sort state_county_code_1990 country_code1990
bysort state_county_code_1990: egen total_ancestry = total(ancestry_2010)

* Generate the share of the population who have foreign ancestry 
gen foreign_share = 100 * (total_ancestry / population)

* Generate log per capita income
gen log_per_capita_income = log(per_capita_income)

* Generate Herfindahl index for the diversity of ancestry in the county 
gen ancestry_ratio   = ancestry_2010 / total_ancestry
gen ancestry_ratio_2 = ancestry_ratio * ancestry_ratio
bysort state_county_code_1990: egen herfindahl = total(ancestry_ratio_2)
sort state_county_code_1990 country_code1990
gen diversity = 1 - herfindahl

* Interact with population share
gen logA_interact_fs = foreign_share * log_ancestry_2010
label variable logA_interact_fs "Log Ancestry $\times$ Foreign Share" 

* Interact with herfindahl index
gen logA_interact_herfindahl = herfindahl * log_ancestry_2010
label variable logA_interact_herfindahl "Log Ancestry $\times$ Herfindahl"
gen logA_interact_diversity  = diversity * log_ancestry_2010
label variable logA_interact_diversity "Log Ancestry $\times$ Ethnic Diversity"

* Interact with per capita income
gen logA_interact_income = log_per_capita_income * log_ancestry_2010
label variable logA_interact_income "Log Ancestry $\times$ Per Capita Income"

*Regress with FDI dummy as outcome, but demean before (using reghdfe because much faster)
capture drop dm_fs
qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 logA_interact_fs = immi_nc_d_X_o_ndv_* pcFour*), absorb(country_code1990 county_code_1990) vce(cluster country_code1990)
qui su foreign_share if e(sample) // mean on sample
gen dm_fs = foreign_share - r(mean)
capture drop logA_interact_dmfs
gen logA_interact_dmfs = dm_fs * log_ancestry_2010
label variable logA_interact_dmfs "Log Ancestry $\times$ Foreign Share (demeaned)" 
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010 logA_interact_dmfs) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(country_code1990) id2(county_code_1990) cluster(country_code1990) 
estimates store TableEleven_B_1

capture drop dm_dv
qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 logA_interact_diversity = immi_nc_d_X_o_ndv_* pcFour*), absorb(country_code1990 county_code_1990) vce(cluster country_code1990)
qui su diversity if e(sample) // mean on sample
gen dm_dv = diversity - r(mean)
capture drop logA_interact_dmdv
gen logA_interact_dmdv = dm_dv * log_ancestry_2010
label variable logA_interact_dmdv "Log Ancestry $\times$ Ethnic Diversity (demeaned)"
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010 logA_interact_dmdv) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(country_code1990) id2(county_code_1990) cluster(country_code1990) 
estimates store TableEleven_B_2

*Regress with total FDI relationships as outcome, but demean before (using reghdfe because much faster)
capture drop dm_fs
qui reghdfe log_fditotal dist distance_lat (log_ancestry_2010 logA_interact_fs = immi_nc_d_X_o_ndv_* pcFour*), absorb(country_code1990 county_code_1990) vce(cluster country_code1990)
qui su foreign_share if e(sample) // mean on sample
gen dm_fs = foreign_share - r(mean)
capture drop logA_interact_dmfs
gen logA_interact_dmfs = dm_fs * log_ancestry_2010
label variable logA_interact_dmfs "Log Ancestry $\times$ Foreign Share" 
qui ivreg2hdfe, depvar(log_fditotal) en(log_ancestry_2010 logA_interact_dmfs) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(country_code1990) id2(county_code_1990) cluster(country_code1990) 
estimates store TableEleven_C_1

capture drop dm_dv
qui reghdfe log_fditotal dist distance_lat (log_ancestry_2010 logA_interact_fs = immi_nc_d_X_o_ndv_* pcFour*), absorb(country_code1990 county_code_1990) vce(cluster country_code1990)
qui su diversity if e(sample) // mean on sample
gen dm_dv = diversity - r(mean)
capture drop logA_interact_dmdv
gen logA_interact_dmdv = dm_dv * log_ancestry_2010
label variable logA_interact_dmdv "Log Ancestry $\times$ Ethnic Diversity"
qui ivreg2hdfe, depvar(log_fditotal) en(log_ancestry_2010 logA_interact_dmdv) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(country_code1990) id2(county_code_1990) cluster(country_code1990) 
estimates store TableEleven_C_2

*------------------------*
* Write output (Panel B) *
*------------------------*
cd "${wkdir}"
estout TableEleven_B_1 TableEleven_B_2 TableEleven_C_1 TableEleven_C_2 using ///
"./Output/Table9B.tex", ///
replace style(tex) keep(log_ancestry_2010 logA_interact*) ///
ml( ,none) collabels(, none) stats( N,fmt( %9.0fc) ///
labels( "N")) cells(b(star fmt(%9.3f)) se(par)) starlevels(* 0.10 ** 0.05 *** 0.01) label

*----------------------------*
* Panel C: Fractionalization *
*----------------------------*
use "Input/Replication.dta", replace
set more off

* Get rid of 2010 immigration for ever
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

gen logA_interact_qc = Qc * log_ancestry_2010
label variable logA_interact_qc "Log Ancestry $\times$ Judicial Quality"
gen logA_interact_dist = dist * log_ancestry_2010
label variable logA_interact_dist "Log Ancestry $\times$ Geographic Distance"
gen logA_interact_diversity  = country_diversity * log_ancestry_2010
label variable logA_interact_diversity "Log Ancestry $\times$ Fractionalization"

capture drop sample
gen sample = 1 if logA_interact_qc != . & logA_interact_dist != . & logA_interact_diversity != .

*Run regressions
foreach round in aaa bbb {
	
	if "`round'" == "aaa" {
		local outcome "country_dummy"
	}
	else if "`round'" == "bbb" {
		local outcome "log_fditotal"
	}
	
	capture drop dm_dist
	qui reghdfe `outcome' dist distance_lat (log_ancestry_2010 logA_interact_dist = immi_nc_d_X_o_ndv_? pcFour?) if sample == 1, ///
	absorb(country_code1990 county_code_1990) vce(cluster country_code1990)
	qui su dist if e(sample) // mean on sample
	gen dm_dist = dist - r(mean)
	capture drop logA_interact_dmdist
	gen logA_interact_dmdist = dm_dist * log_ancestry_2010
	label variable logA_interact_dmdist "Log Ancestry $\times$ Geographic Distance (demeaned)" 
	qui reghdfe `outcome' dm_dist distance_lat (log_ancestry_2010 logA_interact_dmdist = immi_nc_d_X_o_ndv_? pcFour?) if sample == 1, ///
	absorb(country_code1990 county_code_1990) vce(cluster country_code1990)
	est sto `round'1
	
	qui reghdfe `outcome' dist distance_lat (log_ancestry_2010 logA_interact_qc logA_interact_dist logA_interact_diversity = immi_nc_d_X_o_ndv_? pcFour?) if sample == 1, ///
	absorb(country_code1990 county_code_1990) vce(cluster country_code1990)
	foreach a in qc dist diversity {
		capture drop dm_`a'
		if "`a'" == "diversity" {
			local a_modified = "country_diversity"
		}
		else if "`a'" == "qc" {
			local a_modified = "Qc"
		}
		else {
			local a_modified = "`a'"
		}
		qui su `a_modified' if e(sample) // mean on sample
		gen dm_`a' = `a_modified' - r(mean)
		capture drop logA_interact_dm`a'
		gen logA_interact_dm`a' = dm_`a' * log_ancestry_2010
	}
	label variable logA_interact_dmdist "Log Ancestry $\times$ Geographic Distance"
	label variable logA_interact_dmqc "Log Ancestry $\times$ Judicial Quality" 
	label variable logA_interact_dmdiversity "Log Ancestry $\times$ Fractionalization" 
	qui reghdfe `outcome' dm_dist distance_lat (log_ancestry_2010 logA_interact_dmqc logA_interact_dmdist logA_interact_dmdiversity = immi_nc_d_X_o_ndv_? pcFour?) if sample == 1, ///
	absorb(country_code1990 county_code_1990) vce(cluster country_code1990)
	est sto `round'2
}
estout aaa1 aaa2 bbb1 bbb2 using "Output/Table9C.tex", ///
replace style(tex) keep(log_ancestry_2010 logA_interact_dm*) ml( ,none) collabels(, none) ///
stats( N,fmt( %9.0fc) labels( "N")) cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

*****************************************************************************************************************
*****************************************************************************************************************
****************************** APPENDIX TABLES START ************************************************************
*****************************************************************************************************************
*****************************************************************************************************************

********************************************************************************
* Appendix Table 4: Intensive Margin Summary Stats 
********************************************************************************
use "Input/Replication.dta", replace

// Reduce the scale of employees by 1000
replace subsidiarynumberemployees = subsidiarynumberemployees / 1000
replace ussubsidiary_numberofemployees = ussubsidiary_numberofemployees / 1000
label var subsidiarynumberemployees "\# of Workers Employed at Subsidiary in Origin (in thousands)"
label var ussubsidiary_numberofemployees "\# of Workers Employed at Subsidiary in Destination (in thousands)"  

rename log_fditotal log_fdi_total

capture program drop sumStatInten

program define sumStatInten
  capture log close
  capture erase "Output/AppTable4.prn"
  quietly log using "Output/AppTable4.prn", text
  * Calculate Ancestry
  qui sum ancestry_2010 if log_fdi_total != .
  local meanA1 = round(r(mean),.001)
  local sdA1   = round(r(sd),.001)
  local N1    = r(N)
  qui sum ancestry_2010 if subsidiarycount >0
  local meanA2 = round(r(mean),.001)
  local sdA2   = round(r(sd),.001)
  local N2    = r(N)
  qui sum ancestry_2010 if ussubsidiary_firmcount > 0
  local meanA3 = round(r(mean),.001)
  local sdA3   = round(r(sd),.001)
  local N3    = r(N)  
  *Display Ancestry
  display as text `"`: var label ancestry_2010'"' "&" /*
	        */ as result /*
	        */ %04.3f `meanA1' "&" /*
			*/ %04.3f `meanA2' "&" /*
			*/ %04.3f `meanA3' "\\"   
  display as result /*
	        */ "& (" %04.3f `sdA1' ")" /*
			*/ "& (" %04.3f `sdA2' ")" /*
			*/ "& (" %04.3f `sdA3' ") \\"  
  * Calculate fdi		
  qui sum fdi_total if log_fdi_total != .
  local mean1 = round(r(mean),.001)
  local sd1   = round(r(sd),.001)  
  * Display fdi
  display as text `"`: var label fdi_total'"' "&" /*
	        */ as result /*
			*/ %04.3f `mean1' "\\"   
  display as result /*
			*/ "& (" %04.3f `sd1' ") \\"  
  * Calculate statistics for pairs with at least one subsidiary in origin
  foreach x of varlist usparent_firmcount shareholdercount ussubsidiary_numberofemployees {
    qui sum `x' if subsidiarycount > 0
    local mean2 = round(r(mean),.001)
    local sd2   = round(r(sd),.001)
	* Display result
    display as text `"`: var label `x''"' "&" "&" /*
	          */ as result /*
			  */ %04.3f `mean2' "\\"   
    display as result /*
			  */ "& & (" %04.3f `sd2' ") \\"  	
  }
  * Calculate statistics for pairs with at least one subsidiary in destination
  foreach x of varlist subsidiarycount usparent_firmcount subsidiarynumberemployees {	
    qui sum `x' if ussubsidiary_firmcount > 0
    local mean3 = round(r(mean),.001)
    local sd3   = round(r(sd),.001)
	* Display result
    display as text `"`: var label `x''"' "&" "&" "&" /*
	          */ as result /*
			  */ %04.3f `mean3' "\\"   
    display as result /*
			  */ "& & & (" %04.3f `sd3' ") \\"  	    
  }	
  * Display # of observation
  display as text "N" "&" /*
          */ as result /*
		  */ `N1' "&" /*
		  */ `N2' "&" /*
		  */ `N3' "\\"
  qui log close
end

sumStatInten

********************************************************************************
* Appendix Table 6: The Effect of Ancestry on FDI: Correlation Robustness 
********************************************************************************
use "Input/Replication.dta", replace

local LONames LO1 LO2 LO3 LO4 LO5 LO6 LO7 LO8
forvalues j=1/8{
	local l `: word `j' of `LONames''
	rename immi_`l'_d_X_o_ndv_10 XXimmi_`l'_d_X_o_ndv_10
	qui reghdfe country_dummy dist distance_lat (log_ancestry_2010= immi_`l'_d_X_o_ndv_* pc`l'_*), ///
		absorb(region_country_code county_continent_code) vce(cluster country_code1990) 
	estimates store TableSO_`l'
}

cd "${wkdir}"
estout TableSO_LO1 TableSO_LO2 TableSO_LO3 TableSO_LO4  using "./Output/AppTable6A.tex", replace style(tex) ///
keep(log_ancestry_2010 dist) order(log_ancestry_2010 dist) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0g) labels("N")) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

estout TableSO_LO5 TableSO_LO6 TableSO_LO7 TableSO_LO8 using "./Output/AppTable6B.tex", replace style(tex) ///
keep(log_ancestry_2010 dist) order(log_ancestry_2010 dist) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0g) labels("N")) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

********************************************************************************
* Appendix Table 7: The Effect of Ancestry on FDI: Additional Robustness
********************************************************************************
*---------*
* Panel A *
*---------*
use "Input/Replication.dta", replace

// Get rid of 2010 immigration
rename immi_d_X_o_10 XXimmi_d_X_o_10

// Panel A Column One
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_d_X_o_*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenA_1, title(" ")
 
// Panel A Column Two
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_d_X_o_* pcOne*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenA_2, title(" ")

// Panel A Column Three
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_d_X_o_* pcOne*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenA_3, title(" ")

// Panel A Column Four
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3) iv(immi_d_X_o_* pcOne*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenA_4, title(" ")

// Panel A Column Five
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3 dist_Cosine) iv(immi_d_X_o_* pcOne*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenA_5, title(" ")

// Panel A Column Six
rename XXimmi_d_X_o_10 immi_d_X_o_10
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_d_X_o_* pcOne*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenA_6, title(" ")
rename immi_d_X_o_10 XXimmi_d_X_o_10

// Panel A Column Seven
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_d_X_o_* pcOne*) id1(state_country_code) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenA_7, title(" ")

*---------*
* Panel B *
*---------*
cd "${wkdir}"
use "Input/Replication.dta", replace

// Get rid of 2010 immigration
rename immi_no_d_X_o_nd_10 XXimmi_no_d_X_o_nd_10

// Panel B Column One
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_no_d_X_o_nd_*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenB_1, title(" ")
 
// Panel B Column Two
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_no_d_X_o_nd_* pcTwo*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenB_2, title(" ")

// Panel B Column Three
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_no_d_X_o_nd_* pcTwo*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenB_3, title(" ")

// Panel B Column Four
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3) iv(immi_no_d_X_o_nd_* pcTwo*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenB_4, title(" ")

// Panel B Column Five
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3 dist_Cosine) iv(immi_no_d_X_o_nd_* pcTwo*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenB_5, title(" ")

// Panel B Column Six
rename XXimmi_no_d_X_o_nd_10 immi_no_d_X_o_nd_10
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_no_d_X_o_nd_* pcTwo*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenB_6, title(" ")
rename immi_no_d_X_o_nd_10 XXimmi_no_d_X_o_nd_10

// Panel B Column Seven
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_no_d_X_o_nd_* pcTwo*) id1(state_country_code) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenB_7, title(" ")

*---------*
* Panel C *
*---------*
cd "${wkdir}"
use "Input/Replication.dta", replace

// Get rid of 2010 immigration
rename immi_nc_d_X_o_nd_10 XXimmi_nc_d_X_o_nd_10

// Panel C Column One
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_nd_*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenC_1, title(" ")
 
// Panel C Column Two
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_nd_* pcThree*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenC_2, title(" ")

// Panel C Column Three
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_nd_* pcThree*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenC_3, title(" ")

// Panel C Column Four
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3) iv(immi_nc_d_X_o_nd_* pcThree*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenC_4, title(" ")

// Panel C Column Five
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3 dist_Cosine) iv(immi_nc_d_X_o_nd_* pcThree*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenC_5, title(" ")

// Panel C Column Six
rename XXimmi_nc_d_X_o_nd_10 immi_nc_d_X_o_nd_10
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_nd_* pcThree*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenC_6, title(" ")
rename immi_nc_d_X_o_nd_10 XXimmi_nc_d_X_o_nd_10

// Panel C Column Seven
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_nd_* pcThree*) id1(state_country_code) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenC_7, title(" ")

*---------*
* Panel D *
*---------*
cd "${wkdir}"
use "./Input/EthnicityDataForRegression_Table5A.dta", replace

// Get rid of 2010 immigration
rename immi_nc_d_X_o_naj_10 XXimmi_nc_d_X_o_naj_10

// Panel D Column One
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_naj_*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenD_1, title(" ")
 
// Panel D Column Two
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_naj_* pcFour*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenD_2, title(" ")

// Panel D Column Three
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_naj_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenD_3, title(" ")

// Panel D Column Four
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3) iv(immi_nc_d_X_o_naj_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenD_4, title(" ")

// Panel D Column Five
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3 dist_Cosine) iv(immi_nc_d_X_o_naj_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenD_5, title(" ")

// Panel D Column Six
rename XXimmi_nc_d_X_o_naj_10 immi_nc_d_X_o_naj_10
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_naj_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenD_6, title(" ")
rename immi_nc_d_X_o_naj_10 XXimmi_nc_d_X_o_naj_10

// Panel D Column Seven
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_naj_* pcFour*) id1(state_country_code) id2(state_county_code_1990) cluster(country_code1990) 
estimates store TableEighteenD_7, title(" ")

*---------*
* Panel E *
*---------*
cd "${wkdir}"
use "Input/Replication.dta", replace

// Get rid of 2010 immigration
rename immi_LO4_d_X_o_ndv_10 XXimmi_LO4_d_X_o_ndv_10

// Panel E Column One
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat)  iv(immi_LO4_d_X_o_ndv_*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990)
estimates store TableEighteenE_1
 
// Panel E Column Two
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat)  iv(immi_LO4_d_X_o_ndv_* pcLO4*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990)
estimates store TableEighteenE_2

// Panel E Column Three
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat)  iv(immi_LO4_d_X_o_ndv_* pcLO4*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableEighteenE_3

// Panel E Column Four
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3)  iv(immi_LO4_d_X_o_ndv_* pcLO4*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableEighteenE_4

// Panel E Column Five
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3 dist_Cosine)  iv(immi_LO4_d_X_o_ndv_* pcLO4*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableEighteenE_5

// Panel E Column Six
rename XXimmi_LO4_d_X_o_ndv_10 immi_LO4_d_X_o_ndv_10
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat)  iv(immi_LO4_d_X_o_ndv_* pcLO4*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableEighteenE_6
rename immi_LO4_d_X_o_ndv_10 XXimmi_LO4_d_X_o_ndv_10

// Panel E Column Seven
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_LO4_d_X_o_ndv_* pcLO4*) id1(state_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenE_7

*---------*
* Panel F *
*---------*
cd "${wkdir}"
use "Input/Replication.dta", replace

// Get rid of 2010 immigration
rename immi_LO8_d_X_o_ndv_10 XXimmi_LO8_d_X_o_ndv_10

// Panel F Column One
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat)  iv(immi_LO8_d_X_o_ndv_*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990)
estimates store TableEighteenF_1
 
// Panel F Column Two
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat)  iv(immi_LO8_d_X_o_ndv_* pcLO8*) id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990)
estimates store TableEighteenF_2

// Panel F Column Three
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat)  iv(immi_LO8_d_X_o_ndv_* pcLO8*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableEighteenF_3

// Panel F Column Four
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3)  iv(immi_LO8_d_X_o_ndv_* pcLO8*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableEighteenF_4

// Panel F Column Five
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist dist2 dist3 distance_lat distance_lat2 distance_lat3 dist_Cosine)  iv(immi_LO8_d_X_o_ndv_* pcLO8*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableEighteenF_5

// Panel F Column Six
rename XXimmi_LO8_d_X_o_ndv_10 immi_LO8_d_X_o_ndv_10
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat)  iv(immi_LO8_d_X_o_ndv_* pcLO8*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableEighteenF_6
rename immi_LO8_d_X_o_ndv_10 XXimmi_LO8_d_X_o_ndv_10

// Panel F Column Seven
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_LO8_d_X_o_ndv_* pcLO8*) id1(state_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteenF_7

cd "${wkdir}"
estout TableEighteenD_* using "./Output/AppTable7E.tex", replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

estout TableEighteenA_1 TableEighteenA_2 TableEighteenA_3 TableEighteenA_4 TableEighteenA_5 TableEighteenA_6 TableEighteenA_7 using "./Output/AppTable7B.tex", replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

estout TableEighteenB_* using "./Output/AppTable7C.tex", replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

estout TableEighteenC_* using "./Output/AppTable7D.tex", replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01) label
 
estout TableEighteenE_* using "./Output/AppTable7F.tex", replace style(tex) ///
	keep(log_ancestry_2010) order(log_ancestry_2010) ml( ,none) collabels(, none) ///
	cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0g) labels("N")) ///
	starlevels(* 0.10 ** 0.05 *** 0.01) label
	
estout TableEighteenF_* using "./Output/AppTable7G.tex", replace style(tex) ///
	keep(log_ancestry_2010) order(log_ancestry_2010) ml( ,none) collabels(, none) ///
	cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0g) labels("N")) ///
	starlevels(* 0.10 ** 0.05 *** 0.01) label

********************************************************************************************************
* Appendix Table 8: Basic specification on 2007 FDI data
********************************************************************************************************
cd "${wkdir}"
use "Input/EthnicityDataForRegression_AppTable8.dta", replace

* Get rid of 2010 AND 2000(!) immigration
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10
rename immi_nc_d_X_o_ndv_9 XXimmi_nc_d_X_o_ndv_9

*************************** Panel A ********************************

// Panel A Column One
qui reghdfe country_dummy dist distance_lat (log_ancestry_2000 = immi_nc_d_X_o_ndv_*), ///
absorb(country_code1990 state_county_code_1990) vce(cluster country_code1990) ffirst
mat ffirst = e(first)
local fstat = ffirst[4,1]
estadd scalar kp_fstat `fstat'
estadd scalar criticalv5 = 20.25 // need to be read off manually from regression output
estadd scalar criticalv10 = 11.39 // need to be read off manually from regression output
estimates store TableThreeA_1
 
// Panel A Column Two: complicated FE but no PCs
qui reghdfe country_dummy dist distance_lat (log_ancestry_2000 = immi_nc_d_X_o_ndv_*), ///
absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
mat ffirst = e(first)
local fstat = ffirst[4,1]
estadd scalar kp_fstat `fstat'
estadd scalar criticalv5 = 20.25 // need to be read off manually from regression output
estadd scalar criticalv10 = 11.39 // need to be read off manually from regression output
estimates store TableThreeA_2

// Panel A Column Three: complicated FE + PCs
qui reghdfe country_dummy dist distance_lat (log_ancestry_2000 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
mat ffirst = e(first)
local fstat = ffirst[4,1]
estadd scalar kp_fstat `fstat'
estadd scalar criticalv5 = 21.10 // need to be read off manually from regression output
estadd scalar criticalv10 = 11.52 // need to be read off manually from regression output
estimates store TableThreeA_3

// Panel A Column Four
qui reghdfe country_dummy dist dist2 dist3 distance_lat distance_lat2 distance_lat3 ///
(log_ancestry_2000 = immi_nc_d_X_o_ndv_* pcFour*), absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
mat ffirst = e(first)
local fstat = ffirst[4,1]
estadd scalar kp_fstat `fstat'
estadd scalar criticalv5 = 21.10 // need to be read off manually from regression output
estadd scalar criticalv10 = 11.52 // need to be read off manually from regression output
estimates store TableThreeA_4

// Panel A Column Five
rename XXimmi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_9
qui reghdfe country_dummy dist distance_lat (log_ancestry_2000 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(region_country_code county_continent_code) vce(cluster country_code1990) ffirst
mat ffirst = e(first)
local fstat = ffirst[4,1]
estadd scalar kp_fstat `fstat'
estadd scalar criticalv5 = 21.18 // need to be read off manually from regression output
estadd scalar criticalv10 = 11.52 // need to be read off manually from regression output
estimates store TableThreeA_5
rename immi_nc_d_X_o_ndv_9 XXimmi_nc_d_X_o_ndv_9

// Panel A Column Six
qui reghdfe country_dummy dist distance_lat (log_ancestry_2000 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(state_country_code county_continent_code) vce(cluster country_code1990) ffirst
mat ffirst = e(first)
local fstat = ffirst[4,1]
estadd scalar criticalv5 = 21.10 // need to be read off manually from regression output
estadd scalar criticalv10 = 11.52 // need to be read off manually from regression output
estadd scalar kp_fstat `fstat'
estimates store TableThreeA_6

estout TableThreeA_1 TableThreeA_2 TableThreeA_3 TableThreeA_4 TableThreeA_5 TableThreeA_6 using "./Output/AppTable8A.tex", replace ///
style(tex) keep(log_ancestry_2000) order(log_ancestry_2000) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(kp_fstat criticalv5 criticalv10 N,fmt(%9.2fc %9.2fc %9.2fc %9.0fc) ///
labels("\addlinespace KP F-stat on excluded IV's" "Stock-Yogo 5\% critical values" "Stock-Yogo 10\% critical values" "N")) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

*************************** Table Three Panel B ********************************

// Panel B Column One
qui reghdfe country_dummy log_ancestry_2000 dist distance_lat, ///
absorb(country_code1990 state_county_code_1990) vce(cluster country_code1990)
estimates store TableThreeB_1

// Panel B Column Two, Three & Five
qui reghdfe country_dummy log_ancestry_2000 dist distance_lat, ///
absorb(region_country_code county_continent_code) vce(cluster country_code1990)
estimates store TableThreeB_2
estimates store TableThreeB_3
estimates store TableThreeB_5

// Panel B Column Four 
qui reghdfe country_dummy log_ancestry_2000 dist dist2 dist3 distance_lat distance_lat2 distance_lat3, ///
absorb(region_country_code county_continent_code) vce(cluster country_code1990)
estimates store TableThreeB_4

// Panel B Column Six
qui reghdfe country_dummy log_ancestry_2000 dist distance_lat, ///
absorb(state_country_code county_continent_code) vce(cluster country_code1990)
estimates store TableThreeB_6

la var distance_lat "Latitude Difference"

estout TableThreeB_1 TableThreeB_2 TableThreeB_3 TableThreeB_4 TableThreeB_5 TableThreeB_6 using "./Output/AppTable8B.tex", replace ///
style(tex) keep(log_ancestry_2000) order(log_ancestry_2000) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0fc) ///
labels("\addlinespace N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

********************************************************************************
* Appendix Table 9: Non-linear least squares estimation
********************************************************************************
* Nonlinear Squares Estimation
use "./Input/Replication.dta", replace
nl ( country_dummy = {b0} + {b1 = 1} * log(1 + {c = 1} * 1000 * ancestry_2010) + {b2} * dist + {b3} * distance_lat )
* Write output by hand

*************************************************************************************************************************
* Appendix Table 10: Alternative Functional Forms
*************************************************************************************************************************
use "./Input/Replication.dta", replace

// Get rid of 2010 immigration
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

label variable ancestry_2010 "Ancestry 2010"

* Log Ancestry 2010 (-1 for -inf)
capture drop log_ancestry_2010
gen log_ancestry_2010 = log(ancestry_2010)
replace log_ancestry_2010 = -1 if log_ancestry_2010 == .
label var log_ancestry_2010 "Log Ancestry 2010 (-1 for $-\infty$)"

* (Ancestry 2010)^{1/3}
gen ancestry_2010_third = ancestry_2010^(1/3)
label var ancestry_2010_third "(Ancestry 2010)$^{1/3}$" 

* Column 1
qui ivreg2hdfe, depvar(country_dummy) en(ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteen_1, title(" ")

* Column 2
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteen_2, title(" ")

* Column 3
qui ivreg2hdfe, depvar(country_dummy) en(ancestry_2010_third) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteen_3, title(" ")

* Column 6
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2000) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteen_6, title(" ")

// Get rid of 2000 immigration
rename immi_nc_d_X_o_ndv_9 XXimmi_nc_d_X_o_ndv_9

* Column 5
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_1990) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteen_5, title(" ")

// Get rid of 1990 immigration
rename immi_nc_d_X_o_ndv_8 XXimmi_nc_d_X_o_ndv_8

* Column 4
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_1980) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
estimates store TableEighteen_4, title(" ")

cd "${wkdir}"
estout TableEighteen_1 TableEighteen_2 TableEighteen_3 TableEighteen_4 TableEighteen_5 TableEighteen_6 using ./Output/AppTable10.tex, replace style(tex) keep(ancestry_2010 log_ancestry_2010 ancestry_2010_third log_ancestry_1980 log_ancestry_1990 log_ancestry_2000) order(ancestry_2010 log_ancestry_2010 ancestry_2010_third log_ancestry_1980 log_ancestry_1990 log_ancestry_2000) ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

********************************************************************************
* Appendix Table 11: Vary ownership cutoffs
********************************************************************************
foreach cutoff in G5 G25 G50 S50 {
	cd "${wkdir}"
	use "Input/EthnicityDataForRegression_`cutoff'.dta", replace	

	// Get rid of 2010 immigration
	rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

	*---------------------------------*
	* Run extensive margin regression *
	*---------------------------------*
	qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
		absorb(region_country_code county_continent_code) vce(cluster country_code1990) 
	estimates store TableThreeA_3_`cutoff'
	
	*---------------------------------*
	* Run intensive margin regression *
	*---------------------------------*
	qui ivreg2hdfe, depvar(log_fditotal) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) gmm2s
	estimates store TableSixG_2_`cutoff'
}

*--------------*
* Write output *
*--------------*
cd "${wkdir}"
estout TableThreeA_3_G5 TableThreeA_3_G25 TableThreeA_3_G50 TableThreeA_3_S50 ///
	using "./Output/AppTable11A.tex", replace style(tex) keep(log_ancestry_2010) ///
	order(log_ancestry_2010) ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) ///
	stats(r2 N,fmt(%9.3f %9.0g) labels("\$R^2\$" "N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

estout TableSixG_2_G5 TableSixG_2_G25 TableSixG_2_G50 TableSixG_2_S50 ///
	using "./Output/AppTable11B.tex", replace style(tex) keep(log_ancestry_2010) ///
	order(log_ancestry_2010) ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) ///
	stats(r2 N,fmt(%9.3f %9.0g) labels("\$R^2\$" "N")) starlevels(* 0.10 ** 0.05 *** 0.01) label
	

********************************************************************************
* Appendix Table 12: Alternative Standard Error Specifications
********************************************************************************
*** Note: running hte bootstrap takes a significant amount of time

*------------------------------*
* 1) Pairs cluster bootstrap-t *
*------------------------------*
set seed 654321

use "Input/Replication.dta", replace

// Get rid of 2010 immigration
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

*Run bootstrap
foreach a in robust country county {
	
	if "`a'" == "robust" {
		local se_expression "vce(robust)"
		local sampling ""
	}
	if "`a'" == "country" {
		local se_expression "vce(cluster country_code1990)"
		local sampling ", cluster(country_code1990) idcluster(new_country_code1990)"
	}
	if "`a'" == "county" {
		local se_expression "vce(cluster state_county_code_1990)"
		local sampling ", cluster(state_county_code_1990) idcluster(new_state_county_code_1990)"
	}

	*Run initial regression
	qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), `se_expression' absorb(i.region_country_code i.county_continent_code)
	global w_`a' = _b[log_ancestry_2010] / _se[log_ancestry_2010]
	global b_`a' = _b[log_ancestry_2010]
	global se_`a' = _se[log_ancestry_2010]

	*Prepare output file
	capture postclose bootstrapping
	postfile bootstrapping b_`a' se_`a' t_`a' n_`a' using "Output/BootstrapResults_`a'.dta", replace
	forvalues b = 1/1000 {
		di "Round `b' of 1000..."
		preserve
			keep country_dummy dist distance_lat log_ancestry_2010 immi_nc_d_X_o_ndv_* pcFour* country_code1990 state_county_code_1990 region_country_code county_continent_code
			bsample `sampling' // sample _N times with replacement
			*Regress
			qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), `=regexr("`se_expression'","\(cluster ","(cluster new_")'  absorb(i.region_country_code i.county_continent_code)
			*Generate tstat
			local b = _b[log_ancestry_2010]
			local se = _se[log_ancestry_2010]
			local t = (_b[log_ancestry_2010] - ${b_`a'}) / _se[log_ancestry_2010]
			local nobs = e(N)
			*Add to the bottom of the post file;
			post bootstrapping (`b') (`se') (`t') (`nobs')
		restore
	}
	postclose bootstrapping
}

*Gather results
foreach a in country county robust {

	if "`a'" == "robust" {
		local se_expression "vce(robust)"
	}
	if "`a'" == "country" {
		local se_expression "vce(cluster country_code1990)"
	}
	if "`a'" == "county" {
		local se_expression "vce(cluster state_county_code_1990)"
	}
	
	qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), `se_expression'  absorb(i.region_country_code i.county_continent_code)
	global df_`a' = e(df_r)
	global w_`a' = _b[log_ancestry_2010] / _se[log_ancestry_2010]
	global b_`a' = _b[log_ancestry_2010]
	global se_`a' = _se[log_ancestry_2010]
	
	preserve
		use "Output/BootstrapResults_`a'.dta", clear
		
		*Calculate total rejections
		gen abs_w = abs(t_`a')
		gen reject = (abs_w > abs(${w_`a'}))
		sum reject
		local sumreject = `= r(sum) / 1000'
		sum t_`a'
		di "t = ${w_`a'}"
		
		*Calculate bootstrap-se
		qui su b_`a'
		local mean_coeff = r(mean)
		capture drop x
		gen x = (b_`a' - `mean_coeff')^2
		qui su x
		local se_estimate = sqrt((1/(1000-1)) * r(sum))
		global standard_bse_`a' = sqrt((1/(1000-1)) * r(sum))
		
		di "Bootstrapped P-value using `a' cluster: `sumreject'; se_bse = `se_estimate'"
	restore
}

*---------------------*
* 2) Other clustering *
*---------------------*
* Cluster at state level
qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), vce(cluster state_code_1990) absorb(i.region_country_code i.county_continent_code)
global b_state = _b[log_ancestry_2010]
global se_state = _se[log_ancestry_2010]
global df_state = e(df_r)

* Cluster at continent level
qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), vce(cluster continent_code) absorb(i.region_country_code i.county_continent_code)
global b_continent = _b[log_ancestry_2010]
global se_continent = _se[log_ancestry_2010]
global df_continent = e(df_r)

* Cluster at state-origin level
capture drop state_origin_code
egen state_origin_code = group(state_code_1990 country_code1990)
qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), vce(cluster state_origin_code) absorb(i.region_country_code i.county_continent_code)
global b_statecountry = _b[log_ancestry_2010]
global se_statecountry = _se[log_ancestry_2010]
global df_statecountry = e(df_r)

* Cluster at country + county level
qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), vce(cluster state_county_code_1990 country_code1990) absorb(i.region_country_code i.county_continent_code)
global b_countycountry = _b[log_ancestry_2010]
global se_countycountry = _se[log_ancestry_2010]
global df_countycountry = e(df_r)

* Cluster at country + state level
qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), vce(cluster state_code_1990 country_code1990) absorb(i.region_country_code i.county_continent_code)
global b_stateandcountry = _b[log_ancestry_2010]
global se_stateandcountry = _se[log_ancestry_2010]
global df_stateandcountry = e(df_r)

capture file close texfigure1
file open texfigure1 using "Output/AppTable12.tex", write replace
file write texfigure1 "\begin{tabular}{lcccc}" _n
file write texfigure1 "\hline\hline\addlinespace" _n
file write texfigure1 "\textsc{Panel A: Analytical} \\\addlinespace\hline\addlinespace" _n

getstars "${b_robust}" "${se_robust}" "${df_robust}" "robust"
local stars = r(stars_robust)
file write texfigure1 "Robust & `: di %9.4f ${se_robust}' \\" _n

getstars "${b_county}" "${se_county}" "${df_county}" "county"
local stars = r(stars_county)
file write texfigure1 "Cluster by county & `: di %9.4f ${se_county}' \\" _n

getstars "${b_country}" "${se_country}" "${df_country}" "country"
local stars = r(stars_country)
file write texfigure1 "Cluster by country\$\dagger\$ & `: di %9.4f ${se_country}' \\" _n

getstars "${b_countycountry}" "${se_countycountry}" "${df_countycountry}" "countycountry"
local stars = r(stars_countycountry)
file write texfigure1 "Cluster by county and country & `: di %9.4f ${se_countycountry}' \\" _n

getstars "${b_stateandcountry}" "${se_stateandcountry}" "${df_stateandcountry}" "stateandcountry"
local stars = r(stars_stateandcountry)
file write texfigure1 "Cluster by state and country & `: di %9.4f ${se_stateandcountry}' \\" _n

getstars "${b_state}" "${se_state}" "${df_state}" "state"
local stars = r(stars_state)
file write texfigure1 "Cluster by state & `: di %9.4f ${se_state}' \\" _n

getstars "${b_continent}" "${se_continent}" "${df_continent}" "continent"
local stars = r(stars_continent)
file write texfigure1 "Cluster by continent & `: di %9.4f ${se_continent}' \\" _n

getstars "${b_stateandcountry}" "${se_stateandcountry}" "${df_stateandcountry}" "statecountry"
local stars = r(stars_statecountry)
file write texfigure1 "Cluster by state*country & `: di %9.4f ${se_statecountry}' \\\addlinespace\hline\addlinespace" _n

file write texfigure1 "\textsc{Panel B: Bootstrap} \\\addlinespace\hline\addlinespace" _n

getstars "${b_robust}" "${standard_bse_robust}" "${df_robust}" "standard_bse_robust"
local stars = r(stars_standard_bse_robust)
file write texfigure1 "Robust & `: di %9.4f ${standard_bse_robust}' \\" _n

getstars "${b_county}" "${standard_bse_county}" "${df_county}" "standard_bse_county"
local stars = r(stars_standard_bse_county)
file write texfigure1 "Cluster by county & `: di %9.4f ${standard_bse_county}' \\" _n

getstars "${b_country}" "${standard_bse_country}" "${df_country}" "standard_bse_country"
local stars = r(stars_standard_bse_country)
file write texfigure1 "Cluster by country & `: di %9.4f ${standard_bse_country}' \\\addlinespace" _n

file write texfigure1 "\hline\hline\addlinespace" _n
file write texfigure1 "\end{tabular}"
file close texfigure1

********************************************************************************
* Appendix Table 13: Varying standard specifications
********************************************************************************
use "Input/Replication.dta", replace

*-------------------------------------*
* Panel A: As in main tables (repeat) *
*-------------------------------------*
* 1) Standard specification
preserve
	rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10
	ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) 
	est sto standard_nopcs
	cd "${wkdir}"
restore

* 2) Communist natural experiment
preserve
	*Keep selected countries only
	keep if country_code == 810 | country_code == 156 | country_code == 100 | ///
	country_code == 200 | country_code == 348 | country_code == 616 | ///
	country_code == 642 | country_code == 8 | country_code == 704

	foreach time of numlist 1/10 {
	  gen dummy_`time' = 0
	  local opt 1
	  *** Soviet Union
	  local start = 5-1*(`opt'==2)
	  if (`time' >=`start' & `time' <= 8) {
		replace dummy_`time' = 1 if country_code1990 == 810 
	  }
	  *** China
	  local start= 6+1*(`opt'==1)
	  if (`time' >=`start' & `time' <= 7) {
		replace dummy_`time' = 1 if country_code1990 == 156 
	  }
	  *** Vietnam
	  local start= 7+1*(`opt'==1)
	  local stop= 9-1*(`opt'==1)
	  *local stop= 8 //drop 9th wave
	  if (`time' >= `start' & `time' <= `stop') {
		replace dummy_`time' = 1 if country_code1990 == 704 
	  }
	  *** Eastern Europe
	  local start= 6+1*(`opt'==1)
	  local stop= 8-1*(`opt'==1)
	  if (`time' >= `start' & `time' <= `stop') {
		replace dummy_`time' = 1 if (country_code1990 != 810 & country_code1990 != 156 ///
		& country_code1990 != 704)
	  }
	 // Generate the excluded immigration  
	 gen EX_immi_nc_d_X_o_ndv_`time' = immi_nc_d_X_o_ndv_`time' * dummy_`time'

	 // Generate the included immigration
	 gen IN_immi_nc_d_X_o_ndv_`time' = immi_nc_d_X_o_ndv_`time' * (1-dummy_`time')
	 }

	*All countries together with dest FE
	reghdfe country_dummy dist distance_lat (log_ancestry_2010 = EX_immi_nc_d_X_o_ndv_*), ///
	absorb(i.country_code1990 state_county_code_1990) vce(robust)
	estimates store communist_nopcs
restore

* 3) Intensive margin
preserve
	rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10
	reghdfe log_fditotal dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
	absorb(i.region_country_code i.county_continent_code) vce(cluster country_code1990) estimator(gmm2s) keepsingletons
	estimate store intensive_nopcs
restore

* 4) Migration
preserve
	* Generate orthogonal instruments
	qui reg immi_nc_d_X_o_ndv_2  immi_nc_d_X_o_ndv_1,r
	predict res_2, r
	qui reg immi_nc_d_X_o_ndv_3  immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
	predict res_3, r
	qui reg immi_nc_d_X_o_ndv_4  immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
	predict res_4, r
	qui reg immi_nc_d_X_o_ndv_5  immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
	predict res_5, r
	qui reg immi_nc_d_X_o_ndv_6  immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
	predict res_6, r
	qui reg immi_nc_d_X_o_ndv_7  immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
	predict res_7, r
	qui reg immi_nc_d_X_o_ndv_8  immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
	predict res_8, r
	qui reg immi_nc_d_X_o_ndv_9  immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
	predict res_9, r
	qui reg immi_nc_d_X_o_ndv_10 immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
	predict res_10, r

	* Assign meaningful labels
	foreach time of numlist 2/10 {
	  if `time' == 1 {
		local year = 1880
	  }  
	  else if `time' >= 2 & `time' <= 5 {
		local year = 1880 + `time'*10
	  }
	  else {
		local year = 1910 + `time'*10
	  }  
	  rename immi_nc_d_X_o_ndv_`time' XXimmi_nc_d_X_o_ndv_`time'
	  rename res_`time' immi_nc_d_X_o_ndv_`time' 
	  label variable immi_nc_d_X_o_ndv_`time' "\$I_{o,-r(d)}^{`year'}\frac{I_{-c(o),d}^{`year'}}{I_{-c(o)}^{`year'}}\$"
	}

	rename immi_nc_d_X_o_ndv_10 INimmi_nc_d_X_o_ndv_10
	rename immi_nc_d_X_o_ndv_9 INimmi_nc_d_X_o_ndv_9

	reghdfe immigrants_2000 dist distance_lat INimmi_nc_d_X_o_ndv_9 (log_ancestry_1990 = immi_nc_d_X_o_ndv_*), ///
	absorb(region_country_code county_continent_code) vce(cluster country_code1990)
	estimates store migration_nopcs
restore

*------------------------------------------------------------------------------------*
* Panel B,C,D, E: Cluster SE at county (Panel B), state (Panel C), state and country *
* Panel (D), or county and country (Panel D) *
*------------------------------------------------------------------------------------*
foreach c in county state statecountry countycountry {
	
	if "`c'" == "county" {
		local clcode "county_code_1990"
		local nr "1"
	}
	if "`c'" == "state" {
		local clcode "state_code_1990"
		local nr "2"
	}
	if "`c'" == "statecountry" {
		local clcode "state_code_1990 country_code1990"
		local nr "3"
	}
	if "`c'" == "countycountry" {
		local clcode "state_county_code_1990 country_code1990"
		local nr "4"
	}
	
	* 1) Standard specification
	preserve
		rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

		qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
		absorb(i.region_country_code i.county_continent_code) vce(cluster `clcode')
		estimates store standard_`c'
		
	restore

	* 2) Communist natural experiment
	preserve
	*Keep selected countries only
	keep if country_code == 810 | country_code == 156 | country_code == 100 | ///
	country_code == 200 | country_code == 348 | country_code == 616 | ///
	country_code == 642 | country_code == 8 | country_code == 704

	foreach time of numlist 1/10 {
	  gen dummy_`time' = 0
	  local opt 1
	  *** Soviet Union
	  local start = 5-1*(`opt'==2)
	  if (`time' >=`start' & `time' <= 8) {
		replace dummy_`time' = 1 if country_code1990 == 810 
	  }
	  *** China
	  local start= 6+1*(`opt'==1)
	  if (`time' >=`start' & `time' <= 7) {
		replace dummy_`time' = 1 if country_code1990 == 156 
	  }
	  *** Vietnam
	  local start= 7+1*(`opt'==1)
	  local stop= 9-1*(`opt'==1)
	  *local stop= 8 //drop 9th wave
	  if (`time' >= `start' & `time' <= `stop') {
		replace dummy_`time' = 1 if country_code1990 == 704 
	  }
	  *** Eastern Europe
	  local start= 6+1*(`opt'==1)
	  local stop= 8-1*(`opt'==1)
	  if (`time' >= `start' & `time' <= `stop') {
		replace dummy_`time' = 1 if (country_code1990 != 810 & country_code1990 != 156 ///
		& country_code1990 != 704)
	  }
	 // Generate the excluded immigration  
	 gen EX_immi_nc_d_X_o_ndv_`time' = immi_nc_d_X_o_ndv_`time' * dummy_`time'

	 // Generate the included immigration
	 gen IN_immi_nc_d_X_o_ndv_`time' = immi_nc_d_X_o_ndv_`time' * (1-dummy_`time')
	 }

	*All countries together with dest FE
	qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = EX_immi_nc_d_X_o_ndv_*), ///
	absorb(i.country_code1990 state_county_code_1990) vce(cluster `clcode')
	estimates store communist_`c'	
	restore
	
	
	* 3) Intensive margin
	preserve
		rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10
		qui reghdfe log_fditotal dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
		absorb(i.region_country_code i.county_continent_code) vce(cluster `clcode') estimator(2sls) keepsingletons
		estimates store intensive_`c'
	restore
	*/
	* 4) Migration
	preserve

		* Generate orthogonal instruments
		qui reg immi_nc_d_X_o_ndv_2  immi_nc_d_X_o_ndv_1,r
		predict res_2, r
		qui reg immi_nc_d_X_o_ndv_3  immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
		predict res_3, r
		qui reg immi_nc_d_X_o_ndv_4  immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
		predict res_4, r
		qui reg immi_nc_d_X_o_ndv_5  immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
		predict res_5, r
		qui reg immi_nc_d_X_o_ndv_6  immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
		predict res_6, r
		qui reg immi_nc_d_X_o_ndv_7  immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
		predict res_7, r
		qui reg immi_nc_d_X_o_ndv_8  immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
		predict res_8, r
		qui reg immi_nc_d_X_o_ndv_9  immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
		predict res_9, r
		qui reg immi_nc_d_X_o_ndv_10 immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
		predict res_10, r

		* Assign meaningful labels
		foreach time of numlist 2/10 {
		  if `time' == 1 {
			local year = 1880
		  }  
		  else if `time' >= 2 & `time' <= 5 {
			local year = 1880 + `time'*10
		  }
		  else {
			local year = 1910 + `time'*10
		  }  
		  rename immi_nc_d_X_o_ndv_`time' XXimmi_nc_d_X_o_ndv_`time'
		  rename res_`time' immi_nc_d_X_o_ndv_`time' 
		  label variable immi_nc_d_X_o_ndv_`time' "\$I_{o,-r(d)}^{`year'}\frac{I_{-c(o),d}^{`year'}}{I_{-c(o)}^{`year'}}\$"
		}

		rename immi_nc_d_X_o_ndv_10 INimmi_nc_d_X_o_ndv_10
		rename immi_nc_d_X_o_ndv_9 INimmi_nc_d_X_o_ndv_9
	
		qui reghdfe immigrants_2000 dist distance_lat INimmi_nc_d_X_o_ndv_9 (log_ancestry_1990 = immi_nc_d_X_o_ndv_*), ///
		absorb(region_country_code county_continent_code) vce(cluster `clcode')
		estimates store immigration_`c'
	restore
	
	estout standard_`c' communist_`c' intensive_`c' immigration_`c' ///
	using "./Output/AppendixStandardSpecVariations_PanelB.tex", ///
	cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") ///
	msign(--) style(tex) collabels(,none) mlabels(,none) ///
	substitute(\_ _ 0.305 0.356) starlevel(* 0.10 ** 0.05 *** 0.01) replace ///
	keep(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
	order(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
	varlabels(log_ancestry_2010 "Log Ancestry 2010" ///
	log_ancestry_1990 "Log Ancestry 1990" ///
	INimmi_nc_d_X_o_ndv_9 "\$I_{o,-r(d)}^{2000}\frac{I^{2000}_{-c(o),d}}{I^{2000}_{-c(o)}}\$")
}

*--------------*
* Write output *
*--------------*
*Panel A
estout standard_nopcs communist_nopcs intensive_nopcs migration_nopcs ///
using "./Output/AppTable13A.tex", ///
cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") ///
msign(--) style(tex) collabels(,none) mlabels(,none) ///
substitute(\_ _) starlevel(* 0.10 ** 0.05 *** 0.01) replace ///
keep(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
order(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
varlabels(log_ancestry_2010 "Log Ancestry 2010" ///
log_ancestry_1990 "Log Ancestry 1990" ///
INimmi_nc_d_X_o_ndv_9 "\$I_{o,-r(d)}^{2000}\frac{I^{2000}_{-c(o),d}}{I^{2000}_{-c(o)}}\$")

*Panel B (MODIFYING 2SLS COEFFICIENT MANUALLY TO GMM2)
estout standard_county communist_county intensive_county immigration_county ///
using "./Output/AppTable13B.tex", ///
cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") ///
msign(--) style(tex) collabels(,none) mlabels(,none) ///
substitute(\_ _ 0.305 0.356) starlevel(* 0.10 ** 0.05 *** 0.01) replace ///
keep(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
order(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
varlabels(log_ancestry_2010 "Log Ancestry 2010" ///
log_ancestry_1990 "Log Ancestry 1990" ///
INimmi_nc_d_X_o_ndv_9 "\$I_{o,-r(d)}^{2000}\frac{I^{2000}_{-c(o),d}}{I^{2000}_{-c(o)}}\$")

*Panel C (MODIFYING 2SLS COEFFICIENT MANUALLY TO GMM2)
estout standard_state communist_state intensive_state immigration_state ///
using "./Output/AppTable13C.tex", ///
cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") ///
msign(--) style(tex) collabels(,none) mlabels(,none) ///
substitute(\_ _ 0.305 0.356) starlevel(* 0.10 ** 0.05 *** 0.01) replace ///
keep(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
order(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
varlabels(log_ancestry_2010 "Log Ancestry 2010" ///
log_ancestry_1990 "Log Ancestry 1990" ///
INimmi_nc_d_X_o_ndv_9 "\$I_{o,-r(d)}^{2000}\frac{I^{2000}_{-c(o),d}}{I^{2000}_{-c(o)}}\$")

*Panel E (MODIFYING 2SLS COEFFICIENT MANUALLY TO GMM2)
estout standard_statecountry communist_statecountry intensive_statecountry immigration_statecountry ///
using "./Output/AppTable13D.tex", ///
cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") ///
msign(--) style(tex) collabels(,none) mlabels(,none) ///
substitute(\_ _ 0.305** 0.356***) starlevel(* 0.10 ** 0.05 *** 0.01) replace ///
keep(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
order(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
varlabels(log_ancestry_2010 "Log Ancestry 2010" ///
log_ancestry_1990 "Log Ancestry 1990" ///
INimmi_nc_d_X_o_ndv_9 "\$I_{o,-r(d)}^{2000}\frac{I^{2000}_{-c(o),d}}{I^{2000}_{-c(o)}}\$")

*Panel D (MODIFYING 2SLS COEFFICIENT MANUALLY TO GMM2)
estout standard_countycountry communist_countycountry intensive_countycountry immigration_countycountry ///
using "./Output/AppTable13E.tex", ///
cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") ///
msign(--) style(tex) collabels(,none) mlabels(,none) ///
substitute(\_ _ 0.305** 0.356***) starlevel(* 0.10 ** 0.05 *** 0.01) replace ///
keep(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
order(log_ancestry_2010 log_ancestry_1990 INimmi_nc_d_X_o_ndv_9) ///
varlabels(log_ancestry_2010 "Log Ancestry 2010" ///
log_ancestry_1990 "Log Ancestry 1990" ///
INimmi_nc_d_X_o_ndv_9 "\$I_{o,-r(d)}^{2000}\frac{I^{2000}_{-c(o),d}}{I^{2000}_{-c(o)}}\$")

********************************************************************************
* Appendix Table 15: Five Largest Countries and Counties
********************************************************************************
// Panel A : Top 5 Ancestries
use "./Input/Replication.dta", replace
collapse (sum) ancestry_2010, by(country_code1990)
gsort -ancestry_2010
rename country_code1990 country_code
saveold "./Output/2010TotalAncestry.dta", replace

use "./Input/Replication.dta", replace
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10
qui statsby _b _se df=e(df_r), by(country_code1990) clear: qui ivreg country_dummy distance_lat dist (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), r
rename country_code1990 country_code
merge 1:1 country_code using "./Input/List-UNcountries1990.dta"
keep if _merge == 3
drop country_isocode _merge
merge 1:1 country_code using "./Output/2010TotalAncestry.dta"
keep if _merge == 3
drop _merge
replace country_name = "Britain" if country_code == 826

keep if country_code == 276 | country_code == 826 | country_code == 372 | country_code == 484 | country_code == 380

gsort -ancestry_2010
keep country_name  _b_log_ancestry_2010 _se_log_ancestry_2010 _eq2_df ancestry_2010
order country_name _b_log_ancestry_2010 _se_log_ancestry_2010 _eq2_df ancestry_2010

capture file close texfile
file open texfile using "Output/AppTable15A.tex", write replace
forvalues i = 1/5 {

	*Prepare to write
	local cname = country_name[`i']
	local coeff : di %5.3fc _b_log_ancestry_2010[`i']
	local se : di %5.3fc _se_log_ancestry_2010[`i']
	local df = _eq2_df[`i']
	local nofstars = ///
		(abs(`coeff'/`se') > invttail(`df',0.1/2)) + ///
		(abs(`coeff'/`se') > invttail(`df',0.05/2)) + ///
		(abs(`coeff'/`se') > invttail(`df',0.01/2))
	if `nofstars' == 1 {
		local stars = "*"
	}
	if `nofstars' == 2 {
		local stars = "**"
	}
	if `nofstars' == 3 {
		local stars = "***"
	}
	if `nofstars' == 0 {
		local stars = ""
	}
	
	*Write
	file write texfile " `cname' & `coeff'`stars' \\" _n
	file write texfile "& (`se') \\" _n
}
file close texfile

// Panel B: Largest Five Counties
use "./Input/Replication.dta", replace
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10
qui statsby _b _se df=e(df_r), by(state_county_code_1990) clear: ivreg country_dummy distance_lat dist (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), r
saveold "./Output/FirmRegByCounty.dta", replace

use "./Output/FirmRegByCounty.dta", replace
merge 1:1 state_county_code_1990 using "./Input/US-County-Population-1990.dta"
drop _merge
gsort -population

keep if _n <= 5
gen state_county_name = county_name + ", " + state_name
keep state_county_name  _b_log_ancestry_2010 _se_log_ancestry_2010 _eq2_df population
order state_county_name _b_log_ancestry_2010 _se_log_ancestry_2010 _eq2_df population

capture file close texfile
file open texfile using "Output/AppTable15B.tex", write replace
forvalues i = 1/5 {

	*Prepare to write
	local cname = state_county_name[`i']
	local coeff : di %5.3fc _b_log_ancestry_2010[`i']
	local se : di %5.3fc _se_log_ancestry_2010[`i']
	local df = _eq2_df[`i']
	local nofstars = ///
		(abs(`coeff'/`se') > invttail(`df',0.1/2)) + ///
		(abs(`coeff'/`se') > invttail(`df',0.05/2)) + ///
		(abs(`coeff'/`se') > invttail(`df',0.01/2))
	if `nofstars' == 1 {
		local stars = "*"
	}
	if `nofstars' == 2 {
		local stars = "**"
	}
	if `nofstars' == 3 {
		local stars = "***"
	}
	if `nofstars' == 0 {
		local stars = ""
	}
	
	*Write
	file write texfile " `cname' & `coeff'`stars' \\" _n
	file write texfile "& (`se') \\" _n
}
file close texfile

********************************************************************************
* Appendix Table 16: The Effect of Ancestry on FDI: Country Specific Effects
********************************************************************************
use "./Input/Replication.dta", replace

* Get rid of 2010 immigration for ever
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

preserve
	qui statsby _b _se df=e(df_r), by(country_code1990) clear: qui ivreg country_dummy distance_lat dist (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), r
	compress
	saveold "./Output/EMITdataset_2014fdi_EMByCountry.dta", replace
restore

qui statsby size=r(N), by(country_code1990) clear: count if country_dummy > 0
merge 1:1 country_code1990 using "./Output/EMITdataset_2014fdi_EMByCountry.dta"
drop _merge
replace size = 0 if size == .
rename country_code1990 country_code
merge 1:1 country_code using "./Input/List-UNcountries1990.dta"
keep if _merge == 3
drop _merge
keep size _b_log_ancestry_2010 _se_log_ancestry_2010 _eq2_df country_name country_code
saveold "./Output/EMITdataset_2014fdi_EMByCountry.dta", replace 

*Add ancestry variable
use "./Output/EMITdataset_2014fdi_EMByCountry.dta", replace 
merge 1:1 country_code using "./Output/2010TotalAncestry.dta" /* Created in table "5 Largest Countries and Counties" */
drop _merge
drop if ancestry_2010 < 1

replace country_name = "Britain" if country_code == 826
replace country_name = "Bolivia" if country_code == 68
replace country_name = "Iran" if country_code == 364
replace country_name = "North Korea" if country_code == 408
replace country_name = "South Korea" if country_code == 410
replace country_name = "Lao" if country_code == 418
replace country_name = "Syria" if country_code == 760
replace country_name = "Venezuela" if country_code == 862
replace country_name = "Belgium and Luxembourg" if country_code == 918

*Write
capture drop x
gen x = 1 if size > 0
replace x = 0 if size == 0
gsort -x -_b_log_ancestry_2010
local n = _N
capture file close texfile
file open texfile using "Output/AppTable16.tex", write replace
forvalues i = 1/`n' {

	*Prepare to write
	local cname = country_name[`i']
	local coeff : di %5.3fc _b_log_ancestry_2010[`i']
	local se : di %5.3fc _se_log_ancestry_2010[`i']
	local df = _eq2_df[`i']
	local obs = size[`i']
	local nofstars = ///
		(abs(`coeff'/`se') > invttail(`df',0.1/2)) + ///
		(abs(`coeff'/`se') > invttail(`df',0.05/2)) + ///
		(abs(`coeff'/`se') > invttail(`df',0.01/2))
	if `nofstars' == 1 {
		local stars = "*"
	}
	if `nofstars' == 2 {
		local stars = "**"
	}
	if `nofstars' == 3 {
		local stars = "***"
	}
	if `nofstars' == 0 {
		local stars = ""
	}
	
	*Write
	if `obs' == 0 {
		file write texfile " `cname' & n/a & n/a & `obs' \\" _n
	}
	else {
		file write texfile " `cname' & `coeff'`stars' & (`se') & `obs' \\" _n
	}
}
file close texfile

********************************************************************************
* Appendix Table 17: The Effect of Ancestry on FDI: Sector-Specific Effects
********************************************************************************
* Get sector information
use ".\Input/NAICS.dta", replace 
drop if naicscode == 32 | naicscode == 33 | naicscode == 45 | naicscode == 49  
levelsof (naicscode), local(naicscode)

foreach code of local naicscode {
  
	use "Input/EthnicityDataForRegression_NAICS`code'.dta", replace
		
	* Get rid of 2010 immigration for ever
	rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

	* IV regression 
	qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
	absorb(region_country_code county_continent_code) vce(cluster country_code1990) 
	matrix AppendixTableOne_b_`code' = e(b)
	matrix AppendixTableOne_V_`code' = e(V)
	global AppendixTableOne_df_`code' = e(df_r)

	* Count the number of non-zero observations
	drop if country_dummy == 0
	global AppendixTableOne_N_`code' = _N
}

* Prepare latex output for Appendix Table One
use ".\Input/NAICS.dta", replace 
drop if naicscode == 32 | naicscode == 33 | naicscode == 45 | naicscode == 49  
levelsof (naicscode), local(naicscode)
gen b = .
gen v = .
gen df = .
gen obs = .
foreach a of local naicscode {
	replace b = AppendixTableOne_b_`a'[1,1] if naicscode == `a'
	replace v = AppendixTableOne_V_`a'[1,1] if naicscode == `a'
	replace df = ${AppendixTableOne_df_`a'} if naicscode == `a'
	replace obs = ${AppendixTableOne_N_`a'} if naicscode == `a'
}


capture file close texfile
file open texfile using "Output/AppTable17.tex", write replace
gsort -b
local bign = _N
forvalues i = 1/`bign' {

	*Prepare to write
	local des : di %30s naicsdescription[`i']
	local coeff : di %5.3fc b[`i']
	local se : di %5.3fc sqrt(v[`i'])
	local df = df[`i']
	local obs : di %7.0fc obs[`i']
	local nofstars = ///
		(abs(`coeff'/`se') > invttail(`df',0.1/2)) + ///
		(abs(`coeff'/`se') > invttail(`df',0.05/2)) + ///
		(abs(`coeff'/`se') > invttail(`df',0.01/2))
	if `nofstars' == 1 {
		local stars = "*"
	}
	if `nofstars' == 2 {
		local stars = "**"
	}
	if `nofstars' == 3 {
		local stars = "***"
	}
	if `nofstars' == 0 {
		local stars = ""
	}
	
	*Write
	file write texfile " `des' & `coeff'`stars' & (`se') & `obs' \\" _n
}
file close texfile

********************************************************************************
* Appendix Table 18: Heterogeneous Effects across Sectors and Firms
********************************************************************************

forvalues code = 1(1)6 {
		display(`code')
		
		/*
		"Natural Resources" = 1
		"Manufacturing" = 2
		"Trade" = 3
		"Construction, Real Estate, Accomodation, Recreation" = 4
		"Information, Finance, Management, and other Services" = 5
		"Health, Education, Utilities, and other Public Services" = 6
		*/

		* Open data file
		cd "${wkdir}"
		use "Input/EthnicityDataForRegression_AppTable18_`code'.dta", replace

		* Get rid of 2010 immigration for ever
		rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

		* IV regression 
		qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
		absorb(region_country_code county_continent_code) vce(cluster country_code1990) 
		matrix TableTwelveA_b_`code' = e(b)
		matrix TableTwelveA_V_`code' = e(V)
		global TableTwelveA_df_`code' = e(df_r)

		* Get the mean of FDI dummy
		*qui sum country_dummy
		*global FDIMean_`code' = r(mean)

		* Count the number of non-zero observations
		drop if country_dummy == 0
		global TableTwelveA_N_`code' = _N
}


capture file close texfile
file open texfile using "Output/AppTable18A.tex", write replace
getcoeffs "2" "TableTwelveA"
file write texfile "Manufacturing & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\" _n
getcoeffs "3" "TableTwelveA"
file write texfile "Trade & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\" _n
getcoeffs "5" "TableTwelveA"
file write texfile "Information, Finance, Management, and other Services & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\" _n
getcoeffs "4" "TableTwelveA"
file write texfile "Construction, Real Estate, Accomodation, Recreation & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\" _n
getcoeffs "6" "TableTwelveA"
file write texfile "Health, Education, Utilities, and other Public Services & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\" _n
getcoeffs "1" "TableTwelveA"
file write texfile "Natural Resources & `r(coeff)'`r(stars)' \\" _n
file write texfile "& (`r(se)') \\" _n
file close texfile

*************************************
*Panel B: Small vs Large Firm Size
*************************************

*** Large Firms
use "./Input/EthnicityFirmDataForRegression_AppTable18B1.dta", replace

rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

* Run standard specification regression
qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(region_country_code county_continent_code) vce(cluster country_code1990) 
matrix TableTwelveC_b_2 = e(b)
matrix TableTwelveC_V_2 = e(V)
global TableTwelveC_df_2 = e(df_r)
  
* Count the number of non-zero observations
drop if country_dummy == 0
global TableTwelveC_N_2 = _N

*** Small Firms
use "./Input/EthnicityFirmDataForRegression_AppTable18B2.dta", replace

rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

* Run standard specification regression
qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(region_country_code county_continent_code) vce(cluster country_code1990) 
matrix TableTwelveC_b_1 = e(b)
matrix TableTwelveC_V_1 = e(V)
global TableTwelveC_df_1 = e(df_r)
  
* Count the number of non-zero observations
drop if country_dummy == 0
global TableTwelveC_N_1 = _N

*** Compare ancestry coefficients using statistical test
use "./Input/EthnicityFirmDataForRegression_AppTable18B2.dta", replace

rename country_dummy country_dummy_small
saveold "./Output/SmallSizeData.dta", replace

use "./Input/EthnicityFirmDataForRegression_AppTable18B1.dta", replace
keep state_county_code_1990 country_code1990 country_dummy
rename country_dummy country_dummy_large 
merge 1:1 state_county_code_1990 country_code1990 using "./Output/SmallSizeData.dta"
drop _merge

// Get rid of 2010 immigration
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

*Orthogonalize the variables with iterated FWL
cd "${wkdir}"
hdfe country_dummy_small country_dummy_large log_ancestry_2010 dist distance_lat immi_nc_d_X_o_ndv_* pcFour*, absorb(region_country_code county_continent_code) generate(orth_) clusterv(country_code1990)

*Run both iv equations and perform cross equation test
gmm (eq1: orth_country_dummy_large - {b1}*orth_log_ancestry_2010 - {b2}*orth_dist - {b3}*orth_distance_lat - {b0}) ///
	(eq2: orth_country_dummy_small - {c1}*orth_log_ancestry_2010 - {c2}*orth_dist - {c3}*orth_distance_lat - {c0}), ///
	instruments(eq1: orth_dist orth_distance_lat orth_immi_nc_d_X_o_ndv_* orth_pcFour*) ///
	instruments(eq2: orth_dist orth_distance_lat orth_immi_nc_d_X_o_ndv_* orth_pcFour*) ///
	onestep winitial(unadjusted, indep) vce(cluster country_code1990)
estimates store GMM

*Save test for equlity of coefficients
test [b1]_cons==[c1]_cons
global chi2_C = r(p)

capture file close texfile
file open texfile using "Output/AppTable18B.tex", write replace
getcoeffs "2" "TableTwelveC" /* large size */
file write texfile "Above Median & `r(coeff)'`r(stars)' & `r(N)' \\" _n
file write texfile "& (`r(se)') & \\" _n
getcoeffs "1" "TableTwelveC" /* small size */
file write texfile "Below Median & `r(coeff)'`r(stars)' & `r(N)' \\" _n
file write texfile "& (`r(se)') & \\" _n
file write texfile "\$p\$-value of \$\chi^2\$ test, H\$_{0}\$: equality of coefficients & `: di %5.3fc ${chi2_C}' & \\" _n
file close texfile


*************************************************************************************************************************
* Appendix Table 19: The effect of ancestry on the intensive margin of FDI
*************************************************************************************************************************
use "Input/Replication.dta", replace

rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

*----------------------------*
* Without Heckman Correction *
*----------------------------*
// Panel A: Log total number of FDI relationships
* OLS 
qui reghdfe log_fditotal log_ancestry_2010 dist distance_lat, ///
absorb(i.region_country_code i.county_continent_code) vce(cluster i.country_code1990) keepsingletons
estimates store TableSixA_1

* IV 
qui reghdfe log_fditotal dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(i.region_country_code i.county_continent_code) vce(cluster country_code1990) estimator(gmm2s) keepsingletons
estimates store TableSixA_2

* IV 
qui reghdfe log_fditotal dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(i.country_code1990 i.state_county_code_1990) vce(cluster country_code1990) estimator(gmm2s) keepsingletons
estimates store TableSixA_3


// Panel B: Log number of USfirms in d that have at least one shareholder in o
* OLS 
qui reghdfe log_ussubsidiarycount log_ancestry_2010 dist distance_lat, ///
absorb(i.region_country_code i.county_continent_code) vce(cluster country_code1990) keepsingletons
estimates store TableSixB_1

* IV 
qui reghdfe log_ussubsidiarycount dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(i.region_country_code i.county_continent_code) vce(cluster country_code1990) estimator(gmm2s) keepsingletons
estimates store TableSixB_2

* IV 
qui reghdfe log_ussubsidiarycount dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(i.country_code1990 i.state_county_code_1990) vce(cluster country_code1990) estimator(gmm2s) keepsingletons
estimates store TableSixB_3

// Panel C: Log Number of workers employed in d by subsidiaries of firms in o
* OLS 
qui reghdfe log_ussubsidiaryemployees log_ancestry_2010 dist distance_lat, ///
absorb(i.region_country_code i.county_continent_code) vce(cluster country_code1990) keepsingletons
estimates store TableSixD_1

* IV 
qui reghdfe log_ussubsidiaryemployees dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(i.region_country_code i.county_continent_code) vce(cluster country_code1990) estimator(gmm2s) keepsingletons
estimates store TableSixD_2

* IV 
qui reghdfe log_ussubsidiaryemployees dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(i.country_code1990 i.state_county_code_1990) vce(cluster country_code1990) estimator(gmm2s) keepsingletons
estimates store TableSixD_3

*-------------------------*
* With Heckman Correction *
*-------------------------*
// Mark countries with zero FDI (set A)
bysort country_code1990: egen country_fdi = total(country_dummy)
gen setA = 0
replace setA = 1 if country_fdi == 0

// Mark counties with zero FDI (set B)
bysort state_county_code_1990: egen county_fdi = total(country_dummy)
gen setB = 0
replace setB = 1 if county_fdi == 0


* Generate inverse-mills ratios
qui ivprobit subsidiary_country_dummy  dist distance_lat i.country_code1990 i.state_county_code_1990 (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*) if setA == 0 & setB == 0, twostep
qui predict sub_prob_IV_hat, xb
qui gen sub_imratio_IV   = normalden(sub_prob_IV_hat) / normal(sub_prob_IV_hat)

qui ivprobit shareholder_country_dummy dist distance_lat i.country_code1990 i.state_county_code_1990 (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*) if setA == 0 & setB == 0, twostep
qui predict share_prob_IV_hat, xb
qui gen share_imratio_IV = normalden(share_prob_IV_hat) / normal(share_prob_IV_hat)

qui ivprobit country_dummy dist distance_lat i.country_code1990 i.state_county_code_1990 (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*) if setA == 0 & setB == 0, twostep
qui predict fdi_prob_IV_hat, xb
qui gen fdi_imratio_IV = normalden(fdi_prob_IV_hat) / normal(fdi_prob_IV_hat)


// Panel A: Log total number of FDI relationships
qui reghdfe log_fditotal dist distance_lat fdi_imratio_IV (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(i.country_code1990 i.state_county_code_1990) vce(cluster country_code1990) keepsingletons
estimates store TableSixA_4

// Panels B and C
local num = 1
foreach variable of varlist log_ussubsidiarycount log_ussubsidiaryemployees {

  qui reghdfe `variable' dist distance_lat share_imratio_IV (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
  absorb(i.country_code1990 i.state_county_code_1990) vce(cluster country_code1990) keepsingletons
  estimates store TableSix_`num'

  local num = `num' + 1
}

*--------------*
* Write output *
*--------------*

estout TableSixA_* using "Output/AppTable19A.tex", ///
replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ml( ,none) ///
collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0fc) labels("N")) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

estout TableSixB_* TableSix_1 using "Output/AppTable19B.tex", ///
replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ml( ,none) ///
collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0fc) labels("N")) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

estout TableSixD_* TableSix_2 using "Output/AppTable19C.tex", ///
replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ml( ,none) ///
collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0fc) labels("N")) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

**************************************************************************************************************************
* Appendix Table 20: Intensive Margin Of Trade & Investment Data (State Level)
**************************************************************************************************************************
est clear
use "Input/Replication_State.dta", replace

// Exclude 2010 push and pull
rename immi_nc_s_X_o_ndv_10 XXimmi_nc_s_X_o_ndv_10

*-------------------------------------------*
* Panel A: Log total # of FDI relationships *
*-------------------------------------------*
* OLS: control for ancestry, with Heckman correction
qui probit country_dummy dist distance_lat i.country_code1990 log_ancestry_2010
capture drop fdi_prob
capture drop fdi_imratio
qui predict fdi_prob, pr
gen fdi_imratio = normalden(invnormal(fdi_prob)) / fdi_prob
qui reghdfe log_fditotal log_ancestry_2010 dist distance_lat fdi_imratio, absorb(i.country_code1990) vce(cluster country_code1990 state_code)
estimates store fdi_1

* IV:  control for ancestry, with Heckman correction, no destination FE
qui ivprobit country_dummy dist distance_lat i.country_code1990 (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*)
capture drop fdi_prob
capture drop fdi_imratio
qui predict fdi_prob, pr
gen fdi_imratio = normalden(invnormal(fdi_prob)) / fdi_prob
qui reghdfe log_fditotal dist distance_lat fdi_imratio (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*), absorb(i.country_code1990) vce(cluster country_code1990 state_code) ffirst
estimates store fdi_2

* IV:  control for ancestry, with Heckman correction
qui ivprobit country_dummy dist distance_lat i.state_code i.country_code1990 (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*)
capture drop fdi_prob_IV_hat1
capture drop fdi_imratio_IV1
qui predict fdi_prob_IV_hat1, pr
gen fdi_imratio_IV1 = normalden(invnormal(fdi_prob_IV_hat1)) / fdi_prob_IV_hat1
qui reghdfe log_fditotal dist distance_lat fdi_imratio_IV1 (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*), absorb(i.state_code i.country_code1990) vce(cluster country_code1990 state_code) ffirst
estimates store fdi_3

*--------------------------------*
* Panel B: Log aggregate exports *
*--------------------------------*
* OLS: control for ancestry, no destination FE, with Heckman correction
qui probit export_dummy dist distance_lat i.country_code log_ancestry_2010
capture drop export_prob
capture drop export_imratio
qui predict export_prob, pr
gen export_imratio = normalden(invnormal(export_prob)) / export_prob
qui reghdfe log_y2011_export log_ancestry_2010 dist distance_lat export_imratio, absorb(i.country_code) vce(cluster country_code1990 state_code)
estimates store exports_1

* IV:  control for ancestry, with Heckman correction, no destination FE
qui ivprobit export_dummy dist distance_lat i.country_code (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*)
capture drop export_prob
capture drop export_imratio
qui predict export_prob, pr
gen export_imratio = normalden(invnormal(export_prob)) / export_prob
qui reghdfe log_y2011_export dist distance_lat export_imratio (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*), absorb(i.country_code) vce(cluster country_code1990 state_code) ffirst
estimates store exports_2

* IV:  control for ancestry, with Heckman correction
qui ivprobit export_dummy dist distance_lat i.state_code i.country_code (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*)
capture drop export_prob_IV_hat1
capture drop export_imratio_IV1
qui predict export_prob_IV_hat1, pr
gen export_imratio_IV1 = normalden(invnormal(export_prob_IV_hat1)) / export_prob_IV_hat1
qui reghdfe log_y2011_export dist distance_lat export_imratio_IV1 (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*), absorb(i.state_code i.country_code) vce(cluster country_code1990 state_code) ffirst
estimates store exports_3

*--------------------------------*
* Panel C: Log aggregate imports *
*--------------------------------*
* OLS: control for ancestry, with Heckman correction
qui probit import_dummy dist distance_lat i.country_code log_ancestry_2010
capture drop import_prob
capture drop import_imratio
qui predict import_prob, pr
gen import_imratio = normalden(invnormal(import_prob)) / import_prob
qui reghdfe log_y2011_import log_ancestry_2010 dist distance_lat import_imratio, absorb(i.country_code) vce(cluster country_code1990 state_code)
estimates store imports_1

* IV:  control for ancestry, with Heckman correction, no destination FE
qui ivprobit import_dummy dist distance_lat i.country_code (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*)
capture drop import_prob
capture drop import_imratio
qui predict import_prob, pr
gen import_imratio = normalden(invnormal(import_prob)) / import_prob
qui reghdfe log_y2011_import dist distance_lat import_imratio (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*), absorb(i.country_code) vce(cluster country_code1990 state_code) ffirst
estimates store imports_2

* IV:  control for ancestry, with Heckman correction
qui ivprobit import_dummy dist distance_lat i.state_code i.country_code (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*)
capture drop import_prob_IV_hat1
capture drop import_imratio_IV1
qui predict import_prob_IV_hat1, pr
gen import_imratio_IV1 = normalden(invnormal(import_prob_IV_hat1)) / import_prob_IV_hat1
qui reghdfe log_y2011_import dist distance_lat import_imratio_IV1 (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*), absorb(i.state_code i.country_code) vce(cluster country_code1990 state_code) ffirst
estimates store imports_3

*---------------------------------*
* Panel D: Log exports to Vietnam *
*---------------------------------*
preserve
	keep if country_code == 704

	* OLS: control for ancestry, no Heckman correction
	qui reg log_y2011_export log_ancestry_2010 dist distance_lat, vce(robust)
	estimates store vietnam_1

	* IV:  control for ancestry, no Heckman correction, no destination FE
	qui ivreg2 log_y2011_export dist distance_lat (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*), robust
	estimates store vietnam_2
restore

*-------------------------------*
* Panel E: Log exports to Japan *
*-------------------------------*
preserve 
	keep if country_code == 392

	* OLS: control for ancestry, no Heckman correction
	reg log_y2011_export log_ancestry_2010 dist distance_lat, vce(robust)
	estimates store japan_1

	* IV:  control for ancestry, no Heckman correction, no destination FE
	ivreg2 log_y2011_export dist distance_lat (log_ancestry_2010 = immi_nc_s_X_o_ndv_* pcFour*), robust
	estimates store japan_2
restore

*--------------*
* Write output *
*--------------*
estout fdi_* using "Output/AppTable20A.tex", ///
replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) ///
stats(r2 N,fmt(%9.3f %9.0fc) ///
labels("\addlinespace\$R^2\$" "N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

estout exports_* using "Output/AppTable20B.tex", ///
replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) ///
stats(r2 N,fmt(%9.3f %9.0fc) ///
labels("\addlinespace\$R^2\$" "N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

estout imports_* using "Output/AppTable20C.tex", ///
replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) ///
stats(r2 N,fmt(%9.3f %9.0fc) ///
labels("\addlinespace\$R^2\$" "N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

estout vietnam_* using "Output/AppTable20D.tex", ///
replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) ///
stats(r2 N,fmt(%9.3f %9.0fc) ///
labels("\addlinespace\$R^2\$" "N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

estout japan_* using "Output/AppTable20E.tex", ///
replace style(tex) keep(log_ancestry_2010) order(log_ancestry_2010) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) ///
stats(r2 N,fmt(%9.3f %9.0fc) ///
labels("\addlinespace\$R^2\$" "N")) starlevels(* 0.10 ** 0.05 *** 0.01) label


**************************************************************************************************************************
* Appendix Table 21: Counterfactual Experiment: A Gold Rush in Los Angeles in 1880
**************************************************************************************************************************
use "Input/Replication.dta", replace

xtset county_continent_code country_code1990

capture drop immi_nc_d_X_o_ndv_res_* pcFour_res*
capture drop immi_nc_d_X_o_ndv_10

* Generate orthogonalzied interactions
qui reg immi_nc_d_X_o_ndv_2  immi_nc_d_X_o_ndv_1,r
predict res_2, r
qui reg immi_nc_d_X_o_ndv_3  immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_3, r
qui reg immi_nc_d_X_o_ndv_4  immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_4, r
qui reg immi_nc_d_X_o_ndv_5  immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_5, r
qui reg immi_nc_d_X_o_ndv_6  immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_6, r
qui reg immi_nc_d_X_o_ndv_7  immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_7, r
qui reg immi_nc_d_X_o_ndv_8  immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_8, r
qui reg immi_nc_d_X_o_ndv_9  immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_9, r

* Mark countries with zero FDI (set A)
bysort country_code1990: egen country_fdi = total(country_dummy)
gen setA = 0
replace setA = 1 if country_fdi == 0

* Mark counties with zero FDI (set B)
bysort state_county_code_1990: egen county_fdi = total(country_dummy)
gen setB = 0
replace setB = 1 if county_fdi == 0

* ------------------------------------------------------------------------------
* Run RF and IV regressions
* ------------------------------------------------------------------------------

foreach variable of varlist log_ancestry_2010 ancestry_2010 log_fditotal {
  // Run linear regression on full panel
  qui reg2hdfe `variable' immi_nc_d_X_o_ndv_1 res_* dist distance_lat, id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
  matrix `variable'_rf_coef = e(b)
  display(`variable'_rf_coef[1,1])
}

ivreg2hdfe, depvar(log_fditotal) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_1 res_*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) gmm2s
matrix log_fditotal_iv_coef = e(b)
display(log_fditotal_iv_coef[1,1])

* ------------------------------------------------------------------------------
* Generate changes in predicted variable
* ------------------------------------------------------------------------------

* Modify I_{-c,d} for LA county 
gen cimmi_nc_d_X_o_ndv_1 = immi_nc_d_X_o_ndv_1 * 5 if state_county_code_1990 == 60370

* Counterfactual for RF exercise
foreach variable of varlist log_ancestry_2010 ancestry_2010 log_fditotal {
  qui gen `variable'_rf_delta = `variable'_rf_coef[1,1] * (cimmi_nc_d_X_o_ndv_1 - immi_nc_d_X_o_ndv_1)
}

* Counterfactual for IV exercise
gen log_fditotal_iv_delta = log_fditotal_iv_coef[1,1] * log_ancestry_2010_rf_delta
cd "${wkdir}"
save "Output/PullFactorCounterfactuals.dta", replace

* ------------------------------------------------------------------------------
* Prepare Output
* ------------------------------------------------------------------------------

use "Output/PullFactorCounterfactuals.dta", clear

keep if state_county_code_1990 == 60370
replace country_name = "UK" if country_name == "United Kingdom of Great Britain and Northern Ireland"

keep  country_name country_code1990 ancestry_2010 log_fditotal ancestry_2010_rf_delta log_fditotal_rf_delta log_fditotal_iv_delta 
order country_name country_code1990 ancestry_2010 log_fditotal ancestry_2010_rf_delta log_fditotal_rf_delta log_fditotal_iv_delta 
	  
gen     fditotal      = int(exp(log_fditotal))
replace fditotal      = 0 if fditotal == .
gen     fdi_rf_change          = (exp(log_fditotal_rf_delta)-1)*100
replace fdi_rf_change          = 0 if fdi_rf_change == .
gen     fdi_iv_change          = (exp(log_fditotal_iv_delta)-1)*100
replace fdi_iv_change          = 0 if fdi_iv_change == .

replace ancestry_2010 = ancestry_2010 * 1000
replace ancestry_2010_rf_delta = ancestry_2010_rf_delta * 1000

gsort -ancestry_2010_rf_delta
keep if _n <= 10

keep  country_name ancestry_2010 fditotal fdi_iv_change ancestry_2010_rf_delta
order country_name ancestry_2010 fditotal ancestry_2010_rf_delta fdi_iv_change

format ancestry_2010 fditotal ancestry_2010_rf_delta %9.0fc
format fdi_iv_change %9.2f
tostring fdi_iv_change, replace force use
replace fdi_iv_change = "+" + fdi_iv_change
tostring ancestry_2010_rf_delta, replace force use
replace ancestry_2010_rf_delta = "+" + ancestry_2010_rf_delta
*drop fdi_iv_change ancestry_2010_rf_delta // sap columns 3 and 4
listtex * using "Output/Table21.tex", replace rstyle(tabular) 

********************************************************************************
* Appendix Table 22: Information Demand and Language - Top 5 Search Terms
********************************************************************************

*--------------------------------------*
* Create table with top 5 search terms *
*--------------------------------------*
capture file close texfile
file open texfile using "Output/AppTable21.tex", write replace
file write texfile "\begin{tabular}{cc}\hline\hline\addlinespace" _n
file write texfile "Germany & Italy \\\hline\addlinespace" _n
file write texfile "\multicolumn{2}{c}{\textsc{Politicians}}\\\hline\addlinespace" _n
file write texfile "Angela Merkel & Aldo Moro\\" _n // number 1 politicians
file write texfile "Helmut Kohl & Benito Mussolini\\" _n // number 2 politicians
file write texfile "Willy Brandt & Alessandra Mussolini\\" _n // number 3 politicians
file write texfile "Joseph Goebbels & Amintore Fanfani\\" _n // number 4 politicians
file write texfile "Karl Marx & Angelino Alfano\\\addlinespace\hline\addlinespace" _n // number 5 politicians
file write texfile "\multicolumn{2}{c}{\textsc{Actors}}\\\hline\addlinespace" _n
file write texfile `"J\"{u}rgen Prochnow & Isabella Rossellini\\"' _n // number 1 actors
file write texfile "Til Schweiger & Robert De Niro\\" _n // number 2 actors
file write texfile "Franka Potente & John Turturro\\" _n // number 3 actors
file write texfile "Udo Kier & Roberto Rossellini\\" _n // number 4 actors
file write texfile `"Daniel Br\"{u}hl & Roberto Benigni\\\addlinespace\hline\addlinespace"' _n // number 5 actors
file write texfile "\multicolumn{2}{c}{\textsc{Athletes}}\\\hline\addlinespace" _n
file write texfile "Katarina Witt & Mario Andretti\\" // number 1 athletes
file write texfile "Dirk Nowitzki & Armin Zoggeler\\" // number 2 athletes
file write texfile "Boris Becker & Roberto Baggio\\" // number 3 athletes
file write texfile "Steffi Graf & Andrea Barzagli\\" // number 4 athletes
file write texfile "Franz Beckenbauer & Gerhard Plankensteiner\\\addlinespace\hline\addlinespace" // number 5 athletes
file write texfile "\multicolumn{2}{c}{\textsc{Musicians}}\\\hline\addlinespace" _n
file write texfile "Ludwig van Beethoven & Antonio Vivaldi\\" // number 1 musicians
file write texfile "Nena & Gioachino Rossini\\" // number 2 musicians
file write texfile "Johann Sebastian Bach & Giacomo Puccini\\" // number 3 musicians
file write texfile "Nina Hagen & Ennio Morricone\\" // number 4 musicians
file write texfile "Felix Mendelssohn & Luciano Pavarotti\\\addlinespace\hline\hline" _n // number 5 musician
file write texfile "\end{tabular}" _n
file close texfile

********************************************************************************
* Appendix Table 23: The Effect of Ancestry on Language: Country Specific Effects
********************************************************************************
use "Input/EthnicityDataForRegression_Table8.dta", replace

* Get rid of 2010 immigration forever
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

*Save countries with largest language of origin
preserve
	keep if actual_language != .
	collapse (sum) language_domestic (first) actual_language_string, by(actual_language)
	gsort -language_domestic
	save "Output/2010TotalLanguage.dta", replace
restore

*Run country-by-country regressions
preserve
	statsby _b _se df=`=e(N)-e(df_m)', by(actual_language) clear: qui ivregress 2sls language_domestic distance_lat dist (ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), robust
	compress
	save "Output/EMITdataset_2010language_EMByCountry.dta", replace
restore

*Count by language
preserve
	qui statsby nonzero_obs=r(N), by(actual_language) clear: count if language_domestic > 0 & language_domestic != .
	compress
	tempfile a
	save "`a'", replace
restore
preserve
	qui statsby nobs=r(N), by(actual_language) clear: count if language_domestic != .
	merge 1:1 actual_language using "`a'"
	drop _merge
	merge 1:1 actual_language using "Output/EMITdataset_2010language_EMByCountry.dta"
	drop _merge
	keep _b_ancestry_2010 _se_ancestry_2010 _eq2_df actual_language nonzero_obs nobs
	
	*Add total number of speakers
	merge 1:1 actual_language using "Output/2010TotalLanguage.dta"
	drop _merge
	
	*Identify missing
	gen missing = 1 if _b_ancestry_2010 == .

	*Write
	gsort -_b_ancestry_2010 // sort by size of coefficient
	local n = _N
	capture file close texfile
	file open texfile using "Output/AppTable23.tex", write replace
	forvalues i = 1/`n' {

		*Prepare to write
		local cname = actual_language_string[`i']
		local coeff : di %5.3fc _b_ancestry_2010[`i']
		local se : di %5.3fc _se_ancestry_2010[`i']
		local df = _eq2_df[`i']
		local obs : di %9.0fc nobs[`i']
		local nozeroobs : di %9.0fc nonzero_obs[`i']
		local nofstars = ///
			(abs(`coeff'/`se') > invttail(`df',0.1/2)) + ///
			(abs(`coeff'/`se') > invttail(`df',0.05/2)) + ///
			(abs(`coeff'/`se') > invttail(`df',0.01/2))
		if `nofstars' == 1 {
			local stars = "*"
		}
		if `nofstars' == 2 {
			local stars = "**"
		}
		if `nofstars' == 3 {
			local stars = "***"
		}
		if `nofstars' == 0 {
			local stars = ""
		}
		
		*Write
		if missing[`i'] == 1 {
			file write texfile " `cname' & n/a & n/a & `obs' & `nozeroobs' \\" _n
		}
		else {
			file write texfile " `cname' & `coeff'`stars' & (`se') & `obs' & `nozeroobs' \\" _n
		}
	}
	file close texfile
restore

********************************************************************************
* Appendix Table 24: Variations of the Simple Specification *
********************************************************************************
est clear
*----------------------------------*
* County-country level regressions *
*----------------------------------*
use "Input/EthnicityDataForRegression_AppTable24.dta", replace

*Simple specification
qui reghdfe country_dummy dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(country_code1990 county_code_1990) vce(cluster country_code1990) 
est sto a

*Simple specification, controling for rank correlation
qui reghdfe country_dummy corr_rank dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(country_code1990 county_code_1990) vce(cluster country_code1990) 
est sto b

*Simple specificaiton, controling for cosine correlation
qui reghdfe country_dummy corr_cos dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(country_code1990 county_code_1990) vce(cluster country_code1990) 
est sto c

*Simple specification, controling for log_language_all
qui reghdfe country_dummy log_language_all dist distance_lat (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), ///
absorb(country_code1990 county_code_1990) vce(cluster country_code1990) 
est sto d

*-------------------------------*
* DMA-country level regressions *
*-------------------------------*
* Standard specification + control for index
use "Input/EMIT_DMA_Table1and8.dta", clear

la var index_std "Information Demand Index"
ren log_ancestry2010 log_ancestry_2010

*Standard specification, controling for overall index
qui reghdfe country_dummy dist distance_lat index_std (log_ancestry_2010 = immi_nc_d_X_o_nd_* pcThree*) ///
, vce(cluster country_code) absorb(i.country_code i.dma)
est sto e

*Write output
estout a b c d e using "Output/AppTable24.tex", ///
replace style(tex) keep(log_ancestry_2010 corr_rank corr_cos log_language_all index_std) ml( ,none) collabels(, none) ///
stats(N,fmt(%9.0fc) labels("\$N\$")) cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) ///
varlabels(log_ancestry_2010 "Log Ancestry 2010" ///
corr_rank "Sector Similarity (Rank Correlation)" corr_cos "Sector Similarity (Cosine Correlation)" ///
log_language_all "Log \# of residents in \$d\$ that speak language of \$o\$ at home" ///
index_std "Information Demand Index (standardized)")

********************************************************************************
* Appendix Table 25: Generational Effects
********************************************************************************
use "Input/EthnicityDataForRegression_AppTable25.dta", replace

* Drop 2010 immigration interactions
drop immi_nc_d_X_o_ndv_10

* Column One
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableEight_1

* Column Two
qui ivreg2hdfe, depvar(country_dummy) en(log_cum_immigrants_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) gmm2s
estimates store TableEight_2

* Column Three
qui reg2hdfe country_dummy log_ancestry_2010 log_cum_immigrants_2010 dist distance_lat, id1(region_country_code) id2(county_continent_code) cluster(country_code1990)
estimates store TableEight_3

* Column Four  
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010 log_cum_immigrants_2010) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) gmm2s 
* READ FROM OUTPUT (INCLUDED IN TABLE NOTE): KPLM 18.211, p-value of .1497
estimates store TableEight_4

* Column Five
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010_2nd) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) gmm2s 
estimates store TableEight_5

* Column Six
qui ivreg2hdfe, depvar(country_dummy) en(log_ancestry_2010 log_ancestry_2010_2nd) ex(dist distance_lat) iv(immi_nc_d_X_o_ndv_* pcFour*) id1(region_country_code) id2(county_continent_code) cluster(country_code1990) gmm2s 
* READ FROM OUTPUT (INCLUDED IN TABLE NOTE): KPLM 29.043, p-value of .0065
estimates store TableEight_6

*--------------*
* Write output *
*--------------*
cd "${wkdir}"
estout TableEight_* using "Output/AppTable25.tex", replace style(tex) ///
keep(log_ancestry_2010 log_cum_immigrants_2010 log_ancestry_2010_2nd) ///
order(log_ancestry_2010 log_cum_immigrants_2010 log_ancestry_2010_2nd) ///
ml( ,none) collabels(, none) cells(b(star fmt(%9.3f)) se(par)) stats(N,fmt(%9.0fc) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01) label

*****************************************************************************************************************
*****************************************************************************************************************
*********************************** FIGURES START ************************************************************
*****************************************************************************************************************
*****************************************************************************************************************

***************************************************************************************************************************
* Figure 3: Migrants and Ancestors: The Case of Non-Europeans, Italy and Germany 
***************************************************************************************************************************
pause on
foreach a in /*immigrants*/ immigrantsnoneurope /*ancestryGER ancestryITA*/ {

	if "`a'" == "immigrants" {
		local filename "TotalImmigrants"
	}
	if "`a'" == "immigrantsnoneurope" {
		local filename "NonEuropeanImmigrants"
	}
	if "`a'" == "ancestryGER" {
		local filename "GermanAncestry"
	}
	if "`a'" == "ancestryITA" {
		local filename "ItalianAncestry"
	}
	
	use "./Input/EthnicityDataForRegression_Figure2and3.dta", clear
	
	*Gen fips code (need to adjust "by(..)" in the collapse command if you want to use maptile!)
	tostring state_code_1990, gen(s)
	tostring county_code_1990, gen(c)
	replace c = "00" + c if length(c) == 1
	replace c = "0" + c if length(c) == 2
	gen fips = s + c
	drop s c
	destring fips, replace
	ren fips county
	
	* A) Maps on immigrants
	if "`a'" == "immigrants" | "`a'" == "immigrantsnoneurope" {
		
		preserve
		
			if "`a'" == "immigrants" {
				collapse (sum) immigrants_*, by(state_county_code_1990 /*county*/ state_name county_name)
				reshape long immigrants_, i(state_county_code_1990 /*county*/ state_name county_name) j(year)
				
				ren `a'_ `a'
				qui reghdfe `a', absorb(i.state_county /*i.county*/ i.year) residuals(res)
				
				qui levelsof year, local(years)
				gen decile = .
				foreach x in `years' {
					xtile x = res if year == `x', n(10)
					replace decile =  x if year == `x'
					drop x
				}
			}
		
			*For nonEuropean immigration maps: Take pre1880 + 1900 = pre1900; 1910+1920+1930 = 1910-1930
			if "`a'" == "immigrantsnoneurope" {
				foreach x in 1880 1900 1910 1920 1930 1970 1980 1990 2000 2010 {
					gen immigrantsnoneurope_`x' = immigrants_`x'
					replace immigrantsnoneurope_`x' = 0 if continent == "Europe"
				}
				
				collapse (sum) immigrantsnoneurope_*, by(state_county_code_1990 /*i.county*/ state_name county_name)
				reshape long immigrantsnoneurope_, i(state_county_code_1990 /*i.county*/ state_name county_name) j(year)
				
				gen new_year = year
				replace new_year = 1900 if year == 1880
				replace new_year = 1930 if year == 1910
				replace new_year = 1930 if year == 1920
				collapse (sum) `a'_, by(new_year state_county_code_1990 /*county*/)
				ren new_year year
				
				keep if year == 1900 | year == 1930 // restrict to two periods of interest
				
				ren `a'_ `a'
				qui reghdfe `a', absorb(i.state_county_code_1990 /*i.county*/ i.year) residuals(res)
				
				pause
				tab year
				
				qui levelsof year, local(years)
				gen decile = .
				foreach x in `years' {
					xtile x = res if year == `x', n(10)
					replace decile =  x if year == `x'
					drop x
				}
			}

			keep state_county_code_1990 year decile
			reshape wide decile, i(state_county_code_1990) j(year)
			export delimited using "Output/Maps/`a'.csv", replace
			
		restore
	}
	
	*B) Maps on ancestry
	else {
		preserve
			
			keep if continent == "Europe"
			gen specialfe = country_code1990 if country_name == "Germany" | country_name == "Italy"
			
			qui reghdfe log_ancestry_2010, absorb(i.state_county_code i.specialfe) residuals(resid_lancestryGER_2010)
			replace resid_lancestryGER_2010 = 0 if country_name != "Germany"
			qui reghdfe log_ancestry_2010, absorb(i.state_county_code i.specialfe) residuals(resid_lancestryITA_2010)
			replace resid_lancestryITA_2010 = 0 if country_name != "Italy"
			
			collapse (sum) resid_lancestryGER_* resid_lancestryITA_*, by(/*county*/ state_county_code_1990 state_name county_name)
			reshape long resid_lancestryGER_ resid_lancestryITA_, i(/*county*/ state_county_code_1990 state_name county_name) j(year)
			
			ren resid_l`a'_ `a'			
			keep if year == 2010
			xtile decile = `a', n(10)
			
			keep state_county_code_1990 year decile
			reshape wide decile, i(state_county_code_1990) j(year)
			export delimited using "Output/Maps/`a'.csv", replace
			
		restore
	}
}

* Top 8 countries
use "./Input/EthnicityDataForRegression_Figure2and3.dta", replace

* Merge with country abbrev
ren country_code1990 country_code
merge m:1 country_code using "Input\List-UNcountries1990.dta"
keep state_county_code_1990 state_name_1990 county_name_1990 country_name country_code country_isocode ancestry_1990
order state_county_code_1990 state_name_1990 county_name_1990 country_name country_code country_isocode ancestry_1990
sort state_county_code_1990 country_code

* Merge with county-level population
merge m:1 state_county_code_1990 using "./Input/US-County-Population-1990.dta"
keep state_county_code_1990 state_name_1990 county_name_1990 country_name country_code country_isocode ancestry_1990 population
gen log_ancestry_1990 = log(1+ancestry_1990)

* Generate residuals
reghdfe log_ancestry_1990, absorb(state_county_code_1990 country_code) residuals(log_ancestry_1990_res)

* Generate shares
gen ancestry_share = ancestry_1990 * 10000 / population

* Keep top 8 ancestries only
keep if country_isocode == "DEU" | country_isocode == "GBR" | country_isocode == "IRL" | country_isocode == "MEX" ///
| country_isocode == "ITA" | country_isocode == "POL" | country_isocode == "FRA" | country_isocode == "NLD"

* Generate deciles
xtile quantity_decile_ = log_ancestry_1990_res, n(10)
xtile share_decile_ = ancestry_share, n(10)

* Reshape dataset for ArcGIS use
keep state_county_code_1990 country_isocode quantity_decile_ share_decile_
reshape wide quantity_decile_ share_decile_, i(state_county_code_1990) j(country_isocode) string
export delimited using "./Output/Maps/TopEightAncestry.csv", replace

*************************************************************************************************************************
* Figure 4: Heterogeneous Estimates across Countries and Counties
*************************************************************************************************************************
// Country Funnel Plot
use "./Input/Replication.dta", replace
collapse (sum) ancestry_2010, by(country_code1990)
gsort -ancestry_2010
list country_code1990 if _n <= 5
rename country_code1990 country_code
saveold "./Output/2010TotalAncestry.dta", replace

use "./Input/Replication.dta", replace
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10
qui statsby _b _se, by(country_code1990) clear: qui ivreg country_dummy distance_lat dist (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), r
rename country_code1990 country_code
merge 1:1 country_code using "./Input/List-UNcountries1990.dta"
keep if _merge == 3
drop country_isocode _merge
merge 1:1 country_code using "./Output/2010TotalAncestry.dta"
keep if _merge == 3
drop _merge
replace country_name = "Britain" if country_code == 826

gen _t_log_ancestry_2010 = _b_log_ancestry_2010 / _se_log_ancestry_2010
sum _t_log_ancestry_2010 if _t_log_ancestry_2010 > 1.96 | _t_log_ancestry_2010 < -1.96

gen inv_se_ancestry_2010 = 1/_se_log_ancestry_2010
gen country_name_select = country_name if country_code == 276 | country_code == 826 | country_code == 372 | country_code == 484 | country_code == 380
gen country_name_position = 0
replace country_name_position = 11 if country_name == "Germany"

gsort -ancestry_2010
keep if _n <= 100

sum if inv_se_ancestry_2010 < 150 
sum if _b_log_ancestry_2010 < 1
sum if inv_se_ancestry_2010 < 150 & _b_log_ancestry_2010 < 1

twoway scatter inv_se_ancestry_2010 _b_log_ancestry_2010 [w = ancestry_2010] if inv_se_ancestry_2010 < 150 & _b_log_ancestry_2010 < 1 ///
       , mlw(vthin) mc(gs8) m(Oh) graphregion(color(white)) xline(0, lc(black) lw(vthin) lp(dash)) legend(off) ///
	     xtitle(Coefficient Estimate: Countries, size(small)) xlabel(-0.1(0.1)1, labs(small)) ytitle(1 / Standard Error, size(small)) ylabel(,nogrid labs(small)) ///
       || scatter inv_se_ancestry_2010 _b_log_ancestry_2010 if inv_se_ancestry_2010 < 150 & _b_log_ancestry_2010 < 1 ///
	      , ms(i) mlabel(country_name_select) mlabvposition(country_name_position) mlabsize(medium) mlabcol(gs6) ///
	   || function y= 1.96/x, range(0.01 1)     lc(cranberry) ///
	   || function y=-1.96/x, range(-0.1 -0.01) lc(cranberry) scheme(s2color)
graph export "./Output/Figure4A.eps", replace as(eps)

// County Funnel Plot
use "./Input/Replication.dta", replace
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10
qui statsby _b _se, by(state_county_code_1990) clear: ivreg country_dummy distance_lat dist (log_ancestry_2010 = immi_nc_d_X_o_ndv_* pcFour*), r
saveold "./Output/FirmRegByCounty.dta", replace

use "./Output/FirmRegByCounty.dta", replace
merge 1:1 state_county_code_1990 using "./Input/US-County-Population-1990.dta"
drop _merge
gsort -population

keep if _n <= 100
list state_name county_name state_county_code population if _n <= 10

gen inv_se_ancestry_2010 = 1/_se_log_ancestry_2010

gen county_name_select = county_name if state_county_code_1990 == 60370 | ///
state_county_code_1990 == 170310 | state_county_code_1990 == 482010 | ///
state_county_code_1990 == 60730 | state_county_code_1990 == 60590
replace county_name_select = county_name_select + ", CA" if state_county_code_1990 == 60370
replace county_name_select = county_name_select + ", IL" if state_county_code_1990 == 170310
replace county_name_select = county_name_select + ", TX" if state_county_code_1990 == 482010
replace county_name_select = county_name_select + ", CA" if state_county_code_1990 == 60730
replace county_name_select = county_name_select + ", CA" if state_county_code_1990 == 60590

gen county_name_position = 0
replace county_name_position = 12 if state_county_code_1990 == 60370
replace county_name_position = 4 if state_county_code_1990 == 170310
replace county_name_position = 3 if state_county_code_1990 == 60730

sum if inv_se_ancestry_2010 < 150 
sum if _b_log_ancestry_2010 < 0.5
sum if inv_se_ancestry_2010 < 150 & _b_log_ancestry_2010 < 0.5

twoway scatter inv_se_ancestry_2010 _b_log_ancestry_2010 [w = population] if inv_se_ancestry_2010 < 150 & _b_log_ancestry_2010 < 0.5 ///
       , mlw(vthin) mc(gs8) m(Oh) graphregion(color(white)) xline(0, lc(black) lw(vthin) lp(dash)) legend(off) ///
	     xtitle(Coefficient Estimate: Counties, size(small)) xlabel(-0.1(0.1)0.5, labs(small)) ylabel(0(25)100, labs(small)) ytitle(1 / Standard Error, size(small)) ylabel(,nogrid labs(small)) ///
	   || scatter inv_se_ancestry_2010 _b_log_ancestry_2010 if inv_se_ancestry_2010 < 150 & _b_log_ancestry_2010 < 0.5 ///
	      , ms(i) mlabel(county_name_select) mlabvposition(county_name_position) mlabsize(small) mlabcol(gs6) ///
	   || function y= 1.96/x, range(0.02 0.5)     lc(cranberry) ///
	   || function y=-1.96/x, range(-0.1 -0.02) lc(cranberry) scheme(s2color)
graph export "./Output/Figure4B.eps", replace as(eps)

*************************************************************************************************************************
* Figure 5: Ancestry and FDI: Germany and Britain; LA and Cook Counties
*************************************************************************************************************************

* Get Data For Analysis
use "./Input/Replication.dta", replace

rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

* Get 2-digit Country ISO Code
rename country_code1990 country_code
merge m:1 country_code using "Input\List-UNcountries1990.dta" 
drop if _merge == 2
drop _merge
rename country_code country_code1990 
sort state_county_code_1990 country_code1990
gen country_isocode_2digit = substr(country_isocode,1,2)

gen county_name_label = county_name_1990
replace county_name_label = "" if state_county_code_1990 != 60370 & state_county_code_1990 != 170310 & state_county_code_1990 != 482010 & state_county_code_1990 != 60730 & state_county_code_1990 != 60590

* Germany Case
capture drop log_ancestry_hat 
qui xi:reg log_ancestry_2010   dist distance_lat immi_nc_d_X_o_ndv_* pcFour* if country_code == 276, r
qui predict log_ancestry_hat if country_code == 276, xb
qui xi:reg log_subsidiarycount dist distance_lat log_ancestry_hat if country_code == 276, r
qui avplot log_ancestry_hat, msize(small) mlabel(county_name_label) ytitle(Log # of Subsidiaries in Origin | X) xtitle(Predicted Log Ancestry 2010 | X) title(Germany) scheme(s1color)
graph export "./Output/Figure5A.eps", as(eps) replace

* Britain Case
capture drop log_ancestry_hat 
qui xi:reg log_ancestry_2010   dist distance_lat immi_nc_d_X_o_ndv_* pcFour* if country_code == 826, r
qui predict log_ancestry_hat if country_code == 826, xb
qui xi:reg log_subsidiarycount dist distance_lat log_ancestry_hat if country_code == 826, r
qui avplot log_ancestry_hat, msize(small) mlabel(county_name_label) ytitle(Log # of Subsidiaries in Origin | X) xtitle(Predicted Log Ancestry 2010 | X) title(Britain) scheme(s1color) 
graph export "./Output/Figure5B.eps", as(eps) replace

* LA County Case
capture drop log_ancestry_hat 
qui xi:reg log_ancestry_2010   dist distance_lat immi_nc_d_X_o_ndv_* pcFour* if state_county_code_1990 == 60370, r
qui predict log_ancestry_hat if state_county_code_1990 == 60370, xb
qui xi:reg log_subsidiarycount dist distance_lat log_ancestry_hat if state_county_code_1990 == 60370, r
qui avplot log_ancestry_hat, msize(small) mlabel(country_isocode_2digit) ytitle(Log # of Subsidiaries in Origin | X) xtitle(Predicted Log Ancestry 2010 | X) title(Los Angeles CA) scheme(s1color) 
graph export "./Output/Figure5C.eps", as(eps) replace

* Cook County Case
capture drop log_ancestry_hat 
qui xi:reg log_ancestry_2010   dist distance_lat immi_nc_d_X_o_ndv_* pcFour* if state_county_code_1990 == 170310, r
qui predict log_ancestry_hat if state_county_code_1990 == 170310, xb
qui xi:reg log_subsidiarycount dist distance_lat log_ancestry_hat if state_county_code_1990 == 170310, r
qui avplot log_ancestry_hat, msize(small) mlabel(country_isocode_2digit) ytitle(Log # of Subsidiaries in Origin | X) xtitle(Predicted Log Ancestry 2010 | X) title(Cook IL) scheme(s1color) 
graph export "./Output/Figure5D.eps", as(eps) replace

*************************************************************************************************************************
* Figure 6: Counterfactual Experiment: Removing the Chinese Exclusion Act 
*************************************************************************************************************************
use "Input/EthnicityDataForRegression_Figure6.dta", replace

* ------------------------------------------------------------------------------
* Event One: Chinese Exclusion (1882 - 1965)
* ------------------------------------------------------------------------------

// Generate CHINESE EXCLUSION dummy
gen ChineseExclusion = 0
replace ChineseExclusion = 1 if country_name == "China" & time > 1 & time <= 6

// Generate counterfactual immigrant at division level
qui reghdfe immigrants ChineseExclusion, absorb(i.country_code i.time#i.division) 
matrix coef = e(b)
gen immigrants_CHN_o_dv = immigrants - coef[1,1] * ChineseExclusion

*Count total Chinese immigrants (in 1000s)
preserve	
	keep if country_name == "China"
	gen immigrants_CHN_additional = immigrants_CHN_o_dv - immigrants
	egen total_immigrants_CHN_additional = total(immigrants_CHN_additional)
	format total_immigrants_CHN_additional %15.0fc
	list total_immigrants_CHN_additional if _n == 1
restore

// Generate alternative immigration flows to other census regions
sort country_code time 
by country_code time: egen immigrants_CHN_o = sum(immigrants_CHN_o_dv)
gen immigrants_CHN_o_ndv_ = immigrants_CHN_o - immigrants_CHN_o_dv

// Reshape WIDE
keep country_code time immigrants_CHN_o_ndv_ division
qui reshape wide immigrants_CHN_o_ndv_, i(country_code division) j(time)

sort country_code1990 division
saveold "./Output/Counterfactual_China.dta", replace

use "./Input/Replication.dta", clear

* Generate orthogonal instruments
qui reg immi_nc_d_X_o_ndv_2  immi_nc_d_X_o_ndv_1,r
predict res_2, r
qui reg immi_nc_d_X_o_ndv_3  immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_3, r
qui reg immi_nc_d_X_o_ndv_4  immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_4, r
qui reg immi_nc_d_X_o_ndv_5  immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_5, r
qui reg immi_nc_d_X_o_ndv_6  immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_6, r
qui reg immi_nc_d_X_o_ndv_7  immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_7, r
qui reg immi_nc_d_X_o_ndv_8  immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_8, r
qui reg immi_nc_d_X_o_ndv_9  immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_9, r

rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

foreach time of numlist 2/9 {
  rename immi_nc_d_X_o_ndv_`time' XXimmi_nc_d_X_o_ndv_`time'
  rename res_`time' immi_nc_d_X_o_ndv_`time'
}

* ------------------------------------------------------------------------------
* First- and second-stage regressions
* ------------------------------------------------------------------------------

// First-stage regression - LOGS
qui reg2hdfe log_ancestry_2010 immi_nc_d_X_o_ndv_* dist distance_lat, id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990)
predict log_ancestry_2010_hat, xb
matrix fsCoef_log = e(b)

// First-stage regression - LEVELS
qui reg2hdfe ancestry_2010 immi_nc_d_X_o_ndv_* dist distance_lat, id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990)
predict ancestry_2010_hat, xb
matrix fsCoef_level = e(b)

// Second-stage linear regressions
rename log_subsidiarycount log_subcount
*rename log_subsidiaryparentcount log_subparentcount
rename log_usparentcount  log_subparentcount
rename log_subsidiarynumberemployees log_subemployees
rename log_shareholdercount log_sharecount
*rename log_shareholderparentcount log_shareparentcount
rename log_ussubsidiarycount  log_shareparentcount
rename log_shareholdernumberemployees log_shareemployees
foreach variable of varlist country_dummy log_subcount log_subparentcount log_subemployees log_sharecount log_shareparentcount log_shareemployees log_fditotal {
  qui reg2hdfe `variable' log_ancestry_2010_hat dist distance_lat, id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990)
  matrix `variable'_coef = e(b)
  predict `variable'_hat, xb
}

* ------------------------------------------------------------------------------
* Calculate alternative probabilities for each county
* ------------------------------------------------------------------------------

merge m:1 country_code1990 division using "./Output/Counterfactual_China.dta"

// Generate immigration change
gen deltaAnc_log = 0 

foreach time of numlist 1/9 {
  gen immigration_nc_d_o_`time' = immigration_nc_d_`time' / immigration_nc_`time'
  replace immigration_nc_d_o_`time' = 0 if immigration_nc_d_o_`time' == .
  replace deltaAnc_log = deltaAnc_log + fsCoef_log[1,`time'] * immigration_nc_d_o_`time' * (immigrants_CHN_o_ndv_`time'-immigration_o_ndv_`time')  
  gen deltaAnc_log_`time' = deltaAnc_log
}

foreach variable of varlist country_dummy log_subcount log_subparentcount log_subemployees log_sharecount log_shareparentcount log_shareemployees log_fditotal {
  gen `variable'_delta = `variable'_coef[1,1] * deltaAnc_log
  gen `variable'_chat = `variable'_hat + `variable'_delta
}

*Export for figure
preserve
	keep if country_name == "China"
	xtile country_dummy_delta_decile_ = country_dummy_delta, n(10)
	keep country_dummy_delta_decile_ state_county_code_1990
	export delimited using "./Output/Maps/ChinaCounterFactual_County.csv", replace
restore
	
saveold "./Output/Counterfactual_China.dta", replace


******************************
*Input to Map
******************************
use "Output/Counterfactual_China.dta", replace

keep state_county_code_1990 state_code_1990 state_name_1990 country_name ///
     country_dummy country_dummy_delta country_dummy_hat ///
   log_subcount_delta log_subcount_hat ///
   log_subparentcount_delta log_subparentcount_hat ///
   log_subemployees_delta log_subemployees_hat ///
   log_sharecount_delta log_sharecount_hat ///
   log_shareparentcount_delta log_shareparentcount_hat ///
   log_shareemployees_delta log_shareemployees_hat ///
   log_fditotal_delta log_fditotal_hat deltaAnc_log log_ancestry_2010 

order state_county_code_1990 state_code_1990 state_name_1990 country_name ///
     deltaAnc_log log_ancestry_2010 country_dummy country_dummy_delta country_dummy_hat ///
   log_subcount_delta log_subcount_hat ///
   log_subparentcount_delta log_subparentcount_hat ///
   log_subemployees_delta log_subemployees_hat ///
   log_sharecount_delta log_sharecount_hat ///
   log_shareparentcount_delta log_shareparentcount_hat ///
   log_shareemployees_delta log_shareemployees_hat ///
   log_fditotal_delta log_fditotal_hat 

keep if country_name == "China"

collapse (count) counties=state_county_code_1990 (rawsum) sum_country_dummy=country_dummy ///
sum_country_dummy_delta=country_dummy_delta (mean) deltaAnc_log ///
log_ancestry_2010 country_dummy_delta log_subcount_delta log_subparentcount_delta ///
log_subemployees_delta log_sharecount_delta log_shareemployees_delta ///
log_fditotal_delta, by(state_name_1990 state_code_1990)

saveold "./Output/PushFactorCounterfactuals.dta", replace

* Bar graph for sum_country_dummy and sum_country_dummy_delta

use "./Output/PushFactorCounterfactuals.dta", replace

replace sum_country_dummy = sum_country_dummy/counties
replace sum_country_dummy_delta = sum_country_dummy_delta/counties

gsort -sum_country_dummy_delta
drop if state_name_1990 == "District Of Columbia"
keep if _n <= 10

gen ratio = sum_country_dummy_delta/sum_country_dummy
gen total = sum_country_dummy_delta + sum_country_dummy

gsort -total
forvalues x = 1/10 {
	quietly levelsof sum_country_dummy if `x' == _n, local(baseline`x')
	local baseline`x': di %3.2fc `baseline`x''
	quietly levelsof ratio if `x' == _n, local(increase`x')
	local increase`x': di %3.0fc `=`increase`x''*100'
	quietly levelsof total if `x' == _n, local(total`x')
	local total`x': di %3.2fc `total`x''
	quietly levelsof state_name_1990 if `x' == _n, local(name`x')
	di "for x=`x' (state = `=`name`x'''), baseline = `baseline`x''; increase = `increase`x''%, total = `total`x''"
}

* Graph EXCLUDING DC * 
 graph hbar sum_country_dummy sum_country_dummy_delta if state_name_1990 != "District Of Columbia", ///
                         over(state_name_1990, sort(total) descending label(labsize(medsmall))) stack ///
                         plotregion(style(none)) aspectratio(2) scheme(s1color)  ///
                         bar(2, color(navy)) bar(1, color(100 200 150)) ///
                         ytitle("Extensive Margin (China)", size(medsmall)) ///
                         ylabel(, labsize(medsmall) grid glpattern(shortdash) glwidth(vthin)) ///
                         legend(off) ///
                         text(`total10' 4 "+`increase10'%", place(e)) ///
                         text(`total9' 14.22 "+`increase9'%", place(e)) ///
                         text(`total8' 24.44 "+`increase8'%", place(e)) ///
                         text(`total7' 34.66 "+`increase7'%", place(e)) ///
                         text(`total6' 44.88 "+`increase6'%", place(e)) ///
                         text(`total5' 55.11 "+`increase5'%", place(e)) ///
                         text(`total4' 65.33 "+`increase4'%", place(e)) ///
                         text(`total3' 75.55 "+`increase3'%", place(e)) ///
                         text(`total2' 85.77 "+`increase2'%", place(e)) ///
                         text(`total1' 96 "+`increase1'%", place(e))
                         * legend(label(1 "FDI Dummy (Average)") label(2 "Counterfactual Change")  ///
			             * col(2) ring(0) position(5) symysize(*.3) symxsize(*1.3) keygap(1) colgap(0) nobox size(small) region(lc(none)) stack)

graph export "./Output/Figure6.eps", as(eps) replace

*****************************************************************************************************************
*****************************************************************************************************************
*********************************** APPENDIX FIGURES START ******************************************************
*****************************************************************************************************************
*****************************************************************************************************************

***************************************************************************************************************************
* Appendix Figure 1: First-Stage Coefficients 
***************************************************************************************************************************
use "./Input/Replication.dta", replace

* Generate orthogonal instruments
qui reg immi_nc_d_X_o_ndv_2  immi_nc_d_X_o_ndv_1,r
predict res_2, r
qui reg immi_nc_d_X_o_ndv_3  immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_3, r
qui reg immi_nc_d_X_o_ndv_4  immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_4, r
qui reg immi_nc_d_X_o_ndv_5  immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_5, r
qui reg immi_nc_d_X_o_ndv_6  immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_6, r
qui reg immi_nc_d_X_o_ndv_7  immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_7, r
qui reg immi_nc_d_X_o_ndv_8  immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_8, r
qui reg immi_nc_d_X_o_ndv_9  immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_9, r
qui reg immi_nc_d_X_o_ndv_10 immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_10, r

* Assign meaningful labels to instruments
foreach time of numlist 2/9 {
  if `time' == 1 {
    local year = 1880
  }  
  else if `time' >= 2 & `time' <= 5 {
    local year = 1880 + `time'*10
  }
  else {
    local year = 1910 + `time'*10
  }  
  rename immi_nc_d_X_o_ndv_`time' XXimmi_nc_d_X_o_ndv_`time'
  rename res_`time' immi_nc_d_X_o_ndv_`time' 
  label variable immi_nc_d_X_o_ndv_`time' "\$I_{o,-r(d)}^{`year'}\frac{I_{-c(o),d}^{`year'}}{I_{-c(o)}^{`year'}}\$"
}

* Get rid of 2010 immigration
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

* Rename principal components
foreach time of numlist 1/5 {
  rename pcFour`time' pc_`time'
}

* Table One Column 2: same as 1 but add distance and latitude control
qui reg2hdfe log_ancestry_2010 immi_nc_d_X_o_ndv_* dist distance_lat, id1(country_code1990) id2(state_county_code_1990) cluster(country_code1990)
estimates store TableOne2, title(" ")

mat b = e(b)
mat v = e(V)
local df = e(df_r)

preserve
	keep if _n == 1
	
	*Take first 9 coefficients and standard errors
	forvalues j = 1/9 {
		gen mean_wave`j' = b[1,`j']
		
		gen low_wave`j' = `= b[1,`j'] - ( invttail(`df',.05/2) * sqrt(v[`j',`j']) ) '
		gen up_wave`j' = `= b[1,`j'] + ( invttail(`df',.05/2) * sqrt(v[`j',`j']) ) '
		
		gen sd_wave`j' = sqrt(v[`j',`j'])
	}
	
	keep mean_wave* low_wave* up_wave* sd_wave*
	gen id = 1
	reshape long mean_wave low_wave up_wave sd_wave, i(id)
	drop id
	ren _j wave

	*Variable with labels
	gen label_wave = "1880" if wave == 1
	replace label_wave = "1900" if wave == 2
	replace label_wave = "1910" if wave == 3
	replace label_wave = "1920" if wave == 4
	replace label_wave = "1930" if wave == 5
	replace label_wave = "1970" if wave == 6
	replace label_wave = "1980" if wave == 7
	replace label_wave = "1990" if wave == 8
	replace label_wave = "2000" if wave == 9

	*sort mean_wave
	gen n = _n
	labmask n, values(label_wave)
	drop label_wave

	forvalues i = 1/9 {
		levelsof wave if _n == `i', local(j)
		local command = `"`command'"' + `" (bar mean_wave n if wave == `j', color("10 1 138") lcolor(black) barwidth(.5))"'
	}

	twoway `command' (rcap low_wave up_wave n, lstyle(foreground) lcolor(red)), xtitle("") ///
	xlabel(#10, valuelabel) scheme(s1color) ymtick(0,grid glcolor(black) glwidth(vthin)) ///
	ylabel(, valuelabel angle(h)) ytitle("Coefficient on excluded IVs", size(large)) legend(off)
	graph export "Output/AppFigure1.eps", replace as(eps)
restore

***************************************************************************************************************************
* Appendix Figure 2: Second-Stage Coefficients 
***************************************************************************************************************************
use "./Input/Replication.dta", replace

* Get rid of 2010 immigration
rename immi_nc_d_X_o_ndv_10 XXimmi_nc_d_X_o_ndv_10

*replace country_dummy = 100 * country_dummy

* Generate orthogonal instruments
qui reg immi_nc_d_X_o_ndv_2  immi_nc_d_X_o_ndv_1,r
predict res_2, r
qui reg immi_nc_d_X_o_ndv_3  immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_3, r
qui reg immi_nc_d_X_o_ndv_4  immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_4, r
qui reg immi_nc_d_X_o_ndv_5  immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_5, r
qui reg immi_nc_d_X_o_ndv_6  immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_6, r
qui reg immi_nc_d_X_o_ndv_7  immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_7, r
qui reg immi_nc_d_X_o_ndv_8  immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_8, r
qui reg immi_nc_d_X_o_ndv_9  immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1,r
predict res_9, r

* Assign meaningful labels
foreach time of numlist 2/9 {
  if `time' == 1 {
    local year = 1880
  }  
  else if `time' >= 2 & `time' <= 5 {
    local year = 1880 + `time'*10
  }
  else {
    local year = 1910 + `time'*10
  }  
  rename immi_nc_d_X_o_ndv_`time' XXimmi_nc_d_X_o_ndv_`time'
  rename res_`time' immi_nc_d_X_o_ndv_`time' 
  label variable immi_nc_d_X_o_ndv_`time' "\$I_{-c,d}^{`year'}I_{o,-division}^{`year'}\$"
}

reghdfe country_dummy immi_nc_d_X_o_ndv_* dist distance_lat, absorb(country_code1990 state_county_code_1990) vce(cluster country_code1990)
estimates store FigureTwo, title(" ")
*estout FigureTwo using "./Output/PaperFigureTwo.tex", replace style(tex) keep(immi_nc_d_X_o_ndv_*) ml( ,none) collabels(, none) cells(b(star fmt(%9.4f)) se(par)) prefoot("\hline") stats(r2, fmt(%9.2f) labels("\$R^2\$")) starlevels(* 0.10 ** 0.05 *** 0.01) label

mat b = e(b)
mat v = e(V)
local df = e(df_r)

preserve
	keep if _n == 1
	
	*Take first 9 coefficients and standard errors
	forvalues j = 1/9 {
		gen mean_wave`j' = b[1,`j']
		
		gen low_wave`j' = `= b[1,`j'] - ( invttail(`df',.05/2) * sqrt(v[`j',`j']) ) '
		gen up_wave`j' = `= b[1,`j'] + ( invttail(`df',.05/2) * sqrt(v[`j',`j']) ) '
		
		gen sd_wave`j' = sqrt(v[`j',`j'])
	}
	
	keep mean_wave* low_wave* up_wave* sd_wave*
	gen id = 1
	reshape long mean_wave low_wave up_wave sd_wave, i(id)
	drop id
	ren _j wave

	*Variable with labels
	gen label_wave = "1880" if wave == 1
	replace label_wave = "1900" if wave == 2
	replace label_wave = "1910" if wave == 3
	replace label_wave = "1920" if wave == 4
	replace label_wave = "1930" if wave == 5
	replace label_wave = "1970" if wave == 6
	replace label_wave = "1980" if wave == 7
	replace label_wave = "1990" if wave == 8
	replace label_wave = "2000" if wave == 9

	*sort mean_wave
	gen n = _n
	labmask n, values(label_wave)
	drop label_wave

	forvalues i = 1/9 {
		levelsof wave if _n == `i', local(j)
		local command = `"`command'"' + `" (bar mean_wave n if wave == `j', color("10 1 138") lcolor(black) barwidth(.5))"'
	}

	twoway `command' (rcap low_wave up_wave n, lstyle(foreground) lcolor(red)), xtitle("") ///
	xlabel(#10, valuelabel) scheme(s1color) ymtick(0,grid glcolor(black) glwidth(vthin)) ///
	ylabel(#10) yscale(range(-.03 .08)) ytitle("Coefficient on excluded IVs", size(large)) legend(off)
	graph export "Output/AppFigure2.eps", replace as(eps)
restore

********************************************************************************
* Appendix Figure 3: Largest Counties
********************************************************************************
use "Input/Replication.dta", replace

* Generate orthogonal instruments
qui reg immi_nc_d_X_o_ndv_2  immi_nc_d_X_o_ndv_1
predict res_2, r
rename immi_nc_d_X_o_ndv_2 XXXimmi_nc_d_X_o_ndv_2
rename res_2 immi_nc_d_X_o_ndv_2

qui reg immi_nc_d_X_o_ndv_3  immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_3, r
rename immi_nc_d_X_o_ndv_3 XXXimmi_nc_d_X_o_ndv_3
rename res_3 immi_nc_d_X_o_ndv_3

qui reg immi_nc_d_X_o_ndv_4  immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_4, r
rename immi_nc_d_X_o_ndv_4 XXXimmi_nc_d_X_o_ndv_4
rename res_4 immi_nc_d_X_o_ndv_4

qui reg immi_nc_d_X_o_ndv_5  immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_5, r
rename immi_nc_d_X_o_ndv_5 XXXimmi_nc_d_X_o_ndv_5
rename res_5 immi_nc_d_X_o_ndv_5

qui reg immi_nc_d_X_o_ndv_6  immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_6, r
rename immi_nc_d_X_o_ndv_6 XXXimmi_nc_d_X_o_ndv_6
rename res_6 immi_nc_d_X_o_ndv_6

qui reg immi_nc_d_X_o_ndv_7  immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_7, r
rename immi_nc_d_X_o_ndv_7 XXXimmi_nc_d_X_o_ndv_7
rename res_7 immi_nc_d_X_o_ndv_7

qui reg immi_nc_d_X_o_ndv_8  immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_8, r
rename immi_nc_d_X_o_ndv_8 XXXimmi_nc_d_X_o_ndv_8
rename res_8 immi_nc_d_X_o_ndv_8

qui reg immi_nc_d_X_o_ndv_9  immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_9, r
rename immi_nc_d_X_o_ndv_9 XXXimmi_nc_d_X_o_ndv_9
rename res_9 immi_nc_d_X_o_ndv_9

qui reg immi_nc_d_X_o_ndv_10 immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_10, r
rename immi_nc_d_X_o_ndv_10 XXXimmi_nc_d_X_o_ndv_10
rename res_10 immi_nc_d_X_o_ndv_10

keep country_dummy fdi_total subsidiarycount ussubsidiary_firmcount log_ancestry_2010 ancestry_2010 fdi_total ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 ///
	XXXimmi_nc_d_X_o_ndv_2 XXXimmi_nc_d_X_o_ndv_3 XXXimmi_nc_d_X_o_ndv_4 XXXimmi_nc_d_X_o_ndv_5 XXXimmi_nc_d_X_o_ndv_6 XXXimmi_nc_d_X_o_ndv_7 XXXimmi_nc_d_X_o_ndv_8 XXXimmi_nc_d_X_o_ndv_9 ///
	dist distance_lat region_country_code county_continent_code country_code1990 country_name state_county_code_1990 county_name_1990 state_name_1990 continent


* Generate sum of total FDI

bys state_county_code_1990: egen fdi_intensive_sum = total(fdi_total)

sum fdi_total
local fdi_intensive_total = r(N) * r(mean) 

preserve
foreach x of numlist 1/10 {
	gsort -fdi_intensive_sum state_county_code_1990 -fdi_total country_name

	local 	county_select       = state_county_code_1990[1]
	local 	county_select_cname = county_name_1990[1]
	local 	county_select_sname = state_name_1990[1]
	local   county_select_fdishare = round(100*fdi_intensive_sum[1]/`fdi_intensive_total', .01)

	sum ancestry_2010 if state_county_code_1990 == `county_select', d
	centile ancestry_2010 if state_county_code_1990 == `county_select', centile(90)
	local   ancestry_2010_p90 = r(c_1)
	display `ancestry_2010_p90'
	
	sum ancestry_2010 if state_county_code_1990 == `county_select' & ancestry_2010 <= `ancestry_2010_p90'
	local pos_x =  (r(max)- r(min))*0.75 + r(min)
	sum fdi_total if state_county_code_1990 == `county_select' & ancestry_2010 <= `ancestry_2010_p90'
	local pos_y =  (r(max)- r(min))*0.75 + r(min)
	reg fdi_total ancestry_2010 if state_county_code_1990 == `county_select' & ancestry_2010 <= `ancestry_2010_p90'
	local beta = round(_b[ancestry_2010],.01)
	local ster = round(_se[ancestry_2010],.01)

	twoway (scatter fdi_total ancestry_2010) ///
	   (lfit fdi_total ancestry_2010) ///
	   if state_county_code_1990 == `county_select' & ancestry_2010 <= `ancestry_2010_p90', ///
	   saving(g1, replace) legend(off)  title("Sample: Ancestry 2010 in bottom 90%", size(small)) xtitle("Ancestry 2010 (in 1000)")  ///
	   ytitle("Total # of FDI Relationships 2014") ///
	   text(`pos_y' `pos_x' "{&beta}=`:di %4.2f `beta'' (`:di %4.2f `ster'')")
	
	sum ancestry_2010 if state_county_code_1990 == `county_select' & ancestry_2010 > `ancestry_2010_p90'
	local pos_x =  (r(max)- r(min))*0.75 + r(min)
	sum fdi_total if state_county_code_1990 == `county_select' & ancestry_2010 > `ancestry_2010_p90'
	local pos_y =  (r(max)- r(min))*0.75 + r(min)
	reg fdi_total ancestry_2010 if state_county_code_1990 == `county_select' & ancestry_2010 > `ancestry_2010_p90'   
	local beta = round(_b[ancestry_2010],.01)
	local ster = round(_se[ancestry_2010],.01)
	
	twoway (scatter fdi_total ancestry_2010) ///
	   (lfit fdi_total ancestry_2010) ///
	   if state_county_code_1990 == `county_select' & ancestry_2010 > `ancestry_2010_p90', ///
	   saving(g2, replace) legend(off) title("Sample: Ancestry 2010 in top 10%", size(small)) xtitle("Ancestry 2010 (in 1000)") ///
	   text(`pos_y' `pos_x' "{&beta}=`:di %4.2f `beta'' (`:di %4.2f `ster'')")
	   
	graph combine g1.gph g2.gph, col(2) ysize(2) xsize(4) scale(1.7) ycommon 
	display "`x': Ancestry and FDI: {bf: `county_select_cname', `county_select_sname'} (`county_select_fdishare'% of total US FDI Relationship)"
	graph export Output/AppFigure3_`x'.pdf, replace

	drop if state_county_code_1990 == `county_select'
}

********************************************************************************
* Appendix Figure 4: 
********************************************************************************
use "Input/Replication.dta", replace

* Generate orthogonal instruments
qui reg immi_nc_d_X_o_ndv_2  immi_nc_d_X_o_ndv_1
predict res_2, r
rename immi_nc_d_X_o_ndv_2 XXXimmi_nc_d_X_o_ndv_2
rename res_2 immi_nc_d_X_o_ndv_2

qui reg immi_nc_d_X_o_ndv_3  immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_3, r
rename immi_nc_d_X_o_ndv_3 XXXimmi_nc_d_X_o_ndv_3
rename res_3 immi_nc_d_X_o_ndv_3

qui reg immi_nc_d_X_o_ndv_4  immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_4, r
rename immi_nc_d_X_o_ndv_4 XXXimmi_nc_d_X_o_ndv_4
rename res_4 immi_nc_d_X_o_ndv_4

qui reg immi_nc_d_X_o_ndv_5  immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_5, r
rename immi_nc_d_X_o_ndv_5 XXXimmi_nc_d_X_o_ndv_5
rename res_5 immi_nc_d_X_o_ndv_5

qui reg immi_nc_d_X_o_ndv_6  immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_6, r
rename immi_nc_d_X_o_ndv_6 XXXimmi_nc_d_X_o_ndv_6
rename res_6 immi_nc_d_X_o_ndv_6

qui reg immi_nc_d_X_o_ndv_7  immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_7, r
rename immi_nc_d_X_o_ndv_7 XXXimmi_nc_d_X_o_ndv_7
rename res_7 immi_nc_d_X_o_ndv_7

qui reg immi_nc_d_X_o_ndv_8  immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_8, r
rename immi_nc_d_X_o_ndv_8 XXXimmi_nc_d_X_o_ndv_8
rename res_8 immi_nc_d_X_o_ndv_8

qui reg immi_nc_d_X_o_ndv_9  immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_9, r
rename immi_nc_d_X_o_ndv_9 XXXimmi_nc_d_X_o_ndv_9
rename res_9 immi_nc_d_X_o_ndv_9

qui reg immi_nc_d_X_o_ndv_10 immi_nc_d_X_o_ndv_9 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_6 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_1
predict res_10, r
rename immi_nc_d_X_o_ndv_10 XXXimmi_nc_d_X_o_ndv_10
rename res_10 immi_nc_d_X_o_ndv_10

keep country_dummy fdi_total subsidiarycount ussubsidiary_firmcount log_ancestry_2010 ancestry_2010 fdi_total ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 ///
	XXXimmi_nc_d_X_o_ndv_2 XXXimmi_nc_d_X_o_ndv_3 XXXimmi_nc_d_X_o_ndv_4 XXXimmi_nc_d_X_o_ndv_5 XXXimmi_nc_d_X_o_ndv_6 XXXimmi_nc_d_X_o_ndv_7 XXXimmi_nc_d_X_o_ndv_8 XXXimmi_nc_d_X_o_ndv_9 ///
	dist distance_lat region_country_code county_continent_code country_code1990 country_name state_county_code_1990 county_name_1990 state_name_1990 continent

local variables = "country_dummy log_ancestry_2010 ancestry_2010 immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 dist distance_lat" 

* Take out variation explained by fixed effects and controls

reg2hdfe log_ancestry_2010 ///
	immi_nc_d_X_o_ndv_1 immi_nc_d_X_o_ndv_2 ///
	immi_nc_d_X_o_ndv_3 immi_nc_d_X_o_ndv_4 immi_nc_d_X_o_ndv_5 immi_nc_d_X_o_ndv_6 ///
	immi_nc_d_X_o_ndv_7 immi_nc_d_X_o_ndv_8 immi_nc_d_X_o_ndv_9 ///
	dist distance_lat, id1(region_country_code) id2(county_continent_code)

foreach v of varlist `variables' {
	qui areg `v' i.region_country_code dist distance_lat, absorb(county_continent_code)
	predict r_`v', residuals
}	

reg log_ancestry_2010 ///
	r_immi_nc_d_X_o_ndv_1 r_immi_nc_d_X_o_ndv_2 ///
	r_immi_nc_d_X_o_ndv_3 r_immi_nc_d_X_o_ndv_4 r_immi_nc_d_X_o_ndv_5 r_immi_nc_d_X_o_ndv_6 ///
	r_immi_nc_d_X_o_ndv_7 r_immi_nc_d_X_o_ndv_8 r_immi_nc_d_X_o_ndv_9 
	
foreach n of numlist 6/9 {
preserve
	if `n' == 1      local t = 1880
	else if `n' >= 6 local t = `n' * 10 + 1910
	else             local t = `n' * 10 + 1880

	local condvariables = ""
	foreach x of numlist 1/9 {
		if `x' != `n' {
			local condvariables = "`condvariables' r_immi_nc_d_X_o_ndv_`x'"
		}
	}
	
	reg r_log_ancestry_2010 `condvariables'
	predict yvar, r
	
	reg r_immi_nc_d_X_o_ndv_`n' `condvariables'
	predict xvar, r

	reg yvar xvar, cluster(country_code1990)
	local beta_hat = round(_b[xvar], .001)
	local sterr    = round(_se[xvar], .001)

	sort continent country_code1990 xvar
	by continent country_code1990: gen group = floor(((_n-1)/_N)*5)
	collapse (mean) yvar xvar, by(continent country_code1990 group)
	
	sum xvar
	local pos_x =  (r(max)- r(min))*0.75 + r(min)
	local pos_y =  `pos_x' * `beta_hat' + 0.1		
	
	twoway (scatter yvar xvar if continent == "Asia",     mc(orange)  msize(tiny)) ///
		   (scatter yvar xvar if continent == "Europe",   mc(blue)    msize(tiny)) ///
		   (scatter yvar xvar if continent == "Africa",   mc(green)   msize(tiny)) ///
		   (scatter yvar xvar if continent == "Americas", mc(red)     msize(tiny)) ///
		   (scatter yvar xvar if continent == "Oceania",  mc(black)   msize(tiny)) ///
		   (function y = `beta_hat'*x, range(xvar) lc(gs2)) ///
		   , legend(off) ytitle("Log Ancestry 2010 ", height(-3)) xtitle("I{subscript:-c(o),d}{superscript:`t'} x I{subscript:o,-r(d)}{superscript:`t'}")  plotregion(margin(vsmall)) graphregion(margin(small)) ysize(3) xsize(4) saving(Output/scatter_`n'.gph, replace) ///
		     text(`pos_y' `pos_x' "{&beta}=`:di %5.3f `beta_hat'' (`:di %5.3f `sterr'')")

	drop yvar xvar 
restore	
}	


foreach n of numlist 1/5 {
preserve
	if `n' == 1      local t = 1880
	else if `n' >= 6 local t = `n' * 10 + 1910
	else             local t = `n' * 10 + 1880

	local condvariables = ""
	foreach x of numlist 1/9 {
		if `x' != `n' {
			local condvariables = "`condvariables' r_immi_nc_d_X_o_ndv_`x'"
		}
	}
	
	reg r_log_ancestry_2010 `condvariables'
	predict yvar, r
	
	reg r_immi_nc_d_X_o_ndv_`n' `condvariables'
	predict xvar, r

	reg yvar xvar, cluster(country_code1990)
	local beta_hat = round(_b[xvar], .001)
	local sterr    = round(_se[xvar], .001)

	sort continent country_code1990 xvar
	by continent country_code1990: gen group = floor(((_n-1)/_N)*5)
	collapse (mean) yvar xvar, by(continent country_code1990 group)
	
	sum xvar
	local pos_x =  (r(max)- r(min))*0.75 + r(min)
	local pos_y =  `pos_x' * `beta_hat' + 0.1		
	
	twoway (scatter yvar xvar if continent == "Asia",     mc(orange)  msize(tiny)) ///
		   (scatter yvar xvar if continent == "Europe",   mc(blue)    msize(tiny)) ///
		   (scatter yvar xvar if continent == "Africa",   mc(green)   msize(tiny)) ///
		   (scatter yvar xvar if continent == "Americas", mc(red)     msize(tiny)) ///
		   (scatter yvar xvar if continent == "Oceania",  mc(black)   msize(tiny)) ///
		   (function y = `beta_hat'*x, range(xvar) lc(gs2)) ///
		   , legend(off) ytitle("Log Ancestry 2010 ") xtitle("I{subscript:-c(o),d}{superscript:`t'} x I{subscript:o,-r(d)}{superscript:`t'}")  plotregion(margin(vsmall)) graphregion(margin(small)) ysize(3) xsize(4) saving(Output/scatter_`n'.gph, replace) ///
		     text(`pos_y' `pos_x' "{&beta}=`:di %5.3f `beta_hat'' (`:di %5.3f `sterr'')")

	drop yvar xvar 
restore	
}	

preserve 
drop if _n > 1
local beta_hat = 1
gen xvar = 1
gen yvar = 1
twoway (scatter yvar xvar if continent == "Asia",     mc(orange)  msize(tiny)) ///
		   (scatter yvar xvar if continent == "Europe",   mc(blue)    msize(tiny)) ///
		   (scatter yvar xvar if continent == "Africa",   mc(green)   msize(tiny)) ///
		   (scatter yvar xvar if continent == "Americas", mc(red)     msize(tiny)) ///
		   (scatter yvar xvar if continent == "Oceania",  mc(black)   msize(tiny)) ///
		   (function y = `beta_hat'*x, range(xvar) lc(gs2)) ///
		   , legend(label(1 "Asia") label(2 "Europe") label(3 "Africa") label(4 "Americas") label(5 "Oceania") label(6 "FS Fit") ring(0) position(12) lw(none) region(fcolor(white)) size(medsmall)) ///
		     graphregion(color(white)) plotregion(color(white)) xscale(r(0 2) off) yscale(r(0 2) off) saving(Output/scatter_10.gph, replace)
			 
drop xvar yvar 	
restore	   


graph combine scatter_1.gph scatter_2.gph scatter_3.gph scatter_4.gph scatter_5.gph scatter_6.gph scatter_7.gph scatter_8.gph scatter_9.gph scatter_10.gph, col(2) xsize(4) ysize(5)
graph export "Output/Figure4.pdf", replace

********************************************************************************
* Appendix Figure 6: Concave ancestry
********************************************************************************
use "Input/Replication.dta", replace

* Regenerate ancestry in the original scale
replace ancestry_2010 = 1000 * ancestry_2010
replace log_ancestry_2010 = log(1 + ancestry_2010)

* Scatter plot
preserve
	xtile ancestry_2010_centile = ancestry_2010 if ancestry_2010 > 0, nq(100)
	replace ancestry_2010_centile = 0 if ancestry_2010 == 0

	collapse (mean) country_dummy ancestry_2010, by(ancestry_2010_centile)

	scatter country_dummy ancestry_2010 if ancestry_2010_centile < 99, ///
		graphregion(color(white)) xtitle("{it: Ancestry 2010}") ytitle("{it: FDI Dummy 2014}" "(Average by {it: Ancestry 2010} bin)") ///
		ylabel(0(.05).25,nogrid) m(Oh) 
	graph export "Output/AppFigure6.pdf", as(pdf) replace
restore

*************************************************************************************************************************
* Appendix Figure 7: Heterogeneous Estimates across Sectors
*************************************************************************************************************************
use "Input/SectorFunnelPlot.dta", replace

gen sector_name= naicsdescription
replace sector_name = "Technical Services" in 3
replace sector_name = "Administrative Services" in 5
replace sector_name = "Real Estate" in 9
replace sector_name = "Other Services" in 10
replace sector_name = "Management" in 12
replace sector_name = "Transportation" in 8
replace sector_name = "Mining, Oil, Gas" in 14
replace sector_name = "Health Care" in 16
replace sector_name = "Entertainment" in 17
replace sector_name = "Agriculture, Forestry, Fishing" in 19
replace sector_name = "Accommodation" in 15

gsort -N
list sector_name N if _n <= 5

gen sector_name_select = sector_name if sector_name == "Manufacturing" | ///
sector_name == "Wholesale Trade" | sector_name == "Technical Services" | ///
sector_name == "Transportation" | sector_name == "Information"

gen inv_se_log_ancestry_2010 = 1 / se_log_ancestry_2010

twoway scatter inv_se_log_ancestry_2010 coef_log_ancestry_2010 [w = N] if inv_se_log_ancestry_2010 < 300 & coef_log_ancestry_2010 > 0 ///
       , mlw(vthin) mc(gs8) m(Oh) graphregion(color(white)) xline(0, lc(black) lw(vthin) lp(dash)) legend(off) ///
	     xtitle(Coefficient Estimate: Sectors, size(small)) xlabel(-0.1(0.1)0.2, labs(small) format(%9.1gc)) ytitle(1 / Standard Error, size(small)) ylabel(,nogrid labs(small)) ///
       || scatter inv_se_log_ancestry_2010 coef_log_ancestry_2010 if inv_se_log_ancestry_2010 < 300 & coef_log_ancestry_2010 > 0 ///
	      , ms(i) mlabel(sector_name_select) mlabsize(small) mlabcol(gs6) ///
	   || function y= 1.96/x, range(0.0065 0.2)   lc(cranberry) ///
	   || function y=-1.96/x, range(-0.1 -0.0065) lc(cranberry) scheme(s2color)
graph export "./Output/AppFigure7.eps", replace as(eps)
