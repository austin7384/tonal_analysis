********************************************************************************
********* Figure K.1: The impact of experience on women's review times *********
********************************************************************************
* Generate mother and childbirth controls.
use `duration', clear
generate Mother = ChildReceived<=4|ChildAccepted<=4
collapse (firstnm) ReviewLength FemRatio PageN N PubOrder Year Journal ReceivedYear AcceptedYear Editor Maxt MaxInst asinhCiteCount (max) Mother Birth, by(ArticleID AuthorID)
collapse (firstnm) ReviewLength FemRatio PageN N PubOrder Year Journal ReceivedYear AcceptedYear Editor Maxt MaxInst asinhCiteCount (min) Mother Birth, by(ArticleID)

* Merge with author-level data.
merge 1:m ArticleID using `author5', assert(using match) keep(match) nogenerate
assert Year<=2015

* Generate distinct grouping variable (if a value is skipped, suest won't work.)
tempvar Year Editor ECMA RES
generate `ECMA' = AcceptedYear if Journal==2
replace `ECMA' = 0 if missing(`ECMA')
generate `RES' = AcceptedYear if Journal==6
replace `RES' = 0 if missing(`RES')
egen `Year' = group(AcceptedYear)
egen `Editor' = group(Editor)

* Estimate on junior and senior samples separately in SURE regressions.
eststo novice: regress ReviewLength FemRatio Maxt PageN N PubOrder asinhCiteCount ib1.`Editor' i.Journal ib1.`Year' i.`ECMA' i.`RES' i.MaxInst [aweight=AuthorWeight] if t==1 & Maxt<=t
eststo expert: regress ReviewLength FemRatio Maxt PageN N PubOrder asinhCiteCount ib1.`Editor' i.Journal ib1.`Year' i.`ECMA' i.`RES' i.MaxInst [aweight=AuthorWeight] if t>1 & Maxt<=t
eststo suest: suest novice expert, vce(cluster ReceivedYear)

estimates table suest, p keep(novice_mean:FemRatio expert_mean:FemRatio) stats(N)
lincom _b[novice_mean:FemRatio] - _b[expert_mean:FemRatio]
tempname C
matrix `C' = r(estimate) \ r(se)

coefplot ///
  (suest, keep(novice_mean:FemRatio expert_mean:FemRatio)) ///
  (matrix(`C'), se(`C'[2])) ///
	, vertical ///
	coeflabels( ///
			novice_mean:FemRatio = "Junior women" ///
			expert_mean:FemRatio = "Senior women" ///
			c1 = "Difference", labsize(small)) ///
	noeqlabels ///
	msize(vlarge) ///
	levels(90) ///
	scheme(publishing-female) ///
	legend(off) ///
	grid(none) ///
	offset(0) ///
	p1(mcolor(pfblue)) ///
	p2(mcolor(pfyellow)) ///
	ciopts(lcolor(gray)) ///
	subtitle("Review length", size(small) placement(nwest)) ///
		aspectratio(0.3)
graph export "~/tonal_analysis/outputs/figures/Figure-K.1.pdf", replace fontface("Avenir-Light") as(pdf)
********************************************************************************
