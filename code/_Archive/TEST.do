*============================*
* FIGURE 1 — RTW → COVERAGE *
*============================*


cap mkdir "graphs"

* --- 1) Load micro and merge monthly RTW ---
use "$data/cps_00009.dta", clear

rename statefip state_cps

merge m:1 state_cps year month using "$intm/RTW_States.dta", nogen
drop state
rename state_cps state
replace rtw = 0 if missing(rtw)

* --- 2) ORG universe (build coverage on full ORG; NO wage filters) ---
keep if inrange(age,18,64) & inlist(empstat,10,12) & inlist(classwkr,21,22,23) & eligorg==1

* Check the implications for the refuse to anwser people and dont know and no response remove for now 

replace jtyears = . if inlist(jtyears,99.96,99.97,99.98,99.99)

gen byte covered = inlist(union,2,3) if union != 0
label var covered "Member or covered by union contract"
replace hourwage  = . if hourwage == 999.99
egen racexhispan = group(race hispan)
egen indxyear = group(ind year)
egen educxjtyears = group(educ jtyears)


gen agecat = .
replace agecat = 0 if !mi(age) & age <=  29
replace agecat = 1 if !mi(age) & age >  29 & age <=  40
replace agecat = 2 if !mi(age) & age >  40 & age <=  50
replace agecat = 3 if !mi(age) & age >  50 



* --- 3) Annualize RTW from monthly indicator (any-month rule) ---
preserve
keep state year month rtw
collapse (max) rtw, by(state year)
rename rtw rtw_y
tempfile rtw_y
save `rtw_y', replace
restore

* --- 4) Collapse to state×industry×year: coverage (EARNWT-weighted) ---
collapse (mean) covered = covered [pw= earnwt], by(state year ind agecat racexhispan indxyear sex marst educ jtyears educxjtyears)
//g lnwage = ln(hourwage)

//label var covered "Union contract coverage (EARNWT-weighted)"
merge m:1 state year using `rtw_y', nogen keep(master match)

* --- 5) Panel ID + cohort (first treated year). 0 = never treated ---
egen id = group(state year)
egen statexyear = group(state year)
bys state (year): egen int g_rtw = min(cond(rtw_y==1, year, .))
replace g_rtw = 0 if missing(g_rtw)


 xtset year // need for covariates 
* --- 6) Event-study with CSDID ---
csdid covered agecat racexhispan indxyear sex marst educ jtyears educxjtyears, ivar(id) time(year) gvar(g_rtw) method(dripw) cluster(statexyear)
estat event, window(-10 10)
csdid_plot

estat calendar
csdid_plot
 
 *************
 *************
 *************
 *************
 *************
 *************
 *------------------ PREP ------------------*
use "$data/cps_00009.dta", clear
* drop the sample 25 once you're done debugging
rename statefip state_cps
merge m:1 state_cps year month using "$intm/RTW_States.dta", nogen
drop state
rename state_cps state

keep if inrange(age,18,64) & inlist(empstat,10,12) & inlist(classwkr,21,22,23) & eligorg==1
replace jtyears = . if inlist(jtyears,99.96,99.97,99.98,99.99)
gen byte covered = inlist(union,2,3) if union!=0
replace hourwage = . if hourwage==999.99
replace educ = . if educ == 999

