********************************************************************************
******** Figure 2: The representation of women in top economics journals *******
********************************************************************************
* Readability by JEL code.
use `article_primary_jel', clear
keep if !missing(JEL1_A)
keep ArticleID JEL1_* _flesch_score Year FemRatio0

* Save long names of JEL codes.
foreach v of varlist JEL1_* {
  local `v' : variable label `v'
}

* Reshape data.
reshape long JEL1_, i(ArticleID) j(jel) string
drop if JEL==0 | missing(JEL1_)
drop JEL
rename jel JEL

* Replace JEL code letters with their long names.
levelsof JEL, local(jel) clean
foreach j in `jel' {
  replace JEL = "`JEL1_`j''" if JEL == "`j'"
}
* Female ratio by JEL code.
replace FemRatio0 = 100*FemRatio0
graph hbar (mean) FemRatio0, over(JEL) ///
  scheme(publishing-female) ///
  ytitle("% female authors (per paper)", placement(seast) size(small)) ///
  aspectratio(2, placement(left)) ///
  name(femratio_jel, replace)
graph export "~/tonal_analysis/outputs/figures/Figure-2-jel.pdf", replace fontface("Avenir-Light") as(pdf)

* Gender representation over time.
use `article', clear
replace Fem100 = FemRatio0==1
replace Fem50 = FemRatio0>0.5
generate Male = FemRatio0==0
collapse (mean) FemRatio0 Fem50 Fem1 Fem100 (sum) MaleCount=Male FemaleCount=Fem100, by(Year)
generate Fem100Ratio = FemaleCount / (MaleCount+FemaleCount)
tsset Year

foreach v of varlist Fem* {
  replace `v' = `v'*100
}

tssmooth ma maFemRatio=FemRatio0, window(5)
tssmooth ma maFem50=Fem50, window(5)
tssmooth ma maFemale=Fem1, window(5)
tssmooth ma maFem100=Fem100, window(5)
tssmooth ma maFem100Ratio=Fem100Ratio, window(5)
keep if Year >= 1990
graph twoway ///
  (line maFemRatio Year, lpattern(shortdash) color(pfyellow) lwidth(medium)) ///
  (line maFem100 Year, color(pfpink) lwidth(medium)) ///
  (line maFem50 Year, lpattern(longdash) color(pfblue) lwidth(medium)) ///
  (line maFemale Year, lpattern(dash_dot) color(pfteal) lwidth(medium)) ///
  (line maFem100Ratio Year, color(pfpink) lpattern(dot) lwidth(medium)) ///
  , xlabel(1990(4)2015) ///
  legend(position(10) ///
    order(4 "At least one female-author (% papers)" ///
    1 "% female authors (per paper)" ///
    3 "Majority female-authored (% papers)" ///
    2 "100% female-authored (% papers)" ///
    5 "100% female-authored (% single-gender papers)") ///
    cols(1) rows(8) symxsize(7) size(small)) ///
  scheme(publishing-female) ///
  xtitle("") ///
  ytitle("") ///
  ylabel(5 "5%" 10 "10%" 15 "15%" 20 "20%" 25 "25%") ///
  name(femrep, replace)
graph export "~/tonal_analysis/outputs/figures/Figure-2-time.pdf", replace fontface("Avenir-Light") as(pdf)
********************************************************************************
