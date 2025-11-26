/*	
				CSDID estimates by Top 10 unionized industries 
 * ─────────────────────────────────────────────────────────────────────── */


* Generate effect by industry
use "$intm/RTW_Analysis.dta", clear

est clear

collapse (first) rtw_year (sum) pop = wt                                     ///
         (mean) unmem rtw , ///
         by(state year ind_2d)

replace rtw = 0 if rtw < .5 & rtw != 0
replace rtw = 1 if rtw >= .5 & rtw != 0
 
local top10 4 10 18 23 24 29 31 39 40 51
 
foreach k of local top10 {
    preserve
	
    keep if ind_2d == `k'

    * csdid first stage
	csdid unmem [iw = pop], ivar(state) time(year) gvar(rtw_year) method(dripw) post
	
	estat simple, post
	eststo model_`k'
    
	restore
}

* Estimate effect for all

use "$intm/RTW_Analysis.dta",clear

collapse  (first) rtw_year  (sum) pop = wt (mean)  unmem  [aw = wt], by(state year)


csdid unmem [iw = pop], ivar(state) time(year) gvar(rtw_year) method(dripw) post

estat simple, post
eststo model_all


coefplot                                                      ///
    (model_4 ,  label("Construction"))                        ///
    (model_10,  label("Transportation Equip. Mfg"))           ///
    (model_18,  label("Petroleum & Coal Products"))           ///
    (model_23,  label("Transportation & Warehousing"))        ///
    (model_24,  label("Utilities"))                           ///
    (model_29,  label("Telecommunications"))                  ///
    (model_31,  label("Other Information Services"))          ///
    (model_39,  label("Waste Mgmt & Remediation"))            ///
    (model_40,  label("Educational Services"))                ///
    (model_51,  label("Public Administration"))               ///
    (model_all, label("All Industries")), xline(0) ytitle("") mlabels mlabp(11) format(%4.3f)

graph export "$figures/CSDID_HetT10.pdf", replace



use "$intm/RTW_Analysis.dta" if rural == 1 ,clear

collapse  (first) rtw_year  (sum) pop = wt (mean)  unmem  lnrw [aw = wt], by(state year)

replace rtw_year = . if mi(rtw_year)

csdid unmem [iw = pop], ivar(state) time(year) gvar(rtw_year) method(dripw) post
estat event, window(-10 10)
csdid_plot

csdid lnrw [iw = pop], ivar(state) time(year) gvar(rtw_year) method(dripw) post
estat event, window(-10 10)
csdid_plot

