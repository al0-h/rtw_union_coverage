* ──────────────────────────────────────────────── *
* main outcomes									   *
* ──────────────────────────────────────────────── *

use "../intm/RTW_Analysis.dta", clear

drop if alwaystreat == 1 // csdid does this automatically so we do prior
 
local outcomes covered member frider lnwage 


* Main Full Specification

foreach var in `outcomes'{

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
	  
	  
	eststo, prefix(Full_`var'): csdid `var'		///
		c.pexp c.pexp#c.pexp 					///
		i.ed4 i.female i.white i.black i.hisp 	///
		i.occ8 i.public i.msa					///
		[w=earnwt], time(year) gvar(g_rtw) method(dripw) cluster(state) // internally pw are used. holds for aw and w see https://www.statalist.org/forums/forum/general-stata-discussion/general/1709369-adding-weight-in-callaway-and-sant-anna-diff-in-diff

	estat event, window(-5 5) pretrend
	
	csdid_plot, style(rcap) 												///
	title("") xtitle("Years relative to RTW adoption") 						///
	ytitle("Average treatment effect on `ylab'") yline(0, lpattern(solid)) 	///
	ylabel(, grid glpattern(solid) glcolor(black%10))               		///
	xline(0, lcolor(red)) xlabel(-4(1)4, nogrid)							///
	legend(order(1 "Pre-RTW" 3 "Post-RTW") pos(3) bplacement(SW) ring(0) ) 	
	
	graph export "../presentations/Figures/csdid/Full_`filename'.pdf",replace
	
}


* Naive csdid specifications 

foreach var in `outcomes'{
	
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

	
	eststo, prefix(Naive_`var'): csdid `var' ///
	[w=earnwt], time(year) gvar(g_rtw) method(dripw) cluster(state)  
		// internally pw are used. holds for aw and w see https://www.statalist.org/forums/forum/general-stata-discussion/general/1709369-adding-weight-in-callaway-and-sant-anna-diff-in-diff
	
	estat event, window(-5 5) pretrend
	
	csdid_plot, style(rcap) 												///
	title("") xtitle("Years relative to RTW adoption") 						///
	ytitle("Average treatment effect on `ylab'") yline(0, lpattern(solid)) 	///
	ylabel(, grid glpattern(solid) glcolor(black%10))               		///
	xline(0, lcolor(red)) xlabel(-4(1)4, nogrid)							///
	legend(order(1 "Pre-RTW" 3 "Post-RTW") pos(3) bplacement(SW) ring(0) ) 	
	
	graph export "../presentations/Figures/csdid/Naive_`filename'.pdf",replace

}


* High vs low union participating unions

foreach i in 0 1{
	foreach var in `outcomes'{
	
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
	  
	local part "`i'"
	if "`var'" == "0" 				local part "low"
	if "`var'" == "1" 				local part "high"

	
	  
	eststo, prefix(Full`part'_`var'): csdid `var'		///
		c.pexp c.pexp#c.pexp 					///
		i.ed4 i.female i.white i.black i.hisp 	///
		i.occ8 i.public i.msa					///
		if high_union_ind == `i' [w=earnwt], time(year) gvar(g_rtw) method(dripw) cluster(state) // internally pw are used. holds for aw and w see https://www.statalist.org/forums/forum/general-stata-discussion/general/1709369-adding-weight-in-callaway-and-sant-anna-diff-in-diff
	
	estat event, window(-5 5) pretrend
	
	csdid_plot, style(rcap) 												///
	title("") xtitle("Years relative to RTW adoption") 						///
	ytitle("Average treatment effect on `ylab'") yline(0, lpattern(solid)) 	///
	ylabel(, grid glpattern(solid) glcolor(black%10))               		///
	xline(0, lcolor(red)) xlabel(-4(1)4, nogrid)							///
	legend(order(1 "Pre-RTW" 3 "Post-RTW") pos(3) bplacement(SW) ring(0) ) 
	
	graph export "../presentations/Figures/csdid/`part'_UNFull_`filename'.pdf",replace
	
	}
}



