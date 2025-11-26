/****************************************************************************
* FILE     : 03a_Top_UnionShareInd.do
* PROJECT  : RTW Project
* PURPOSE  : Test the robustness of the first stage of RTW on Union mem
*
* CREATED  : 23 May 2025
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
* INPUTS   : - ../intm/RTW_Analysis.dta
*
* OUTPUTS  : - Top_UnionShareInd.pdf
*
****************************************************************************/

* Top 10 unionized firms from 2003 - 2019
use "$intm/RTW_Analysis.dta" if rtw == 0, clear


* Compute 2003 (pre-treatment) union density and sample size
collapse (mean) pre_union = unmem  (sum) pre_pop = wt, by(ind_2d)

* Keep private, sizeable cells & rank by union density
sort pre_union -pre_pop
list ind_2d pre_union pre_pop in 1/15  // eyeball the top 15

* Pick the top 10 unionised private industries 
egen rank = rank(-pre_union)
keep if rank <= 10
levelsof ind_2d, local(top10)   // stores codes in `top10'

* Plot Union membership shares

* Clean up labels for figures
decode ind_2d, gen(ind2_str) 
replace ind2_str = trim(regexr(ind2_str, " [0-9].*$", ""))

graph hbar pre_union, over(ind2_str,sort(rank))/*
	*/ blabel(bar, position(outside) format(%4.2f) )/*
	*/ title("Union membership rate (pre-RTW)")  ytitle("")
	
graph export "$figures/Top_UnionShareInd.pdf"
