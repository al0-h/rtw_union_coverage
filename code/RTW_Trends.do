*============================*
* RTW Trends
*============================*

use "../intm/RTW_Analysis.dta", clear

drop if alwaystreat == 1

local outcomes member covered frider hourwage

g becomesrtw = g_rtw >0
preserve 
collapse (mean) member covered frider hourwage [pw= earnwt],by(year becomesrtw)

foreach outcome in `outcomes'{
	
	local filename "`outcome'"
	if "`outcome'" == "member" 			local filename "mem"
	if "`outcome'" == "covered" 		local filename "cov"
	if "`outcome'" == "frider" 			local filename "frider"
	if "`outcome'" == "hourwage" 		local filename "hourwage"
	
	local ylab "`outcome'"
	if "`outcome'" == "member" 			local ylab "Unionization Rate"
	if "`outcome'" == "covered" 		local ylab "Coverage Rate"
	if "`outcome'" == "frider" 			local ylab "Freerider Rate"
	if "`outcome'" == "hourwage" 		local ylab "Average Hourly Wage"	

	  
	tw 	(line `outcome' year if becomesrtw == 1) ///
		(line `outcome' year if becomesrtw == 0), ///
		legend(order(1 "Ever-adopter states" 2 "Never-RTW states")) ///
		ytitle("`ylab'") xtitle("Year") legend(pos(3)	///
		bplacement(SW) ring(0))ylabel(, grid glpattern(solid)		///
		glcolor(black%10)) xlabel( ,nogrid)	
		
	graph export "../presentations/Figures/Trends/trend_`filename'.pdf",replace

	
}
restore 

keep if covered == 1

local outcomes member frider hourwage

collapse (mean) member frider hourwage [pw= earnwt],by(year becomesrtw)


foreach outcome in `outcomes'{
	
	local filename "`outcome'"
	if "`outcome'" == "member" 			local filename "mem"
	if "`outcome'" == "covered" 		local filename "cov"
	if "`outcome'" == "frider" 			local filename "frider"
	if "`outcome'" == "hourwage" 		local filename "hourwage"
	
	local ylab "`outcome'"
	if "`outcome'" == "member" 			local ylab "Unionization Rate"
	if "`outcome'" == "covered" 		local ylab "Coverage Rate"
	if "`outcome'" == "frider" 			local ylab "Freerider Rate"
	if "`outcome'" == "hourwage" 		local ylab "Average Hourly Wage"	

	  
	tw 	(line `outcome' year if becomesrtw == 1) ///
		(line `outcome' year if becomesrtw == 0), ///
		legend(order(1 "Ever-adopter states" 2 "Never-RTW states")) ///
		ytitle("`ylab'") xtitle("Year") legend(pos(3)	///
		bplacement(SW) ring(0))ylabel(, grid glpattern(solid)		///
		glcolor(black%10)) xlabel( ,nogrid)	
		
	graph export "../presentations/Figures/Trends/trend_cond`filename'.pdf",replace

	
}	