* Annualize RTW with ≥6 treated months 
preserve
keep state year month rtw
bys state year: egen m_treated = total(rtw)
gen rtw_y = (m_treated >= 6)
keep state year rtw_y
collapse (max) rtw, by(state year)
tempfile rtw_y
save `rtw_y'
restore

* --- build the indicator vars BEFORE collapse ---
gen lnwage   = ln(hourwage)           if hourwage<. & hourwage>0
gen fem      = (sex==2)               if !missing(sex)
gen black    = (race==200)            if !missing(race)
gen hisp     = (hispan>0)             if !missing(hispan)
gen married  = inlist(marst,1,2)      if !missing(marst)
* adjust the EDUC range to your coding (check: tab educ, nolabel)
gen bach     = inrange(educ,80,125)   if !missing(educ)

* ------------------ COLLAPSE to state×industry×year ------------------ *
collapse (mean)                                                           ///
    covered        = covered                                              ///
    mean_age       = age                                                  ///
    mean_jtyears   = jtyears                                              ///
    share_female   = fem                                                  ///
    share_black    = black                                                ///
    share_hisp     = hisp                                                 ///
    share_married  = married                                              ///
    share_bach     = bach                                                 ///
    mean_lnwage    = lnwage                                               ///
    [pw=earnwt], by(state ind year)

* panel id = state × industry
egen long id = group(state ind)

* merge RTW (state-year) if you haven't already done it post-collapse
merge m:1 state year using `rtw_y', nogen keep(master match)

* cohort: first treated year (0 = never)
bys state (year): egen int g_rtw = min(cond(rtw_y==1, year, .))
replace g_rtw = 0 if missing(g_rtw)

* ------------------ CSDID with cell-means covariates ------------------ *
csdid covered                                                            ///
      mean_age mean_jtyears share_female share_black share_hisp          ///
      share_married share_bach                                           ///
      , ivar(id) time(year) gvar(g_rtw) method(dripw) cluster(state)

estat event, window(-10 10) pretrend
csdid_plot
 *************
 *************
 *************
 *************
 *************
 ************* *************
 *************
 *************
 *************
 *************
 
 
* 1) Load CPS & merge monthly RTW (rtw==1 only when law is EFFECTIVE)
use "$data/cps_00014.dta", clear
*sample 10
rename statefip state_cps
merge m:1 state_cps year month using "$intm/RTW_States.dta", nogen
drop state
rename state_cps state
replace rtw = 0 if missing(rtw)

* 2) Universe: wage/salary employees (private + public), ages 18–64, in ORG
keep if inrange(age,18,64) & inlist(empstat,10,12) &  inlist(classwkr,21,22,23,24,25,27,28) & eligorg==1

* 3) Clean fields (IPUMS CPS-ORG)
replace hourwage = . if hourwage==999.99
replace jtyears  = . if inlist(jtyears,99.96,99.97,99.98,99.99)
replace educ     = . if educ==999

* Union: 1=not member, 2=member, 3=covered (0=NIU)
gen member  = union==2          	if union!=0 
gen byte frider  = (union==3)       if union!=0 // freerider (covered but not mem)
gen covered = inlist(union,2,3)     if union!=0
drop if missing(covered)

* 4) Annualize RTW: ≥6 treated months in the calendar year
preserve
keep state year month rtw
bys state year: egen m_treated = total(rtw)
gen rtw_y = (m_treated >= 6)
keep state year rtw_y
collapse (max) rtw, by(state year)
tempfile rtw_y
save `rtw_y'
restore
merge m:1 state year using `rtw_y', nogen keep(master match)

* 5) Treatment cohort (first EFFECTIVE year; 0 = never)
bys state (year): egen g_rtw = min(cond(rtw_y==1, year, .))
replace g_rtw = 0 if missing(g_rtw)

* 6) Fortin-style covariates
* (a) Education: 4 groups (adjust if your EDUC coding differs: check `tab educ, nolabel`)
gen byte ed4 = .
replace ed4 = 1 if inrange(educ,  2, 73)   // ≤HS
replace ed4 = 2 if inrange(educ, 74, 79)   // Some college / AA
replace ed4 = 3 if educ==80                // BA
replace ed4 = 4 if inrange(educ, 81,125)   // Grad/Prof

* Approx years of education for potential experience
gen edyrs = .
replace edyrs = 12 if ed4==1
replace edyrs = 14 if ed4==2
replace edyrs = 16 if ed4==3
replace edyrs = 18 if ed4==4

