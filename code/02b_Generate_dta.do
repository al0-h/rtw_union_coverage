/****************************************************************************
* SCRIPT   : 02b_Generate_dta.do 
*
* PURPOSE  : Merge together IPUMS CPS extract
*
* CREATED  : 23 May 2025
*
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
* INPUTS   : - All the .dta files from the IPUMS extract
*
* OUTPUTS  : - ../Intm/cps_rtw_2003_2019.dta
*
* NOTES	   : -  
*
****************************************************************************/

log using "../code/Logs/02b_Generate_dta", replace	

cd "../data/CPS_Extract"


* Get a list of all matching files in this folder
local files : dir "." files "cps_rtw_2003_2019_part*.dta"

* Grab the first file and use it as the starting dataset
local first : word 1 of `files'
use "`first'", clear

* Remove the first file from the list, then loop over the rest
local rest : list files - first

foreach f of local rest {
    qui di "Appending `f'"
    qui append using "`f'"
}

rename _all, lower // Subsequent scripts are written with lowercase variables

cd "../../code" // Change working directory back to ../code


save "../data/cps_rtw_2003_2019.dta", replace

log close

