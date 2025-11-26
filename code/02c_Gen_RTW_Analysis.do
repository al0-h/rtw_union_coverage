/****************************************************************************
* SCRIPT   : 01b_Gen_Appended.do 
*
* PURPOSE  : Append all the ORG CPS data together	
*
* CREATED  : 23 May 2025
*
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
* INPUTS   : - 
*
* OUTPUTS  : - ../Intm/Appended_CPS_ORG.dta
*
* NOTES	   : - 2003-2019 for same reasons as in Fortin et al. 2022	
*
****************************************************************************/

log using "Logs/01b_Gen_Appended", replace	

* Load CPS &  Universe: wage/salary employees (private + public), ages 18–64, in ORG
use "../data/cps_rtw_2003_2019.dta" if inrange(age,18,64) & inlist(empstat,10,12) & ///
  inlist(classwkr,21,22,23,24,25,27,28) & eligorg==1, clear

rename statefip state_cps
merge m:1 state_cps year month using "../intm/RTW_States.dta", nogen keep(match)
replace rtw = 0 if missing(rtw)

* Clean fields (IPUMS CPS-ORG see documentation)
replace hourwage = . if hourwage==999.99
replace jtyears  = . if inlist(jtyears,99.96,99.97,99.98,99.99)
replace educ = . if inlist(educ, 0, 1, 2, 999)


* Union: 1=not member, 2=member, 3=covered (0=NIU)
gen member  = union==2          	if union!=0 
gen byte frider  = (union==3)       if union!=0 // freerider 
gen covered = inlist(union,2,3)     if union!=0
drop if missing(covered)

preserve

keep if inrange(year, 2003, 2011)

* Industry-level weighted mean coverage (using worker weights once)
collapse (mean) covered [aw=earnwt], by(ind)

* Median across industries (no weights now)
summ covered, detail
scalar med_cov = r(p50)

gen high_union_ind = covered > med_cov
label define highu 0 "Low-union industry" 1 "High-union industry"
label values high_union_ind highu

tempfile ind_union
save "`ind_union'", replace

restore

merge m:1 ind using "`ind_union'", nogen

* Annualize RTW defined as ≥6 treated months in the calendar year
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

* Education: 4 groups (refer to IPUMS)
* Treat NIU/missing codes as missing
replace educ = . if inlist(educ, 0, 1, 999)

* Create 4-category education variable
gen byte ed4 = .

* 1 = HS or less: 002–073
replace ed4 = 1 if inrange(educ, 2, 73)

* 2 = Some college, no BA: 080,081,090,091,092,100
replace ed4 = 2 if inlist(educ, 80, 81, 90, 91, 92, 100)

* 3 = BA: 110 or 111
replace ed4 = 3 if inlist(educ, 110, 111)

* 4 = Grad/Prof: 120–125
replace ed4 = 4 if inrange(educ, 120, 125)

gen byte hs_or_less   = (ed4 == 1)                 if !missing(ed4)
gen byte some_college = (ed4 == 2)                 if !missing(ed4)
gen byte ba_plus      = inlist(ed4, 3, 4)          if !missing(ed4)

label var hs_or_less   "High school or less"
label var some_college "Some college (incl. AA, <BA)"
label var ba_plus      "BA or more"

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

* Create dummies  occ8_1, ..., occ8_9
tabulate occ8, generate(occ8_)

* Label a few for clarity
label var occ8_1 "Mgmt/Bus/Fin"
label var occ8_2 "Prof"
label var occ8_3 "Service"
label var occ8_4 "Sales"
label var occ8_5 "Office/Admin"
label var occ8_6 "Constr/Extr"
label var occ8_7 "Production"
label var occ8_8 "Transport/Moving"
label var occ8_9 "Occupation unknown"

* education dummies (if you don't already have them)
tab ed4, gen(ed4_)   // ed4_1, ed4_2, ed4_3, ed4_4



* Dummies: race, marital, public sector, part-time, MSA

gen black     = (race==200)
gen hisp      = (hispan>0)
gen white = (race == 100 & hisp == 0)
label var white "Non-Hispanic White"
gen female	  = sex == 2
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
	
* Log wage
gen lnwage = ln(hourwage) if hourwage>0 & hourwage<.


* Define groups
gen new_adopter =  !mi(rtw_year) & alwaystreat  != 1 
g has_rtw = !mi(rtw_year)
g pre_rtwnew = rtw == 0 if new_adopter == 1 & !mi(rtw_year)

* never RTW, always RTW, and new adopters pre/post
gen group = .
replace group = 1 if has_rtw==0 & new_adopter==0   // never RTW
replace group = 4 if has_rtw==1 & new_adopter==0   // always RTW (RTW all years in sample)
replace group = 2 if pre_rtwnew==1 & new_adopter==1   // new adopters, pre
replace group = 3 if pre_rtwnew==0 & new_adopter==1   // new adopters, post

label define group 1 "Never RTW" 2 "New RTW pre" 3 "New RTW post" 4 "Always RTW"
label values group group

save "../intm/RTW_Analysis.dta", replace

log close
