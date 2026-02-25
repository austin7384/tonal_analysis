********************************************************************************
********* Table 10: Readability of authors' tth paper (draft and final) ********
********************************************************************************
use `nber', clear
merge m:m ArticleID using `author', keep(match) nogenerate
tempfile nber_author
save `nber_author'

tempvar tBin
recode t (1=1)(2=2)(3=3)(4/5=4)(nonmissing=5), generate(`tBin')
label define tBin 1 "1" 2 "2" 3 "3" 4 "4-5" 5 "6+"
label values `tBin' tBin

eststo nber: regress nber_flesch_score c.FemRatio##c.`tBin' Maxt MaxT asinhCiteCount N i.NativeEnglish i.Year##i.Journal i.Editor [aweight=AuthorWeight]
eststo reg:  regress _flesch_score     c.FemRatio##c.`tBin' Maxt MaxT asinhCiteCount N i.NativeEnglish i.Year##i.Journal i.Editor [aweight=AuthorWeight]
eststo suest: suest nber reg, vce(cluster Editor)

tempname B SE se b

* Direct impact of peer review: Female.
margins, at(FemRatio=1) over(`tBin') expression(predict(equation(reg_mean))-predict(equation(nber_mean)))
matrix `B' = nullmat(`B') \ r(b)
matrix `se' = r(table)
matrix `SE' = nullmat(`SE') \ `se'[rownumb(`se',"se"), 1...]

* Direct impact of peer review: Male.
margins, at(FemRatio=0) over(`tBin') expression(predict(equation(reg_mean))-predict(equation(nber_mean)))
matrix `B' = nullmat(`B') \ r(b)
matrix `se' = r(table)
matrix `SE' = nullmat(`SE') \ `se'[rownumb(`se',"se"), 1...]

* Impact of female ratio: published articles.
margins, dydx(FemRatio) over(`tBin') predict(equation(reg_mean))
matrix `B' = nullmat(`B') \ r(b)
matrix `se' = r(table)
matrix `SE' = nullmat(`SE') \ `se'[rownumb(`se',"se"), 1...]

* Impact of female ratio: working papers.
margins, dydx(FemRatio) over(`tBin') predict(equation(nber_mean))
matrix `B' = nullmat(`B') \ r(b)
matrix `se' = r(table)
matrix `SE' = nullmat(`SE') \ `se'[rownumb(`se',"se"), 1...]

* Difference
margins, at(FemRatio=0 FemRatio=1) over(`tBin') contrast(atcontrast(r)) expression(predict(equation(reg_mean))-predict(equation(nber_mean)))
matrix `B' = nullmat(`B') \ r(b)
matrix `se' = r(table)
matrix `SE' = nullmat(`SE') \ `se'[rownumb(`se',"se"), 1...]

forvalues i=1/`=colsof(`B')' {
	matrix `b' = `B'[1...,`i']'
	matrix `se' = `SE'[1...,`i']'
	ereturn_post `b', se(`se') colnames(women men reg nber diff) obs(`e(N)') store(est_`i') local(jnlyr ✓ editor ✓ Nj ✓ qual ✓² native ✓)
}

estout est_* using "~/tonal_analysis/outputs/tables/tex/Table-10.tex", style(publishing-female_latex) ///
	varlabels(women "\quad Women" ///
		men "\quad Men" ///
		diff "\midrule${n}\textbf{Diff.-in-diff.}" ///
		nber "\quad Draft paper" ///
		reg "\quad Published article" ///
		, blist(women "\multicolumn{6}{l}{\textbf{Predicted \(R_{jP}-R_{jW}\)}}\\\${n}" ///
			reg "\midrule\multicolumn{6}{l}{\textbf{Marginal effect of female ratio}}\\\${n}"))
create_latex using "`r(fn)'", tablename("table9")
estimates clear
********************************************************************************
