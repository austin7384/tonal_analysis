********************************************************************************
************* Table 7: Revision duration at Econometrica and Restud ************
********************************************************************************
* Program to generate Econometrica and Restud duration estimates.
capture program drop review_time_restud
program define review_time_restud, eclass
  syntax name

  estimates clear

  eststo eca: reghdfe ReviewLength `namelist' Maxt PageN N PubOrder asinhCiteCount Type_Theory Type_Empirical Type_Other if Journal==2, absorb(AcceptedYear Editor MaxInst) vce(cluster ReceivedYear)
  eststo res: reghdfe ReviewLength `namelist' Maxt PageN N PubOrder asinhCiteCount Type_Theory Type_Empirical Type_Other if Journal==6, absorb(AcceptedYear Editor MaxInst) vce(cluster ReceivedYear)
  eststo all: reghdfe ReviewLength `namelist' Maxt PageN N PubOrder asinhCiteCount Type_Theory Type_Empirical Type_Other `if', absorb(AcceptedYear##Journal Editor MaxInst) vce(cluster ReceivedYear)
  eststo jel_eca: reghdfe ReviewLength `namelist' Maxt PageN N PubOrder asinhCiteCount Type_Theory Type_Empirical Type_Other if Journal==2, absorb(AcceptedYear Editor MaxInst JEL1_*) vce(cluster ReceivedYear)
  eststo jel_res: reghdfe ReviewLength `namelist' Maxt PageN N PubOrder asinhCiteCount Type_Theory Type_Empirical Type_Other if Journal==6, absorb(AcceptedYear Editor MaxInst JEL1_*) vce(cluster ReceivedYear)
  eststo jel_all: reghdfe ReviewLength `namelist' Maxt PageN N PubOrder asinhCiteCount Type_Theory Type_Empirical Type_Other, absorb(AcceptedYear##Journal Editor MaxInst JEL1_*) vce(cluster ReceivedYear)

  foreach reg in all jel_all res jel_res eca jel_eca {
    estadd local editor = "✓": `reg'
    estadd local inst = "✓": `reg'
  }
  foreach reg in eca res jel_eca jel_res {
    estadd local year = "✓": `reg'
  }
  foreach reg in all jel_all {
      estadd local jnlyr = "✓" : `reg'
  }
  foreach reg in jel_res jel_all jel_eca {
    estadd local jel = "✓" : `reg'
  }
end

capture program drop review_time_restud_table
program define review_time_restud_table
  syntax , type(string)

  estout * using "~/tonal_analysis/outputs/tables/tex/Table-7-`type'.tex", style(publishing-female_latex) ///
    collabels(none) prefoot("\midrule") ///
    stats(r2 N_full editor year jnlyr inst jel, ///
      fmt(3 %9.0fc) labels("\(R^2\)" "No. observations" "\midrule${n}Editor effects" "Accepted year effects" "Journal#Accepted year effects" "Institution effects" "\textit{JEL} (primary) effects" ))
  create_latex using "`r(fn)'", tablename("table11") type("`type'")
end

* Merge duration data with JEL effects and make unique across ArticleID.
use `duration', clear
collapse (firstnm) ReviewLength FemSolo FemSenior FemJunior FemRatio Fem100 Fem50 Fem1 Journal PageN N PubOrder Year ReceivedYear AcceptedYear Editor Maxt MaxInst asinhCiteCount Type_*, by(ArticleID)
merge 1:1 ArticleID using `primary_jel', keep(master match) nogenerate
do `varlabels'

* Table 11 Revision duration at Econometrica and Restud.
review_time_restud FemRatio
review_time_restud_table, type(FemRatio)

* Table J.14x Exclusively female-authored
review_time_restud Fem100
review_time_restud_table, type(Fem100)

* Table J.14x Solo-authored
review_time_restud FemSolo
review_time_restud_table, type(FemSolo)

* Table J.9x At least one female author
review_time_restud Fem1
review_time_restud_table, type(Fem1)

* Table J.4 Majority female-authored
review_time_restud Fem50
review_time_restud_table, type(Fem50)

* Table J.14x Senior female-author
review_time_restud FemSenior
review_time_restud_table, type(FemSenior)

* Junior female-authored.
review_time_restud FemJunior
review_time_restud_table, type(FemJunior)
********************************************************************************
