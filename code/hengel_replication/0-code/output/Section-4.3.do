********************************************************************************
****************** Section 4.3 Quantifying the counterfactual ******************
********************************************************************************
* Table 9: Dik (Corollary 1)
capture program drop matching_table
program define matching_table
	syntax , type(string)

	estout df1 dm1 d31 using "~/tonal_analysis/outputs/tables/tex/Table-9-`type'.tex", style(publishing-female_latex) ///
		cells("b(fmt(2) nostar pattern(1 1 0 0)) se(fmt(2) nopar pattern(1 1 0 0)) N(fmt(0) pattern(1 1 0 0)) b(star pattern(0 0 1 1))" ". . . se(fmt(2) par pattern(0 0 1 1))") ///
		varlabels(flesch "Flesch" fleschkincaid "Flesch Kincaid" gunningfog "Gunning Fog" smog "SMOG" dalechall "Dale-Chall")
	create_latex using "`r(fn)'", tablename("table8") type("`type'")
end

* Figure 5: Distribution of Dik (Corollary 1)
capture programm drop matching_figure
program define matching_figure
	syntax , type(string) [float]

	local _flesch_title "Flesch"
	local _fleschkincaid_title "Flesch-Kincaid"
	local _gunningfog_title "Gunning Fog"
	local _smog_title "SMOG"
	local _dalechall_title "Dale-Chall"

	preserve
	import excel "~/tonal_analysis/data/raw/hengel_labels/tables.xlsx", firstrow clear case(preserve)
	keep if TableName=="figure8" & Type=="`type'"
	local note `"`=Note[1]'"'
	restore
	wordwrap `"{it:Notes.} `note'"', length(42)
	local note
	foreach line in "`r(text)'" {
		local note `"`note' `"{fontface "Avenir-Light"}`line'"'"'
	}
	foreach stat in flesch fleschkincaid gunningfog smog dalechall {
		summarize _`stat'_Ds1, meanonly
		local min = -1 * max(abs(`r(min)'), abs(`r(max)'))
		local width = abs(`min') / 5
		graph twoway ///
			(histogram _`stat'_Ds1 if _`stat'_D==1, start(0) width(`width') frequency color(pfpink%60) lwidth(none) ///
				yaxis(2) ylabel(,format(%4.3f))) ///
			(histogram _`stat'_Ds1 if _`stat'_D==0, start(`min') width(`width') frequency color(pfblue%60) lwidth(none) ///
				yaxis(2)) ///
			(kdensity _`stat'_Ds1 [aw=_weight1], range(`min' `=abs(`min')') color(gs6) lwidth(vthin) yaxis(1) yscale(alt)), ///
			scheme(publishing-female) ///
			title("`_`stat'_title'", size(small) color(gray)) ///
			yscale(off axis(2)) ///
			ytitle("") ///
			xtitle("") ///
			legend(off) ///
			name(`stat', replace)
	}
	twoway ///
		(scatteri 0.99 0.2 `"Pairs suggesting higher standards for:"', msymbol(i) mlabcolor("116 116 116")) ///
		(scatteri 0.9 0.35 `"Men"', color(pfblue%60) mlabcolor("116 116 116")) ///
		(scatteri 0.9 0.55 `"Women"', color(pfpink%60) mlabcolor("116 116 116")) ///
		(scatteri 0 0 "" 1 1 "", msymbol(i)), ///
		scheme(publishing-female) ///
		text(0.19 0.6 `note', just(left) placement(north) size(small) color(gray)) ///
		plotregion(lpattern(blank)) legend(off) ///
		ylabel("") ///
		xlabel("") ///
		ytitle("") ///
		xtitle("") ///
		yscale(off) ///
		xscale(off) ///
		name(blank, replace)
	graph combine flesch fleschkincaid gunningfog smog dalechall blank, ///
		scheme(publishing-female) ///
		commonscheme
	graph export "~/tonal_analysis/outputs/figures/Figure-5-`type'.pdf", replace fontface("Avenir-Light") as(pdf)
end

* Generate base results ("base"), adjusting R for JEL code ("jel") and using the R readability package
foreach R in "base" "jel" "R" {

use `author', clear
merge m:1 ArticleID using `primary_jel', nogenerate
tempfile author_pp
save `author_pp'

* Save list of JEL codes for easy reference.
local jcode1
foreach jcode of varlist JEL1* {
	local jcode1 "`jcode1' `jcode'"
}
local jcode10 = subinstr(strltrim("`jcode1'")," ", "0 ", .) + "0"
local jcode11 = subinstr(strltrim("`jcode1'")," ", "1 ", .) + "1"

* Mahalanobis matching.
use `author_pp', clear
merge m:1 ArticleID using `primary_jel', keep(master match) nogenerate
tabulate Journal, generate(Journal)
egen Decade = cut(Year), at(1930 1940 1950 1960 1970 1980 1990 2000 2010 2020)
tabulate Decade, generate(Decade)
generate FirstInst = InstRank if t==1
collapse ///
	(firstnm) Female T FirstInst ///
	(mean) Journal? Decade? ///
	(max) maxCiteCount=CiteCount ///
	(sum) JEL1_? ///
	, by(AuthorID)
do `varlabels'
tempfile author_prematching
save `author_prematching'

* Generate matches.
* Randomly sort observations before matching.
tempvar rand_sort
generate `rand_sort' = runiform()
sort `rand_sort'
* Match on T, first institution, maximum citation count, decade, journal and JEL code.
local matchlist FirstInst maxCiteCount Decade? Journal? JEL1_?
* Mahalanobis matching.
psmatch2 Female if T>2, mahalanobis(`matchlist') neighbor(1)

* Generate weights.
sort _id
* Female author weights.
generate _weight1 = _weight[_n1]
generate T1 = T[_n1]
generate AuthorID1 = AuthorID[_n1]
* Male author weights.
rename (AuthorID _weight T)=0
* Drop non-matched authors.
drop if missing(_n1)

* Save matched authors.
keep AuthorID* _weight*
tempfile matches
save `matches'

* Merge matched authors with author data.
forvalues i=0/1 {
	* Load matched authors and keep only relevant AuthorID.
	use `matches', clear
	keep AuthorID`i'
	duplicates drop

	* Merge matched authors with author data on AuthorID.
	rename AuthorID`i' AuthorID
	merge 1:m AuthorID using `author_pp', assert(using match) keep(match) keepusing(t T FemRatio `jcode1' _flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score) nogenerate

	* Keep first or third publication.
	keep if t==1 | t==3
	replace t = 2 if t>1

	* Reshape wide on t.
	rename (AuthorID t T FemRatio _flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score `jcode1') =`i'
	reshape wide _flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score`i' `jcode1'`i' FemRatio`i', i(AuthorID`i') j(t)

	* Merge with matched authors.
	merge 1:m AuthorID`i' using `matches', assert(match) nogenerate
	save `matches', replace
}

* Reshape long; each author in a matched pair is an individual observation.
use `matches', clear
generate id = _n
tempvar t g
reshape long `jcode10' `jcode11' FemRatio0 FemRatio1 ///
	_flesch_score0 _flesch_score1 ///
	_fleschkincaid_score0 _fleschkincaid_score1 ///
	_gunningfog_score0 _gunningfog_score1 ///
	_smog_score0 _smog_score1 ///
	_dalechall_score0 _dalechall_score1 ///
		, i(id) j(`t')
reshape long AuthorID FemRatio T _weight `jcode1' ///
	_flesch_score ///
	_fleschkincaid_score ///
	_gunningfog_score ///
	_smog_score ///
	_dalechall_score ///
		, i(id `t') j(`g')

* Reconstruct Rit.
	foreach stat in flesch fleschkincaid gunningfog smog dalechall {
		if "`R'"=="base" | "`R'"=="jel" {
			tempvar resid
			generate _`stat'_R = .
			forvalues gender=0/1 {
				forvalues time=1/2 {
					if "`R'"=="jel"==1 {
						eststo est_`stat'_`gender'`time': regress _`stat'_score FemRatio JEL1_* [aw=_weight] if `t'==`time' & `g'==`gender'
						predict double `resid', residuals
						* Reconstruct Rit as a labour microeconomics paper.
						replace _`stat'_R = _b[_cons] + _b[FemRatio]*(1-`g') + _b[JEL1_D] + _b[JEL1_J] + `resid' if `t'==`time' & `g'==`gender'
					}
					else {
						eststo est_`stat'_`gender'`time': regress _`stat'_score FemRatio [aw=_weight] if `t'==`time' & `g'==`gender'
						predict double `resid', residuals
						replace _`stat'_R = _b[_cons] + _b[FemRatio]*(1-`g') + `resid' if `t'==`time' & `g'==`gender'
					}
					drop `resid'
				}
			}
		local df = `e(N)' - `e(df_r)'
	}
	else {
		generate _`stat'_R = _`stat'_score
		local df = 0
	}
}
do `varlabels'
* Table J.3: Regression output generating Rit (Equation (13))
if "`R'"=="base" {
	estout est_flesch_0* est_flesch_1* using "0-tex/generated/Table-J.3.tex", ///
		style(publishing-female_latex) ///
		varlabels(_cons Constant, prefix("\quad ")) ///
		prehead("\multicolumn{5}{l}{{\textbf{Flesch Reading Ease}}}\\") ///
		prefoot("\midrule")
	estout est_fleschkincaid_0* est_fleschkincaid_1* using "`r(fn)'", ///
		style(publishing-female_latex) ///
		varlabels(_cons Constant, prefix("\quad ")) ///
		prehead("\multicolumn{5}{l}{{\textbf{Flesch Kincaid}}}\\") ///
		prefoot("\midrule") ///
		append noreplace
	estout est_gunningfog_0* est_gunningfog_1* using "`r(fn)'", ///
		style(publishing-female_latex) ///
		varlabels(_cons Constant, prefix("\quad ")) ///
		prehead("\multicolumn{5}{l}{{\textbf{Gunning Fog}}}\\") ///
		prefoot("\midrule") ///
		append noreplace
	estout est_smog_0* est_smog_1* using "`r(fn)'", ///
		style(publishing-female_latex) ///
		varlabels(_cons Constant, prefix("\quad ")) ///
		prehead("\multicolumn{5}{l}{{\textbf{SMOG}}}\\") ///
		prefoot("\midrule") ///
		append noreplace
	estout est_dalechall_0* est_dalechall_1* using "`r(fn)'", ///
		style(publishing-female_latex) ///
		varlabels(_cons Constant, prefix("\quad ")) ///
		prehead("\multicolumn{5}{l}{{\textbf{Dale-Chall}}}\\") ///
		append noreplace
	create_latex using "`r(fn)'", tablename("Rit_regresults")
}

* Merge pre-matched data with matches for balance tables.
preserve
	keep AuthorID _weight
	duplicates drop
	sort AuthorID
	merge 1:1 AuthorID using `author_prematching', assert(using match) generate(match)
	tempfile balance
	save `balance'
restore

* Reshape data wide; each observation is a matched pair.
estimates clear
reshape wide AuthorID FemRatio T _weight `jcode1' ///
	_flesch_score _flesch_R ///
	_fleschkincaid_score _fleschkincaid_R ///
	_gunningfog_score _gunningfog_R ///
	_smog_score _smog_R ///
	_dalechall_score _dalechall_R ///
		, i(id `t') j(`g')
reshape wide `jcode10' `jcode11' FemRatio0 FemRatio1 ///
	_flesch_score0 _flesch_score1 _flesch_R0 _flesch_R1 ///
	_fleschkincaid_score0 _fleschkincaid_score1 _fleschkincaid_R0 _fleschkincaid_R1 ///
	_gunningfog_score0 _gunningfog_score1 _gunningfog_R0 _gunningfog_R1 ///
	_smog_score0 _smog_score1 _smog_R0 _smog_R1 ///
	_dalechall_score0 _dalechall_score1 _dalechall_R0 _dalechall_R1 ///
		, i(id) j(`t')

* Save matched pair data.
compress
tempfile author_matching
save `author_matching'
if "`R'"=="base" save "~/tonal_analysis/data/raw/hengel_generated/author_matching", replace

* Table J.1: Pre- and post-matching summary statistics
if "`R'"=="base" {
	use `balance', clear
	tempname b b1 b2
	local rnames
	foreach v of varlist `matchlist' {
		regress `v' i.Female if T>=3
		matrix `b1' = nullmat(`b1') \ (_b[_cons] + _b[1.Female], _b[_cons], -1*_b[1.Female], -1*_b[1.Female]/_se[1.Female])

		regress `v' i.Female [aw=_weight] if T>=3 & match==3
		matrix `b2' = nullmat(`b2') \ (_b[_cons], -1*_b[1.Female], -1*_b[1.Female]/_se[1.Female])
		local rnames "`rnames' `v'"
	}
	matrix `b' = `b1' , `b2'
	matrix rownames `b' = `rnames'

	estout matrix(`b', fmt(2)) using "0-tex/generated/Table-J.1.tex", style(tex) ///
		label ///
		mlabels(none) ///
		collabels(none) ///
		varlabels(, ///
			prefix("\quad ") ///
			blist(Journal1 "\multicolumn{8}{l}{\textbf{Fraction of articles per journal}}\\\${n}" ///
				Decade1 "\multicolumn{8}{l}{\textbf{Fraction of articles per decade}}\\\${n}" ///
				JEL1_A "\multicolumn{8}{l}{\textbf{Number of articles per \textit{JEL} code}}\\\${n}") ///
			elist(maxCiteCount "${n}\midrule" Journal4 "${n}\midrule" Decade7 "${n}\midrule")) ///
		substitute(.\\ \\ .& &) ///
		replace
	create_latex using "`r(fn)'", tablename("balance0")
}

* Generate data for Table 9 and Figure 5
use `author_matching', clear
if "`R'"=="jel" drop if missing(JEL1_A01)|missing(JEL1_A11)

* Create temporary variables.
tempname a1 a2 a3 a4 a5 n bf1 sf1 bm1 sm1 nf1 nm1 b1 s1 n1 b2 s2 n2

foreach stat in flesch fleschkincaid gunningfog smog dalechall {

	* Mean Conditions 1--2.
	generate _`stat'_Dtm = _`stat'_R12 - _`stat'_R11 // Condition 2 for the male member.
	label variable _`stat'_Dtm "Condition 2 for the male member (`stat')"
	generate _`stat'_Dg = _`stat'_R02 - _`stat'_R12 // Condition 1.
	label variable _`stat'_Dg "Condition 1 (`stat')"
	generate _`stat'_Dtf = _`stat'_R02 - _`stat'_R01 // Condition 2 for the female member.
	label variable _`stat'_Dtf "Condition 2 for the female member (`stat')"

	tempvar D S

	* Dik.
	* Generate binary variable equation to 1 if Conditions (1) and (2) are satisfied
	* for the female pair and 0 if they're satisfied for the male pair. Set
	* inconculsive matched pairs as missing.
	generate _`stat'_D = 1 if _`stat'_Dtf>0 & _`stat'_Dg>0 // 1 if satisfed for the female member.
	replace _`stat'_D = 0 if  _`stat'_Dtm>0 & _`stat'_Dg<0 // 0 if satisfied for the male member.
	replace _`stat'_D = .a if missing(_`stat'_D)
	label variable _`stat'_D "Simultaneous satisfaction of Conditions 1 and 2 (`flesch')"
	capture label define satisfied 1 "Female member" 0 "Male member" .a "Inconclusive"
	label values _`stat'_D satisfied

	* Generate variable equal to gender difference in readability when Conditions
	* (1) and (2) are satisfied according to Equation (13)
	generate _`stat'_Ds1 = _`stat'_Dg if !missing(_`stat'_D)
	replace _`stat'_Ds1 = _`stat'_Dtf if _`stat'_D==1 & _`stat'_R01 > _`stat'_R12
	replace _`stat'_Ds1 = -1*_`stat'_Dtm if _`stat'_D==0 & _`stat'_R11 > _`stat'_R02
	label variable _`stat'_Ds1 "Dik (`stat')"

	* Unconditional mean Dik (Dik=0 when inconclusive).
	generate _`stat'_UDs1 = _`stat'_Ds1
	replace _`stat'_UDs1 = 0 if missing(_`stat'_D)
	label variable _`stat'_UDs1 "Unconditional Dik (`stat', 1)"

	* Unconditional mean percentage (Dik/max{R_it'',Rkt}).
	generate _`stat'_Ds1_percent = 0
	replace _`stat'_Ds1_percent = _`stat'_Ds1 / abs(_`stat'_R12) if _`stat'_D==1 & _`stat'_R01 < _`stat'_R12
	replace _`stat'_Ds1_percent = _`stat'_Ds1 / abs(_`stat'_R01) if _`stat'_D==1 & _`stat'_R01 > _`stat'_R12
	replace _`stat'_Ds1_percent = _`stat'_Ds1 / abs(_`stat'_R02) if _`stat'_D==0 & _`stat'_R11 < _`stat'_R02
	replace _`stat'_Ds1_percent = _`stat'_Ds1 / abs(_`stat'_R11) if _`stat'_D==0 & _`stat'_R11 > _`stat'_R02
	label variable _`stat'_Ds1_percent "Dik as % of max{R_it'',Rkt}"

	* Sample mean Dik. Conditional mean Dik (conditional on discrimination against the female pair).
	summarize _`stat'_Ds1 [aw=_weight0] if _`stat'_D==1
	matrix `bf1' = nullmat(`bf1'), r(mean)
	matrix `sf1' = nullmat(`sf1'), r(sd)
	matrix `nf1' = nullmat(`nf1'), r(N)

	* Conditional mean Dik (conditional on discrimination against the male pair).
	summarize _`stat'_Ds1 [aw=_weight1] if _`stat'_D==0
	matrix `bm1' = nullmat(`bm1'), r(mean)
	matrix `sm1' = nullmat(`sm1'), r(sd)
	matrix `nm1' = nullmat(`nm1'), r(N)

	* Conditional mean Dik.
	mean _`stat'_Ds1 [aw=_weight1]
	local df_correct = `e(df_r)'/(`e(N)'-2*`df'-1)
	matrix `b1' = nullmat(`b1'), _b[_`stat'_Ds1]
	matrix `s1' = nullmat(`s1'), _se[_`stat'_Ds1]*`df_correct'
	matrix `n1' = nullmat(`n1'), e(N)

	* Unconditional mean Dik (Dik=0 when inconclusive).
	mean _`stat'_UDs1 [aw=_weight1]
	local df_correct = `e(df_r)'/(`e(N)'-2*`df'-1)
	matrix `b2' = nullmat(`b2'), _b[_`stat'_UDs1]
	matrix `s2' = nullmat(`s2'), _se[_`stat'_UDs1]*`df_correct'
	matrix `n2' = nullmat(`n2'), e(N)

	* Proportional effect on discrimination (unconditional Dik).
	if "`R'"=="base" {
		mean _`stat'_Ds1_percent [aw=_weight1]
		matrix `a1' = nullmat(`a1') \ _b[_`stat'_Ds1_percent]
	}

	* Count observations one standard deviation above and below zero.
	summarize _`stat'_Ds1 [aw=_weight1]
	local sd = r(sd)
	count if _`stat'_D==1 & _`stat'_Ds1>`sd'
	local women = `r(N)'
	count if _`stat'_D==0 & _`stat'_Ds1<-1*`sd'
	local men = `r(N)'
	matrix `a2' = nullmat(`a2') \ `women' / `men'

	* Count observations exhibiting discrimination.
	count if !missing(_`stat'_D)
	matrix `n' = nullmat(`n') , `r(N)'
}

if "`R'"=="base" {
	* Display average proportional effect on discrimination (2).
	mata: st_local("max", strofreal(max(st_matrix("`a1'"))))
	mata: st_local("min", strofreal(min(st_matrix("`a1'"))))
	matrix `a1' = diag(`a1')
	display as text "Average proportional effect on discrimination (1): " as error round((trace(`a1') / colsof(`a1'))*100,0.01)
	display as text "Max proportional effect on discrimination (2): " as error round(`max'*100,0.01)
	display as text "Min proportional effect on discrimination (2): " as error round(`min'*100,0.01)

	* Display average ratio of observations above and below zero.
	matrix `a2' = diag(`a2')
	display as text "Average ratio of observations above and below zero: " as error round((trace(`a2') / colsof(`a2')),0.01)

	* Percentage of matched pairs with Dik not equal to zero.
	matrix `a3' = diag(`n'/`=_N')
	display as text "Average percentage of observations exhibiting evidence of discrimination: " as error round((trace(`a3') / colsof(`a3'))*100,0.01)

	* Percentage of Dik not equal to zero pairs in which Dik is positive.
	matrix `a4' = diag(hadamard(`nf1', vecdiag(inv(diag(`n')))))
	display as text "Conditional on discrimination, percentage of pairs discriminating against women: " as error round((trace(`a4') / colsof(`a4'))*100,0.01)

	* Relative size of Dik.
	matrix `a5' = diag(hadamard(`bf1', vecdiag(inv(diag(`bm1')))))
	display as text "Conditional on discrimination, ratio of female to male measures of discrimination: " as error abs(round((trace(`a5') / colsof(`a5')),0.01))

	* Degrees of freedom correction.
	display as text "Degrees of freedom correction: " as error round(`df_correct', 0.01)

	* Save data.
	order id AuthorID* _weight* T* *Ds* *Dg *Dtf *Dtm *D FemRatio* *R01 *R02 *R11 *R12 *score*
	order JEL*, last
	save "~/tonal_analysis/data/raw/hengel_generated/author_matching_dik", replace
}

* Main estimation results
ereturn_post `bf1', se(`sf1') store(df1) colnames(flesch fleschkincaid gunningfog smog dalechall) matrix(N `nf1')
ereturn_post `bm1', se(`sm1') store(dm1) colnames(flesch fleschkincaid gunningfog smog dalechall) matrix(N `nm1')
ereturn_post `b1', se(`s1') store(d21) colnames(flesch fleschkincaid gunningfog smog dalechall) matrix(N `n1')
ereturn_post `b2', se(`s2') store(d31) colnames(flesch fleschkincaid gunningfog smog dalechall) matrix(N `n2')

matching_table, type(`R')
matching_figure, type(`R')
}
********************************************************************************
