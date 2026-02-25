********************************************************************************
************** Table F.1: Journal readability, comparisons to AER **************
********************************************************************************
* Get coefficients on journal fixed effects.
estimates clear
use `article', clear
foreach stat in flesch fleschkincaid gunningfog smog dalechall {
  eststo reg_`stat'_Editor: regress _`stat'_score c.FemRatio##i.Blind i.Journal i.Editor i.Year, vce(cluster Editor)
}

* Create LaTeX table.
estout reg_*_Editor using "~/tonal_analysis/outputs/tables/tex/Table-F.1.tex", style(publishing-female_latex) ///
  keep(2.Journal 3.Journal 4.Journal) varlabels(2.Journal "Econometrica", prefix("\textit{") suffix("}")) ///
  stats(N, labels("No. observations")) prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table3") type("journal")
********************************************************************************
