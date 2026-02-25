********************************************************************************
********* Figure 6: Readability of authors’ tth paper (draft and final) ********
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

* Make figure.
tempname b
estimates restore suest
margins, at(FemRatio=0) at(FemRatio=1) over(`tBin') predict(equation(nber_mean)) predict(equation(reg_mean))
matrix `b' = r(table)'
svmat_rownames `b', names(col) generate(rname) rowname clear
generate version = real(regexs(1)) if regexm(rname, "^([0-9]+)")
generate female = real(regexs(1))-1 if regexm(rname, "predict#([0-9]+)")
generate t = real(regexs(1)) if regexm(rname, "at#([0-9]+)")
sort female t version
keep b version female t
reshape wide b, i(t female) j(version)
generate draft_label = "Draft" if t==2
generate final_label = "Final" if t==2
generate n = t + female*0.07
graph twoway ///
  (scatter b1 n if !female, color(pfblue) msize(vlarge) msymbol(circle_hollow) mlwidth(medthin)) ///
  (scatter b2 n if !female, color(pfblue) msize(large) msymbol(diamond)) ///
  (scatter b1 n if  female, color(pfpink) msize(vlarge) msymbol(circle_hollow) mlwidth(medthin)) ///
  (scatter b2 n if  female, color(pfpink) msize(large) msymbol(diamond)) ///
  (pcspike b1 n b2 n if !female, color(pfblue) lwidth(vthin) lpattern(shortdash)) ///
  (pcspike b1 n b2 n if  female, color(pfpink) lwidth(vthin) lpattern(shortdash)) ///
  , legend(pos(5) ring(0) rows(1) order(1 "Male" 3 "Female") color(gray) size(small)) ///
  title("Flesch Reading Ease", size(medsmall) color(gray)) ///
  xtitle("{it:t}th article", size(medsmall) color(gray) placement(seast) justification(right)) ///
  scheme(publishing-female) ///
  graphregion(margin(zero)) ///
  xscale(range(0.9 5.2)) ///
  xlabel(1 "1" 2 "2" 3 "3" 4 "4-5" 5 "6+") ///
  text(`=b1[4]-0.25' 2.07 "Draft", color(gray) size(small)) text(`=b2[4]+0.3' 2.07 "Final", color(gray) size(small)) ///
  text(`=b1[7]+0.3' 4 "Draft", color(gray) size(small)) text(`=b2[7]-0.25' 4 "Final", color(gray) size(small))
graph export "~/tonal_analysis/outputs/figures/Figure-6.pdf", replace fontface("Avenir-Light") as(pdf)
********************************************************************************
