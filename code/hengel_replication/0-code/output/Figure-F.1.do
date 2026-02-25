********************************************************************************
***** Figure F.1: Gender differences in readability, by JEL classification *****
********************************************************************************
use `article_primary_jel_pp', clear

* Drop JEL codes with few observations.
drop JEL1_A JEL1_B JEL1_P JEL1_M

* Regress female ratio interacted with dummies for JEL codes on readability.
eststo reg: regress _dalechall_score c.FemRatio##(JEL1_*) asinhCiteCount Maxt N i.Editor i.Journal i.Year i.MaxInst i.MaxT i.NativeEnglish, vce(cluster Editor)

* Get mean marginal effect of female ratio.
margins, dydx(FemRatio) post
noisily display as text "The mean effect at observed {it:JEL} codes is " as error round(_b[FemRatio], 0.01) as text " (standard error " as error round(_se[FemRatio], 0.001) as text ")."

* Get standard errors for the marginal effect by JEL code.
estimates restore reg
tempname B
foreach jel of varlist JEL1_* {
  lincom _b[FemRatio] + _b[1.`jel'#c.FemRatio]
  matrix `B' = nullmat(`B') \ (r(estimate), r(se)) \ (_b[1.`jel'#c.FemRatio], _se[1.`jel'#c.FemRatio])
  matname `B' asobs:`jel' inter:`jel', rows(`=rowsof(`B')-1'...) explicit
}
matrix `B' = `B'[1...,1],`B'[1...,1]-invttail(e(df_r),0.05)*`B'[1...,2],`B'[1...,1]+invttail(e(df_r),0.05)*`B'[1...,2]
matrix colnames `B' = b ll ul

* Save long names of JEL codes.
foreach v of varlist JEL1_* {
  local `v' : variable label `v'
}

* Convert coefficient matrix to variables.
svmat_rownames `B', names(col) generate(jel eq) roweq rowname clear

* Replace JEL code letters with their long names.
levelsof jel, local(jels) clean
foreach j in `jels' {
  replace jel = "``j''" if jel == "`j'"
}

* Order JEL codes according to largest female ratio.
by eq (b), sort: generate jel_id = _n if eq == "asobs"
by jel (eq), sort: replace jel_id = jel_id[_n-1] if eq == "inter"
labmask jel_id, values(jel)

* Label equations for graphs graphs.
label define myeq 1 "Female ratio, by {it:JEL}" 2 "Female ratio × {it:JEL}"
encode_replace eq, label(myeq)

* Create graph
graph twoway ///
	(rcap ll ul jel_id, by(eq, note("") imargin(l=0 r=2)) subtitle(, nobox) horizontal lwidth(vthin) msize(tiny) color(pfpink)) ///
	(scatter jel_id b, by(eq, legend(off)) msymbol(O) msize(medium) color(pfpink)) ///
	, scheme(publishing-female) ///
	xline(0, lcolor(gray) lwidth(vthin) lpattern(dash)) ///
	xscale(lcolor(gray)) ///
	yscale(lcolor(gray)) ///
	legend(off) ///
	xlabel(, labcolor(gray) tlcolor(gray)) ///
	ylabel(1/`=_N/2', labcolor(gray) tlcolor(gray) valuelabel angle(0) nogrid) ///
	ytitle("") ///
	xtitle("") ///
	aspectratio(0.925, placement(left))
graph export "~/tonal_analysis/outputs/figures/Figure-F.1.pdf", replace fontface("Avenir-Light") as(pdf)
********************************************************************************
