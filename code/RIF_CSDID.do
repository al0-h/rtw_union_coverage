*============================*
* RIF CSDID 
*============================*
use "../intm/RTW_Analysis.dta", clear

* match csdid sample
drop if alwaystreat == 1

* Quantiles
local taus "10 25 50 75 90"

tempname pf                // handle for postfile
tempfile rifcsdid          // temp dataset to store results

postfile `pf' tau att se using "`rifcsdid'", replace

foreach t of local taus {

    di "Running csdid RIF for q(`t')"

    * RIF outcome for this quantile
    cap drop rif_lnwage_q`t'
    egen rif_lnwage_q`t' = rifvar(lnwage), q(`t') weight(earnwt)

    * csdid for this RIF outcome
    eststo, prefix(csdid_q`t'): csdid rif_lnwage_q`t' ///
        c.pexp c.pexp#c.pexp ///
        i.ed4 i.female i.white i.black i.hisp ///
        i.occ8 i.public i.msa ///
        [w = earnwt], time(year) gvar(g_rtw) ///
        method(dripw) cluster(state)

    * overall ATT for that quantile
    estat simple
    matrix R = r(table)
    scalar b  = R[1,1]
    scalar se = R[2,1]

    post `pf' (`t') (b) (se)
}

postclose `pf'


use "`rifcsdid'", clear

label var tau "Unconditional wage quantile"
label var att "RTW ATT on log wages (csdid-RIF)"
label var se  "Std. error"

* confidence intervals
gen ub = att + 1.96*se
gen lb = att - 1.96*se

* convert to percent changes
gen att_pct = (exp(att) - 1)*100
gen lb_pct  = (exp(lb)  - 1)*100
gen ub_pct  = (exp(ub)  - 1)*100

* -------- vertical coef-style plot --------

twoway ///
    (rcap ub_pct lb_pct tau, sort) ///
    (connected att_pct tau, msymbol(o) lpattern(solid)), ///
    xlabel(10 25 50 75 90, nogrid) ///
    xtitle("Unconditional wage quantile") ///
    ytitle("Percent change in hourly wage") ///
    yline(0, lpattern(dash)) ///
    ylabel(, grid glpattern(solid) glcolor(black%10)) ///
    legend(off)

graph export "../presentations/Figures/rtw_rif_quantiles_pctwage_csdid.pdf", replace

