********************************************************************************
******* Table F.1 LLM: Journal LLM tonal composites, comparisons to AER *******
********************************************************************************
* Get coefficients on journal fixed effects.
estimates clear
use `article', clear
foreach stat in llm_g1 llm_g2 llm_g3 llm_g4 llm_g5 {
  eststo reg_`stat'_Editor: regress _`stat'_score c.FemRatio##i.Blind i.Journal i.Editor i.Year, vce(cluster Editor)
}

* Create LaTeX table.
estout reg_*_Editor using "~/tonal_analysis/outputs/tables/tex/Table-F.1-llm.tex", style(publishing-female_latex) ///
  keep(2.Journal 3.Journal 4.Journal) varlabels(2.Journal "Econometrica", prefix("\textit{") suffix("}")) ///
  stats(N, labels("No. observations")) prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table3llm") type("journal")
********************************************************************************
