*============================*
* Heterogeneity & Robustness
*============================*


* ─────────────────────────────────────────────
* Covered by Union but not member (conditioned on coverage)
* ─────────────────────────────────────────────
* Full 

preserve 
keep if covered == 1
csdid frider 															///
      i.ed4 															///
      c.pexp c.pexp#c.pexp 												///
      i.black i.hisp i.msa 												///
      [w=earnwt], time(year) gvar(g_rtw) method(dripw) cluster(state) 
	  
estat event, window(-5 5) pretrend
csdid_plot,  title("Simple Free Rider Conditional") 
graph export "../presentations/Figures/simple_fridercond.pdf",replace

estat event, window(-10 10) pretrend
restore 

* Naive
preserve 
keep if covered == 1
csdid frider 															///
	[w=earnwt], time(year) gvar(g_rtw) method(dripw) cluster(state) 
	  
estat event, window(-5 5) pretrend
	csdid_plot, style(rcap)		                                    ///
    title("")                                      ///
    xtitle("Periods to treatment")                                  ///
    ytitle("ATT")                                                   ///
    yline(0, lpattern(solid)) 										///
	ylabel(, grid glpattern(solid) glcolor(black%10))               ///
    xline(0, lcolor(red)) xlabel(-4(1)4, nogrid)					///
	legend(order(1 "Pre-RTW" 3 "Post-RTW") pos(3) bplacement(SW) ring(0) ) 
graph export "../presentations/Figures/simple_fridercond.pdf",replace

estat event, window(-5 5) pretrend
restore 


* ─────────────────────────────────────────────
* Quantile RIF CSdid & TWFE outcomes
* ─────────────────────────────────────────────

use "../intm/RTW_Analysis.dta", clear

drop if alwaystreat == 1 // csdid does this automatically so we do prior

* Quantiles
local taus "10 25 50 75 90"

tempname pf // tempfile for csdid output 
tempfile rifcsdid // tempfile for all results 

postfile `pf' tau att se using "`rifcsdid'", replace

foreach t of local taus {

    di "Running csdid RIF for q(`t')"

    * Create RIF outcome for this quantile
    cap drop rif_lnwage_q`t'
    egen rif_lnwage_q`t' = rifvar(lnwage), q(`t') weight(earnwt)

    * csdid with individual panels
    eststo, prefix(csdid_q`t'): csdid rif_lnwage_q`t' ///
        c.pexp c.pexp#c.pexp ///
        i.ed4 i.female i.white i.black i.hisp ///
        i.occ8 i.public i.msa ///
        [w = earnwt], time(year) gvar(g_rtw) ///
        method(dripw) cluster(state)

    * Overall ATT for that quantile
    estat simple
    matrix R = r(table)
    scalar b  = R[1,1]
    scalar se = R[2,1]

    post `pf' (`t') (b) (se)
}

postclose `pf'

preserve 
use "`rifcsdid'", clear
label var tau "Quantile"
label var att "RTW ATT on log wages (csdid-RIF)"
label var se  "Std. error"

gen ub = att + 1.96*se
gen lb = att - 1.96*se

twoway (rcap ub lb tau) ///
       (connected att tau, msymbol(o) lpattern(solid)), ///
      xlabel(10 25 50 75 90) ///
      xtitle("Unconditional wage quantile") ///
      ytitle("RTW ATT on log hourly wage (csdid-RIF)") ///
      yline(0, lpattern(dash)) ///
      legend(off)

graph export "../presentations/Figures/rtw_rif_quantiles_lnwage_csdid.pdf", replace

restore 

* Define the our 
local taus "10 25 50 75 90"

* Set up a postfile to store results
tempname pf
tempfile rifres

postfile `pf' tau b se using "`rifres'", replace

