/****************************************************************************
* Script   : 01a_Create_CPS_RTW_ind.do
*
* PROJECT  : RTW Project
* PURPOSE  : Create main dataset; Generates the RTW key for panel data 
*
* CREATED  : 23 May 2025
*
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
* INPUTS   : - ../Data/RTW_Years.xlsx
*
* OUTPUTS  : - ../Intm/RTW_States.dta
*
****************************************************************************/

log using "Logs/01a_Create_CPS_RTW_ind", replace


* RTW data excel sheet has the year and month that the right to work laws were passed.
* ... sources can be found hyperlinked in the excel spreadsheet
import excel "../data/RTW_Years.xlsx", sheet("Sheet1") firstrow clear

* Generate years variables
expand year
bys state: replace year = 1979
bys	state: replace year = year[_n-1]+1 if _n > 1

* Generate months variables
expand month
bys state year: replace month = 1
bys	state year: replace month = month[_n-1]+1 if _n > 1

sort state year month

* Generate RTW status based on month and year implementation

gen double adopt_date = ym(rtw_year , rtw_month)
format adopt_date %tm

gen double obs_date   = ym(year , month)
format obs_date %tm

gen rtw = obs_date >= adopt_date  if !missing(adopt_date)
replace rtw = 0 if missing(adopt_date)

* The states that have always had RTW laws through out our sample window
gen alwaystreatcondtreat = adopt_date < ym(2002,1) if !missing(adopt_date)  

g alwaystreat = adopt_date < ym(2002,1) 
	
drop obs_date adopt_date
	
rename (state icpsr_code) (state_name state) // change names to be CPS ready

keep if year >= 1983 & year <= 2023

save "../intm/RTW_States", replace

log close

