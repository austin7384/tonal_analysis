********************************************************************************
** Figure 1: Relationship between readability and the ratio of female authors **
********************************************************************************
use `article', clear
recode FemRatio0 (0=0) (0.1/0.4=0.25) (0.5=0.5) (0.6/0.8=0.75) (1=1), generate(FemBin)
regress _flesch_score FemBin
local beta_text = string(_b[FemBin],"%03.2f")
local se_text = string(_se[FemBin],"%03.2f")
binscatter _flesch_score FemBin, ///
  scheme(publishing-female) ///
  linetype(lfit) ///
  discrete ///
  color(pfblue pfblue) ///
  xtitle("Ratio of female authors", size(medium)) ///
  ytitle("Flesch Reading Ease", size(medium)) ///
  text(41.5 0.8 `"{fontface "Avenir-Light"}{it:{&beta}} = `beta_text'"' "(`se_text')", color(gray)) ///
  xlabel(0.25 0.5 0.75 1) ///
  aspectratio(0.4)
graph export "~/tonal_analysis/outputs/figures/Figure-1.pdf", replace fontface("Avenir-Light") as(pdf)
********************************************************************************
