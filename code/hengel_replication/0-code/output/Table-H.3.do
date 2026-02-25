********************************************************************************
******* Table H.3: Table 6 column (5), alternative thresholds for mother *******
********************************************************************************
* Set mother = 1 if the child was less than 3, 4, 5, 10 and 18 at some point during review.
* Then reestimate Equation (9) controlling for same factors as in Table 6, column (5).
foreach thresh of numlist 2 3 4 9 17 {
  use `duration', clear
  generate Mother = ChildReceived<=`thresh'|ChildAccepted<=`thresh'
  collapse (firstnm) Journal ReviewLength FemRatio FemSolo Fem100 Fem1 Fem50 FemSenior FemJunior PageN N PubOrder Year ReceivedYear AcceptedYear Editor Maxt MaxInst asinhCiteCount _flesch_score Type_* (max) Mother Birth, by(ArticleID AuthorID)
  collapse (firstnm) Journal ReviewLength FemRatio FemSolo Fem100 Fem1 Fem50 FemSenior FemJunior PageN N PubOrder Year ReceivedYear AcceptedYear Editor Maxt MaxInst asinhCiteCount _flesch_score Type_* (min) Mother Birth, by(ArticleID)
  merge m:1 ArticleID using `primary_jel', keep(match master) nogenerate
  do `varlabels'
  eststo est_`thresh': reghdfe ReviewLength FemRatio Mother Birth Maxt PageN N PubOrder asinhCiteCount _flesch_score Type_Theory Type_Empirical Type_Other, absorb(i.MaxInst i.AcceptedYear i.Editor) vce(cluster ReceivedYear)
  estadd local year = "✓"
  estadd local inst = "✓"
  estadd local editor = "✓"
}

* Create LaTeX table.
estout est_2 est_3 est_4 est_9 est_17 using "~/tonal_analysis/outputs/tables/tex/Table-H.3.tex", style(publishing-female_latex) ///
  cells(b(star fmt(3)) se(fmt(3))) ///
  stats(r2 N editor year inst, fmt(3 %9.0fc) labels("\(R^2\)" "No. observations" "\midrule${n}Editor effects" "Accepted year effects" "Institution effects")) ///
  drop(*.Year *.MaxInst *.Editor, relax) ///
  prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table10") type("thresholds")
********************************************************************************
