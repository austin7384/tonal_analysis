********************************************************************************
************ Table G.1 LLM: Table 5 (first panel), full output, LLM ***********
********************************************************************************
foreach stat in llm_g1 llm_g2 llm_g3 llm_g4 llm_g5 {
  * Re-estimate Equation (1).
  use `nber', clear
  rename nber_`stat'_score nber_score // Rename NBER score variable to nber_score so it's constant across scores.
  eststo ols_`stat': reghdfe _`stat'_score nber_score c.FemRatio##i.Blind Maxt MaxT N asinhCiteCount i.NativeEnglish Type_Theory Type_Empirical Type_Other, absorb(i.Year##i.Journal i.Editor) vce(cluster Editor)
  estadd local jnlyr = "✓"
  estadd local editor = "✓"
}

* Create LaTeX table.
estout ols_* using "~/tonal_analysis/outputs/tables/tex/Table-G.1-llm.tex", style(publishing-female_latex) ///
  cells(b(star fmt(3)) se(fmt(3))) ///
  stats(N_full editor jnlyr, labels("No. observations" "\midrule${n}Editor effects" "Year#Journal effects")) ///
  varlabels(1.NativeEnglish "Native speaker" nber_score "\(R_{jW}\)" 1.Blind#c.FemRatio "Blind\(\times\)female ratio" 1.Blind "Blind review" _cons "Constant", prefix("\mrow{4cm}{") ///
    suffix("}")) ///
  prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table6llm") type("full")
******************************************************************************
