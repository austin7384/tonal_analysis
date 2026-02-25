********************************************************************************
******** Table G.4: The impact of double-blind review after the internet *******
********************************************************************************
* Semi-blind review.
use `nber_fe', clear
tempname B S
foreach stat in flesch fleschkincaid gunningfog smog dalechall {
	eststo semiblind_`stat': reghdfe D._`stat'_score c.FemRatio##1.SemiBlind N Maxt MaxT asinhCiteCount i.NativeEnglish Type_* if Year>1997, absorb(i.Editor i.Year##i.Journal) vce(cluster Year)
  estadd local jnlyr = "✓"
  estadd local editor = "✓"
  estadd local Nj = "✓"
  estadd local qual = "✓²"
  estadd local native = "✓"
  estadd local theory = "✓"
}

* Create LaTeX table.
estout semiblind_* using "~/tonal_analysis/outputs/tables/tex/Table-G.4.tex", style(publishing-female_latex) ///
	stats(N_full editor jnlyr Nj qual native theory, labels("No. observations" "\midrule${n}Editor effects" ///
		"Journal#Year effects" "\(N_j\)" "Quality controls" "Native speaker" "Theory/emp. effects")) ///
	keep(FemRatio 1.SemiBlind#c.FemRatio) ///
  varlabels(1.SemiBlind#c.FemRatio "Blind\(\times\)fem. ratio") ///
	prefoot("\midrule") ///
	eqlabels(none)
create_latex using "`r(fn)'", tablename("table7_semiblind")
********************************************************************************