* Potential experience & quartic
gen pexp = age - edyrs - 6
replace pexp = 0 if pexp<0
gen pexp2 = pexp^2
gen pexp3 = pexp^3
gen pexp4 = pexp^4

* 4 experience groups (quartiles).  (Alt: fixed bins 0–9/10–19/20–29/30+)
xtile exp4 = pexp, nq(4)

* (b) Eight occupation groups (2010 Census OCC codes; tweak if needed)
* If your file has occ2010, swap in that variable.
gen byte occ8 = .
replace occ8 = 1 if inrange(occ, 0010, 0950)   // Mgt/Business/Finance
replace occ8 = 2 if inrange(occ, 1000, 3540)   // Professional (incl. health)
replace occ8 = 3 if inrange(occ, 3600, 4650)   // Service
replace occ8 = 4 if inrange(occ, 4700, 4960)   // Sales
replace occ8 = 5 if inrange(occ, 5000, 5940)   // Office/Admin
replace occ8 = 6 if inrange(occ, 6200, 6940)   // Construction/Extraction
replace occ8 = 7 if inrange(occ, 7000, 7960)   // Production
replace occ8 = 8 if inrange(occ, 8000, 9750)   // Transport/Moving
gen byte miss_occ8 = missing(occ8)
replace occ8 = 0 if missing(occ8)           // create an "unknown" category
label define occ8lbl 0 "unk" 1 "Mgmt/Bus/Fin" 2 "Prof" 3 "Service" 4 "Sales" ///
                     5 "Office" 6 "Constr/Extr" 7 "Production" 8 "Transport", modify
label values occ8 occ8lbl

* (c) Dummies: race, marital, public sector, part-time, MSA
gen black     = (race==200)
gen hisp      = (hispan>0)
gen public    = inlist(classwkr,24,25,26)

gen parttime = .
capture confirm variable uhrsworkorg
    qui replace parttime = (uhrsworkorg<35) if _rc==0 & !missing(uhrsworkorg)
gen byte miss_parttime = missing(parttime)
replace parttime = 0 if missing(parttime)

gen msa = .
capture confirm variable metro 
qui replace msa = inlist(metro,2,3,4) if _rc==0 & !missing(metro) 
capture confirm variable metarea 
qui replace msa = (metarea>0) if missing(msa) & _rc==0 & !missing(metarea)
gen byte miss_msa = missing(msa)
replace msa = 0 if missing(msa)	
	
* Industry variable for interactions (ensure it exists)
capture confirm variable ind
if _rc {
    capture confirm variable ind1990
    if !_rc rename ind1990 ind
}

* Log wage
gen lnwage = ln(hourwage) if hourwage>0 & hourwage<.

* Low-wage share (e.g. < $15/hr in 2019 $)
local THRESH = 15
gen loww = (hourwage < `THRESH') if hourwage<.

* compute weighted p10/p90 by state×year and save them
preserve
    keep if lnwage<. & earnwt<.
    collapse (p10) p10=lnwage (p90) p90=lnwage [pw=earnwt], by(state year)
    gen gap_p90_p10 = p90 - p10
    tempfile gaps
    save `gaps'
restore

* bring them back to micro
merge m:1 state year using `gaps', nogen keep(master match)


save "$intm/RTW_Analysis.dta", replace


 * Main Analysis
use "$intm/RTW_Analysis.dta", clear

keep if inrange(year,2003,2019) // Main Sample Window

drop if alwaystreat == 1


* main outcomes 

local outcomes covered member frider lnwage gap_p90_p10


* Main Full Specification

foreach var in `outcomes'{
	
	local xlab "`var'"
	if "`var'" == "covered" 		local xlab "Coverage"
	if "`var'" == "member" 			local xlab "Membership"
	if "`var'" == "frider" 			local xlab "Unconditional Free Rider"
	if "`var'" == "lnwage" 			local xlab "Log Hourly Wage"	
	if "`var'" == "gap_p90_p10" 	local xlab "Gap Between 90th and 10th Percentiles"	

	
	local filename "`var'"
	if "`var'" == "covered" 		local filename "cov"
	if "`var'" == "member" 			local filename "mem"
	if "`var'" == "frider" 			local filename "frider"
	if "`var'" == "lnwage" 			local filename "lnwage"	
	if "`var'" == "gap_p90_p10" 	local filename "gap"	

	
	csdid `var'                                                         ///
      i.ed4 															///
      c.pexp c.pexp#c.pexp 												///
      i.black i.hisp i.msa 												///
      [w=earnwt], time(year) gvar(g_rtw) method(dripw) cluster(state)  // internally pw are used. holds for aw and w see https://www.statalist.org/forums/forum/general-stata-discussion/general/1709369-adding-weight-in-callaway-and-sant-anna-diff-in-diff
	
	estat event, window(-10 10) pretrend
	csdid_plot,  title("Full Model Unconditional Free Rider")
	graph export "$figures/Full_`filename'.pdf",replace
	
}


