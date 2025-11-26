/* ──────────────────────────────────────────────────────────────────────── *
				TWFE estimates by Top 10 unionized industries 
 * ─────────────────────────────────────────────────────────────────────── */

* Generate effect by industry
use "$intm/RTW_Analysis.dta", clear

collapse (first) rtw_year (sum) pop = wt                                     ///
         (mean) unmem rtw , ///
         by(state year ind_2d)

replace rtw = 0 if rtw < .5 & rtw != 0
replace rtw = 1 if rtw >= .5 & rtw != 0
 
local top10 4 10 18 23 24 29 31 39 40 51
 
foreach k of local top10 {
    preserve
	
	rename rtw rtw`k'
	
    keep if ind_2d == `k'

    * twfe first stage
    reghdfe unmem rtw`k' [pw = pop], absorb(state year) vce(cluster state)

	eststo model_`k'
    
	restore
}

* Estimate effect for all

use "$intm/RTW_Analysis.dta",clear

rename rtw rtwall

collapse  (first) rtw_year  (sum) pop = wt (mean)  unmem rtwall [aw = wt], by(state year)

replace rtwall = 0 if rtwall < .5 & rtwall != 0
replace rtwall = 1 if rtwall >= .5 & rtwall != 0

reghdfe unmem rtwall [pw = pop], absorb(state year) vce(cluster state)

eststo model_all

coefplot model_* , mlabels  mlabp(11) format(%4.3f) keep(rtwall rtw4 rtw10 rtw18 rtw23 rtw24 rtw29 rtw31 rtw39 rtw40 rtw51) xline(0) /*
*/	coeflabels(rtwall  = "All Industries" /*
*/			   rtw4 = "Construction"	  /*
*/			   rtw10 = "Transportation Equipment Manufacturing" /*
*/			   rtw18 = "Petroleum and Coal Products" /*
*/			   rtw23 = "Transportation and Warehousing" /*
*/			   rtw24 = "Utilities" /*
*/			   rtw29 = "Telecommunications" /*
*/			   rtw31 = "Other Information Services" /*
*/			   rtw39 = "Waste Management and Remediation Services" /*
*/			   rtw40 = "Educational services" /*
*/			   rtw51 = "Public administration") legend(off) 

graph export "$figures/TWFE_HetT10.pdf", replace
