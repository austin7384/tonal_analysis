********************************************************************************
**************** Table G.2: Table 5 (second panel), full output ****************
********************************************************************************
foreach stat in flesch fleschkincaid gunningfog smog dalechall {
  * Re-estimate Equation (2).
  use `nber_fe', clear
  eststo fe_`stat': reghdfe D._`stat'_score c.FemRatio##i.Blind Maxt MaxT N asinhCiteCount i.NativeEnglish Type_Theory Type_Empirical Type_Other, absorb(i.Editor i.Year##i.Journal) vce(cluster Year)
  estadd local jnlyr = "✓"
  estadd local editor = "✓"
}

* Create LaTeX table.
estout fe_flesch fe_fleschkincaid fe_gunningfog fe_smog fe_dalechall using "~/tonal_analysis/outputs/tables/tex/Table-G.2.tex", style(publishing-female_latex) ///
  cells(b(star fmt(3)) se(fmt(3))) ///
  stats(N_full editor jnlyr, labels("No. observations" "\midrule${n}Editor effects" "Year#Journal effects")) ///
  varlabels(1.NativeEnglish "Native speaker" nber_score "\(R_{jW}\)" _cons "Constant" 1.Blind#c.FemRatio "Blind\(\times\)female ratio" 1.Blind "Blind review", prefix("\mrow{4cm}{") ///
    suffix("}")) ///
  prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table6") type("change_full")
********************************************************************************
