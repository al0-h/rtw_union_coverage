/*******************************************************************************
* FILE     : 00_Master.do
* PROJECT  : RTW Project
* PURPOSE  : Complies all the STATA scripts for the analysis of the paper
*
* CREATED  : 23 May 2025
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
********************************************************************************/


* 	  Settings	     *
**********************

clear all
set more off
version 18.5
set seed 20250115     

net install scheme-modern, from("https://raw.githubusercontent.com/mdroste/stata-scheme-modern/master/")
net install grc1leg,from( http://www.stata.com/users/vwiggins/) 
set scheme modern

* 	    Paths		 *
**********************

cd "`c(pwd)'"  


/* ────────────────────────────────────────────────────────────────────────── *
 *                              Main Scripts   					              *
 * ────────────────────────────────────────────────────────────────────────── */

do "02a_Create_CPS_RTW_ind.do"  // Prepares RTW_Years data set for panel data

do "02b_Generate_dta.do"	// Appends Chunked IPUMS extract

do "02c_Gen_RTW_Analysis.do"	// Generate the main dataset for Analysis

do "Summary_Statistics.do"

do "RTW_Trends.do"

do "Main_CSDID.do"

do "RIF_CSDID.do"

do "Heterogeneity_Robustness.do"

file open done using "../data/stata_done.flag", write replace
file close done
display "Created data/stata_done.flag"



