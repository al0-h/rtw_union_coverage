*============================================================*
*  Table 1: Summary statistics by RTW status 				 *
*============================================================*

use "../intm/RTW_Analysis.dta", clear

* Group labels - the column names
label define grouplbl ///
    1 "Never RTW" ///
    2 "New RTW (pre)" ///
    3 "New RTW (post)" ///
    4 "Always RTW"
label values group grouplbl

* Variables in the order we want them to appear
local sumvars ///
    covered member ///                        // 1–2  Union status
    lnwage age female ///                     // 3–5  Demographics
    white black hisp ///                      // 6–8  Race/ethnicity
    hs_or_less some_college ba_plus ///       // 9–11 Education
    occ8_2 occ8_3 occ8_7 public               // 12–15 Occupation/sector

* Nice labels for the rows
label var covered       "Union covered"
label var member        "Union member"
label var lnwage        "Log hourly wage"
label var age           "Age"
label var female        "Female"
label var white         "Non-Hispanic White"
label var black         "Non-Hispanic Black"
label var hisp          "Hispanic"
label var hs_or_less    "High school or less"
label var some_college  "Some college or AA"
label var ba_plus       "Bachelors or more"
label var occ8_2        "Professional occupation"
label var occ8_3        "Service occupation"
label var occ8_7        "Production occupation"
label var public        "Public sector"

*------------------------------------------------------------*
* Open LaTeX file                                            *
*------------------------------------------------------------*
file open tex using "../presentations/Tables/table1_sumstats.tex", write replace

file write tex "\begin{table}[htbp]" _n
file write tex "\centering" _n
file write tex "\caption{Summary statistics by right-to-work status}" _n
file write tex "\label{tab:sumstats_rtw}" _n
file write tex "\begin{tabular}{l d{-3} d{-3} d{-3} d{-3} d{-3} d{-3}}" _n
file write tex "\toprule" _n
file write tex " & \multicolumn{1}{c}{Total}" ///
               " & \multicolumn{1}{c}{Never RTW}" ///
               " & \multicolumn{1}{c}{New RTW (pre)}" ///
               " & \multicolumn{1}{c}{New RTW (post)}" ///
               " & \multicolumn{1}{c}{Always RTW}" ///
               " & \multicolumn{1}{c}{\emph{p}-value} \\" _n
file write tex " & \multicolumn{1}{c}{(1)}" ///
               " & \multicolumn{1}{c}{(2)}" ///
               " & \multicolumn{1}{c}{(3)}" ///
               " & \multicolumn{1}{c}{(4)}" ///
               " & \multicolumn{1}{c}{(5)}" ///
               " & \multicolumn{1}{c}{(3)--(2)} \\" _n
file write tex "\midrule" _n

*------------------------------------------------------------*
* Loop over variables with section headers                   *
*------------------------------------------------------------*
local i = 0

foreach v of local sumvars {
    local ++i

    * Section headers at specific positions
    if `i' == 1 {
        file write tex _n "% ===== UNION STATUS =====" _n
        file write tex "\multicolumn{7}{l}{\textbf{Union status}}\\\\[0.2em]" _n
    }
    if `i' == 3 {
        file write tex "\addlinespace" _n
        file write tex "\multicolumn{7}{l}{\textbf{Demographics}}\\\\[0.2em]" _n
    }
    if `i' == 6 {
        file write tex "\addlinespace" _n
        file write tex "\multicolumn{7}{l}{\textbf{Race / ethnicity}}\\\\[0.2em]" _n
    }
    if `i' == 9 {
        file write tex "\addlinespace" _n
        file write tex "\multicolumn{7}{l}{\textbf{Education}}\\\\[0.2em]" _n
    }
    if `i' == 12 {
        file write tex "\addlinespace" _n
        file write tex "\multicolumn{7}{l}{\textbf{Occupation and sector}}\\\\[0.2em]" _n
    }

    * Row label
    local lab : variable label `v'

    * ----- Weighted means and SDs -----
    quietly summarize `v' [aw=earnwt]
    local mean_Total : display %5.3f r(mean)
    local sd_Total   : display %5.3f r(sd)

    quietly summarize `v' if group==1 [aw=earnwt]
    local mean_Never : display %5.3f r(mean)
    local sd_Never   : display %5.3f r(sd)

    quietly summarize `v' if group==2 [aw=earnwt]
    local mean_NewPre : display %5.3f r(mean)
    local sd_NewPre   : display %5.3f r(sd)

    quietly summarize `v' if group==3 [aw=earnwt]
    local mean_NewPost : display %5.3f r(mean)
    local sd_NewPost   : display %5.3f r(sd)

    quietly summarize `v' if group==4 [aw=earnwt]
    local mean_Always : display %5.3f r(mean)
    local sd_Always   : display %5.3f r(sd)

    * ----- p-value: New RTW (pre) vs Never RTW -----
    quietly regress `v' i.group if inlist(group,1,2) [pw=earnwt]
    quietly test 2.group = 0
    local sp : display %5.3f r(p)

    * Means row (indented with \qquad)
    file write tex "\qquad `lab'" ///
        " & `mean_Total'" ///
        " & `mean_Never'" ///
        " & `mean_NewPre'" ///
        " & `mean_NewPost'" ///
        " & `mean_Always'" ///
        " & `sp' \\\\" _n

    * SD row (with small extra space after each variable)
    file write tex " & (`sd_Total')" ///
        " & (`sd_Never')" ///
        " & (`sd_NewPre')" ///
        " & (`sd_NewPost')" ///
        " & (`sd_Always')" ///
        " & \\\\[0.2em]" _n
}

*------------------------------------------------------------*
* Number of observations row                                 *
*------------------------------------------------------------*
file write tex "\midrule" _n

quietly count if !missing(earnwt)
local NTotal : display %9.0f r(N)
quietly count if group==1 & !missing(earnwt)
local NNever : display %9.0f r(N)
quietly count if group==2 & !missing(earnwt)
local NNewPre : display %9.0f r(N)
quietly count if group==3 & !missing(earnwt)
local NNewPost : display %9.0f r(N)
quietly count if group==4 & !missing(earnwt)
local NAlways : display %9.0f r(N)

file write tex "Number of observations" ///
    " & \multicolumn{1}{c}{`NTotal'}" ///
    " & \multicolumn{1}{c}{`NNever'}" ///
    " & \multicolumn{1}{c}{`NNewPre'}" ///
    " & \multicolumn{1}{c}{`NNewPost'}" ///
    " & \multicolumn{1}{c}{`NAlways'}" ///
    " & \\" _n

file write tex "\bottomrule" _n
file write tex "\end{tabular}" _n
file write tex "\end{table}" _n

file close tex
*============================================================*
