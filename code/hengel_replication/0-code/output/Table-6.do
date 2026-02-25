********************************************************************************
****************** Table 6: Revision duration at Econometrica ******************
********************************************************************************
* Program to generate Econometrica duration estimates.
capture program drop review_time
program define review_time, eclass
  syntax name, year(varlist)

  estimates clear

  * Main estimation results.
  eststo est_: reghdfe ReviewLength `namelist' Mother Birth Maxt PageN N PubOrder asinhCiteCount _flesch_score Type_Theory Type_Empirical Type_Other, absorb(i.MaxInst i.`year' i.Editor) vce(cluster ReceivedYear)
  estadd local year = "✓" : est_
  estadd local inst = "✓" : est_
  estadd local editor = "✓" : est_

  * Exclude motherhood & birth indicators.
  eststo est_exclude: reghdfe ReviewLength `namelist' Maxt PageN N PubOrder asinhCiteCount _flesch_score Type_Theory Type_Empirical Type_Other if !Mother & !Birth, absorb(i.MaxInst i.`year' i.Editor) vce(cluster ReceivedYear)
  eststo est_nomom: reghdfe ReviewLength `namelist' Birth Maxt PageN N PubOrder asinhCiteCount _flesch_score Type_Theory Type_Empirical Type_Other, absorb(i.MaxInst i.`year' i.Editor) vce(cluster ReceivedYear)
  eststo est_nobirth: reghdfe ReviewLength `namelist' Mother Maxt PageN N PubOrder asinhCiteCount _flesch_score Type_Theory Type_Empirical Type_Other, absorb(i.MaxInst i.`year' i.Editor) vce(cluster ReceivedYear)
  eststo est_none: reghdfe ReviewLength `namelist' Maxt PageN N PubOrder asinhCiteCount _flesch_score Type_Theory Type_Empirical Type_Other, absorb(i.MaxInst i.`year' i.Editor) vce(cluster ReceivedYear)

  * Add JEL fixed effects.
  eststo est_90s: reghdfe ReviewLength `namelist' Mother Birth Maxt PageN N PubOrder asinhCiteCount _flesch_score Type_Theory Type_Empirical Type_Other if !missing(JEL1_A), absorb(i.MaxInst i.`year' i.Editor) vce(cluster ReceivedYear)
  eststo est_jel: reghdfe ReviewLength `namelist' Mother Birth Maxt PageN N PubOrder asinhCiteCount _flesch_score Type_Theory Type_Empirical Type_Other, absorb(i.MaxInst i.`year' i.Editor JEL1_*) vce(cluster ReceivedYear)

  * Add ticks for fixed effects.
  estadd local jel = "✓" : est_jel
  foreach ind in year inst editor {
    foreach reg in nomom nobirth none exclude jel 90s {
      estadd local `ind' = "✓" : est_`reg'
    }
  }
end

capture program drop review_time_table
program define review_time_table
  syntax , type(string)

  estout est_none est_exclude est_nobirth est_nomom est_ est_90s est_jel using "~/tonal_analysis/outputs/tables/tex/Table-6-`type'.tex", ///
    style(publishing-female_latex) cells(b(star fmt(3)) se(fmt(3))) ///
    stats(r2 N_full editor year inst jel, fmt(3 %9.0fc) ///
      labels("\(R^2\)" "No. observations" "\midrule${n}Editor effects" "Year effects" "Institution effects" "\textit{JEL} (primary) effects")) ///
    drop(*.AcceptedYear *.MaxInst *.Editor JEL1_*, relax) ///
    prefoot("\midrule")
  create_latex using "`r(fn)'", tablename("table10") type("`type'")
end

* Merge duration data with JEL effects.
use `duration', clear
generate Mother = ChildReceived<=4|ChildAccepted<=4
collapse (firstnm) Journal ReviewLength FemRatio FemSolo Fem100 Fem1 Fem50 FemSenior FemJunior PageN N PubOrder Year ReceivedYear AcceptedYear Editor Maxt MaxInst asinhCiteCount _flesch_score Type_* (max) Mother Birth, by(ArticleID AuthorID)
collapse (firstnm) Journal ReviewLength FemRatio FemSolo Fem100 Fem1 Fem50 FemSenior FemJunior PageN N PubOrder Year ReceivedYear AcceptedYear Editor Maxt MaxInst asinhCiteCount _flesch_score Type_* (min) Mother Birth, by(ArticleID)
merge m:1 ArticleID using `primary_jel', keep(match master) nogenerate
do `varlabels'

* Table 10 Revision duration at Econometrica
review_time FemRatio, year(AcceptedYear)
review_time_table, type(FemRatio)

* Table J.14 Exclusively female-authored
review_time Fem100, year(AcceptedYear)
review_time_table, type(Fem100)

* Table J.14 Solo-authored
review_time FemSolo, year(AcceptedYear)
review_time_table, type(FemSolo)

* Table J.9 At least one female author
review_time Fem1, year(AcceptedYear)
review_time_table, type(Fem1)

* Table J.4 Majority female-authored
review_time Fem50, year(AcceptedYear)
review_time_table, type(Fem50)

* Table J.14 Exclusively female-authored
review_time FemSenior, year(AcceptedYear)
review_time_table, type(FemSenior)

* Junior female-authored.
review_time FemJunior, year(AcceptedYear)
review_time_table, type(FemJunior)

* Table N.1 Publication year effects
review_time FemRatio, year(Year)
review_time_table, type(pubyear)

* Table N.2 Acceptance year effects
review_time FemRatio, year(ReceivedYear)
review_time_table, type(subyear)
********************************************************************************
