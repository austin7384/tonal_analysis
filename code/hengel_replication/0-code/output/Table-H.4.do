********************************************************************************
* Table H.4: Revision duration at Econometrica and REStud, quantile regression *
********************************************************************************
* Re-estimate Equation (9) using the same controls as in Table 6, column (5) (first panel)
* and Table 7, third column (second column) using a quantile regression model.
use `duration', clear
generate Mother = ChildReceived<=4|ChildAccepted<=4
collapse (firstnm) Journal ReviewLength FemRatio PageN N PubOrder Year ReceivedYear AcceptedYear Editor Maxt MaxInst asinhCiteCount _flesch_score Type_* (max) Mother Birth, by(ArticleID AuthorID)
collapse (firstnm) Journal ReviewLength FemRatio PageN N PubOrder Year ReceivedYear AcceptedYear Editor Maxt MaxInst asinhCiteCount _flesch_score Type_* (min) Mother Birth, by(ArticleID)
do `varlabels'
foreach qtile in 25 50 75 {
	local qfrac = `qtile'/100

	* Table 6, column (5)
	eststo q1_`qtile': qreg ReviewLength FemRatio Mother Birth Maxt PageN N PubOrder _flesch_score asinhCiteCount Type_* i.MaxInst i.AcceptedYear i.Editor, vce(robust) quantile(`qfrac') iterate(1000)
	estadd scalar r2 = 1- (`=e(sum_adev)'/`=e(sum_rdev)')
	estadd local year = "✓" : q1_`qtile'
	estadd local inst = "✓" : q1_`qtile'
	estadd local editor = "✓" : q1_`qtile'

	* Table 7, third column
	eststo q2_`qtile': qreg ReviewLength FemRatio Maxt PageN N PubOrder asinhCiteCount Type_* i.MaxInst i.AcceptedYear##i.Journal i.Editor, vce(robust) quantile(`qfrac') iterate(1500)
	estadd scalar r2 = 1- (`=e(sum_adev)'/`=e(sum_rdev)')
	estadd local editor = "✓" : q2_`qtile'
	estadd local jnlyr = "✓" : q2_`qtile'
  estadd local inst = "✓" : q2_`qtile'
}

* CONVERGENCE CHECK: Table-H.4 col 3 (q1_75) has an unexplained SE discrepancy vs
* the original paper: Constant SE = 6.21 (replication) vs 25.99 (original), shifting
* from insignificant to ***. The coefficient (40.67) and Pseudo R² (0.208) match.
* Hypothesis: iterate(1000) hit the limit before the Hessian approximation stabilised.
* Re-run q1_75 with iterate(5000) and compare the Constant SE. If it matches 25.99
* the original used a non-converged solution; if it stays near 6.21 the replication
* result is correct and the original was the non-converged one.
display as error "*** Table-H.4 convergence check for q1_75 (Constant SE: expect ~6.21 or ~25.99) ***"
qreg ReviewLength FemRatio Mother Birth Maxt PageN N PubOrder _flesch_score asinhCiteCount Type_* i.MaxInst i.AcceptedYear i.Editor, vce(robust) quantile(0.75) iterate(5000)
display as error "Constant b = " _b[_cons] "  SE = " _se[_cons]

estout q1_25 q1_50 q1_75 q2_25 q2_50 q2_75 using "~/tonal_analysis/outputs/tables/tex/Table-H.4.tex", style(publishing-female_latex) ///
	keep(FemRatio Maxt PageN PageN N PubOrder _flesch_score asinhCiteCount Mother Birth Type_Theory Type_Empirical Type_Other _cons) ///
	collabels(none) ///
	order(FemRatio Maxt PageN PageN N PubOrder asinhCiteCount Type_Theory Type_Empirical Type_Other _flesch_score Mother Birth _cons) ///
	stats(r2 N editor year jnlyr inst, ///
		fmt(3 %9.0fc) labels("Pseudo \(R^2\)" "No. observations" "\midrule${n}Editor effects" "Accepted year effects" "Journal\(\times\)Accepted year effects" "Institution effects")) ///
	prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table10") type("quantile")
********************************************************************************