* Loop over quantiles and run RIF regressions
foreach t of local taus {
    di "Running RIF regression for q(`t')"

	eststo, prefix(TWFE_q`t'):rifhdreg lnwage rtw ///
		c.pexp c.pexp#c.pexp ///
		i.ed4 i.female i.white i.black i.hisp ///
		i.occ8 i.public ///
		i.state i.year ///
		[aw=earnwt], rif(q(`t')) vce(cluster state)


    * Extract RTW coefficient and SE
    matrix bmat = e(b)
    matrix V    = e(V)

    scalar b_rtw  = bmat[1, "rtw"]
    scalar se_rtw = sqrt(V[1,1])

    * Post into results file
    post `pf' (`t') (b_rtw) (se_rtw)
}

preserve 
postclose `pf'

* Load the results as a dataset
use "`rifres'", clear
label var tau "Quantile"
label var b   "RTW effect on log wages"
label var se  "Std. error"

* Build confidence intervals
gen ub = b + 1.96*se
gen lb = b - 1.96*se

* Plot: RTW effect by quantile
twoway (rcap ub lb tau) ///
       (connected b tau, msymbol(o) lpattern(solid)), ///
      xlabel(10 25 50 75 90) ///
      xtitle("Unconditional wage quantile") ///
      ytitle("RTW effect on log hourly wage") ///
      yline(0, lpattern(dash)) ///
      legend(off)

graph export "../presentations/Figures/TWFE_rif_quantiles_lnwage.pdf", replace
restore


* ─────────────────────────────────────────────
* Sun and abraham 2021
* ─────────────────────────────────────────────

use "../intm/RTW_Analysis.dta", clear

drop if alwaystreat == 1

* Define cohort: first year RTW turns 1 within the sample
bysort state: egen rtw_cohort = min(cond(rtw==1, year, .))

* Never-treated indicator (used as control cohort)
gen byte never_treat = missing(rtw_cohort)

* Event time K = year - first RTW year (only defined for treated states)
gen K = year - rtw_cohort if !missing(rtw_cohort)

* Choose the window (more on window choice)
local max_lead = 5     // up to K = -5
local max_lag  = 5     // up to K = +5

* Lags: K = 0,1,...,max_lag
forvalues l = 0/`max_lag' {
    gen L`l' = (K == `l')
}

* Leads: K = -1,-2,...,-max_lead
forvalues f = 1/`max_lead' {
    gen F`f' = (K == -`f')
}

* Drop F1 so K = -1 is the omitted (baseline) period
drop F1

local outcomes lnwage member covered 

foreach outcome in `outcomes'{
	
	local filename "`var'"
	if "`var'" == "covered" 		local filename "cov"
	if "`var'" == "member" 			local filename "mem"
	if "`var'" == "frider" 			local filename "frider"
	if "`var'" == "lnwage" 			local filename "lnwage"	
	
	local ylab "`var'"
	if "`var'" == "covered" 		local ylab "union coverage rate"
	if "`var'" == "member" 			local ylab "union membership rate"
	if "`var'" == "frider" 			local ylab "free‑rider rate"
	if "`var'" == "lnwage" 			local ylab "log hourly wage"	
	
	eststo, prefix(Full_`outcome'ESI): eventstudyinteract `outcome' L* F*, ///
		cohort(rtw_cohort) control_cohort(never_treat) ///
		absorb(state year) vce(cluster state)
		
	event_plot e(b_iw)#e(V_iw), ///
		stub_lag(L#) stub_lead(F#) ///
		trimlag(5) trimlead(5) ///
		default_look ///
		graph_opt( ///
			xtitle("Years relative to RTW adoption (baseline = -1)") ///
			ytitle("Effect on `ylab'") ///
			xline(0, lcolor(red)) xlabel(-4(1)4, nogrid)///
			yline(, grid glpattern(solid) glcolor(black%10)) ///
			legend(order(1 "Pre-RTW" 3 "Post-RTW") pos(3) bplacement(SW) ring(0) ) ///
			style(rcap)
		)
		
	graph export "../presentations/Figures/event_plot_`filename'.pdf",replace
	
}




