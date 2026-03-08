********************************************************************************
*********** Table G.2 LLM: Table 5 (second panel), full output, LLM ***********
********************************************************************************
foreach stat in llm_g1 llm_g2 llm_g3 llm_g4 llm_g5 {
  * Re-estimate Equation (2).
  use `nber_fe', clear
  eststo fe_`stat': reghdfe D._`stat'_score c.FemRatio##i.Blind Maxt MaxT N asinhCiteCount i.NativeEnglish Type_Theory Type_Empirical Type_Other, absorb(i.Editor i.Year##i.Journal) vce(cluster Year)
  estadd local jnlyr = "✓"
  estadd local editor = "✓"
}

* Create LaTeX table.
estout fe_llm_g1 fe_llm_g2 fe_llm_g3 fe_llm_g4 fe_llm_g5 using "~/tonal_analysis/outputs/tables/tex/Table-G.2-llm.tex", style(publishing-female_latex) ///
  cells(b(star fmt(3)) se(fmt(3))) ///
  stats(N_full editor jnlyr, labels("No. observations" "\midrule${n}Editor effects" "Year#Journal effects")) ///
  varlabels(1.NativeEnglish "Native speaker" nber_score "\(R_{jW}\)" _cons "Constant" 1.Blind#c.FemRatio "Blind\(\times\)female ratio" 1.Blind "Blind review", prefix("\mrow{4cm}{") ///
    suffix("}")) ///
  prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table6llm") type("change_full")
********************************************************************************