* MAP PREFIXES -> ACTUAL ESTIMATE NAMES (handles ...1, ...2) *

eststo dir
local all `r(names)'

local specs    "Full Naive Full1 Full0"          
local outcomes "member covered frider lnwage"

foreach s of local specs {
    foreach v of local outcomes {
        local key "`s'_`v'"
        local len = strlen("`key'")
        local est_`s'_`v' ""
        foreach nm of local all {
            if substr("`nm'",1,`len') == "`key'" {
                local est_`s'_`v' "`nm'"
            }
        }
    }
}

* TABLE 2: RTW effects on union outcomes and log wages  
* Grab sample sizes once (use lnwage specs; N is the same)   

est restore `est_Naive_lnwage'
local N1 : display %9.0f e(N)

est restore `est_Full_lnwage'
local N2 : display %9.0f e(N)

est restore `est_Full1_lnwage'
local N3 : display %9.0f e(N)

est restore `est_Full0_lnwage'
local N4 : display %9.0f e(N)


label var covered  "Union coverage rate"
label var member   "Union membership rate"
label var frider   "Free-rider rate"
label var lnwage   "Log hourly wage"

file open tex using "../presentations/Tables/table2_rtw_union_wage.tex", write replace


file write tex "\begin{tabular}{l d{-3} d{-3} d{-3} d{-3}}" 
file write tex "\toprule" _n
file write tex " & \multicolumn{1}{c}{No controls}" ///
               " & \multicolumn{1}{c}{Baseline csdid}" ///
               " & \multicolumn{1}{c}{High-union industries}" ///
               " & \multicolumn{1}{c}{Low-union industries} \\" _n
file write tex " & \multicolumn{1}{c}{(1)}" ///
               " & \multicolumn{1}{c}{(2)}" ///
               " & \multicolumn{1}{c}{(3)}" ///
               " & \multicolumn{1}{c}{(4)} \\" _n
file write tex "\midrule" _n

foreach v of local outcomes {

    local lab : variable label `v'

    * (1) No controls: Naive_`v'
    est restore `est_Naive_`v''
    quietly estat simple
    matrix T = r(table)
    local b1  : display %6.3f T[1,1]
    local se1 : display %6.3f T[2,1]

    * (2) Baseline csdid: Full_`v'
    est restore `est_Full_`v''
    quietly estat simple
    matrix T = r(table)
    local b2  : display %6.3f T[1,1]
    local se2 : display %6.3f T[2,1]

    * (3) High-union industries: Full1_`v'
    est restore `est_Full1_`v''
    quietly estat simple
    matrix T = r(table)
    local b3  : display %6.3f T[1,1]
    local se3 : display %6.3f T[2,1]

    * (4) Low-union industries: Full0_`v'
    est restore `est_Full0_`v''
    quietly estat simple
    matrix T = r(table)
    local b4  : display %6.3f T[1,1]
    local se4 : display %6.3f T[2,1]

    * Coefficient row
    file write tex "`lab'" ///
        " & `b1'" ///
        " & `b2'" ///
        " & `b3'" ///
        " & `b4' \\\\" _n

    * SE row
    file write tex " & (`se1')" ///
        " & (`se2')" ///
        " & (`se3')" ///
        " & (`se4') \\\\[0.3em]" _n
}

file write tex "\midrule" _n
file write tex "Number of observations" ///
    " & \multicolumn{1}{c}{`N1'}" ///
    " & \multicolumn{1}{c}{`N2'}" ///
    " & \multicolumn{1}{c}{`N3'}" ///
    " & \multicolumn{1}{c}{`N4'} \\\\" _n
file write tex "\bottomrule" _n
file write tex "\end{tabular}" _n _n


file close tex