* simples specifications 

foreach var in `outcomes'{
	
	local xlab "`var'"
	if "`var'" == "covered" 		local xlab "Coverage"
	if "`var'" == "member" 			local xlab "Membership"
	if "`var'" == "frider" 			local xlab "Unconditional Free Rider"
	if "`var'" == "lnwage" 			local xlab "Log Hourly Wage"	
	if "`var'" == "gap_p90_p10" 	local xlab "Gap Between 90th and 10th Percentiles"	

	
	local filename "`var'"
	if "`var'" == "covered" 		local filename "cov"
	if "`var'" == "member" 			local filename "mem"
	if "`var'" == "frider" 			local filename "frider"
	if "`var'" == "lnwage" 			local filename "lnwage"	
	if "`var'" == "gap_p90_p10" 	local filename "gap"	

	
	csdid `var' [w=earnwt], time(year) gvar(g_rtw) method(dripw) cluster(state)  
		// internally pw are used. holds for aw and w see https://www.statalist.org/forums/forum/general-stata-discussion/general/1709369-adding-weight-in-callaway-and-sant-anna-diff-in-diff
	
	estat event, window(-10 10) pretrend
	csdid_plot,  title("Simple `xlab'")
	graph export "$figures/simple_`filename'.pdf",replace
	
}


* ------------------------
* Covered by Union but not member (conditioned on coverage)
* ------------------------

* Full 
preserve 
keep if covered == 1
csdid frider 															///
      i.ed4 															///
      c.pexp c.pexp#c.pexp 												///
      i.black i.hisp i.msa 												///
      [w=earnwt], time(year) gvar(g_rtw) method(dripw) cluster(state) 
	  
estat event, window(-10 10) pretrend
csdid_plot,  title("Simple Free Rider Conditional") 
graph export "$figures/simple_fridercond.pdf",replace

estat event, window(-10 10) pretrend
restore 

* Simple
preserve 
keep if covered == 1
csdid frider 															///
	[w=earnwt], time(year) gvar(g_rtw) method(dripw) cluster(state) 
	  
estat event, window(-10 10) pretrend
csdid_plot,  title("Simple Free Rider Conditional") 
graph export "$figures/simple_fridercond.pdf",replace

estat event, window(-10 10) pretrend
restore 

* Employer-provided benefits (ASEC linkage)
preserve 
collapse (mean) phinsur_rate=phinsur pension_rate=pension  (first) g_rtw [pw=asecwth], by(state year)

csdid phinsur_rate, ivar(state) time(year) gvar(g_rtw) method(stdipw) 
estat event, window(-10 10) pretrend
csdid_plot,  title("Employer-provided benefits") 
graph export "$figures/Asec_benefits.pdf",replace
restore 



* placebo cutoffs 

* changing widnows 

* increasing pre trend timing 



