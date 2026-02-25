********************************************************************************
******************** Figure D.1: Readability score validity. *******************
********************************************************************************
* Meta analysis of readability score validity.
import delimited "~/tonal_analysis/data/raw/hengel_generated/readability_corr.txt", clear case(preserve) varnames(1) encoding("utf-8")

* Save data on numbers of correlation coefficients and studies.
preserve
	by TestType Source, sort: generate Study = cond(_n==1, 1, 0)
	collapse (median) median=Correlation (count) corrs=Correlation (sum) studies=Study, by(TestType)
	sort median
	tempname bd
	mkmat median corrs studies, matrix(`bd') rownames(TestType)
restore

* Bibliography list of studies.
preserve
keep Source
duplicates drop
generate bib = "\nocite{" + Source + "}"
list in 1/10
outfile bib using "~/tonal_analysis/outputs/tables/tex/Figure-D.1-bib.tex", replace noquote
restore

* Box and whiskers plot of correlations.
graph box Correlation, ///
	over(TestType, ///
		sort(1) ///
		gap(85) ///
		relabel(1 `""Human judgement{sup}{c 134}""' 2 `""Oral reading fluency""' ///
			3 `""Comprehension tests""' 4 `""Readability scores""' 5 `""Cloze procedure""')) ///
	scheme(publishing-female) ///
	nooutsides ///
	note("") ///
	legend(off) ///
	title("") ///
	subtitle("Correlation", placement(nwest) size(small)) ///
	ytitle("") ///
	asyvars ///
	showyvars ///
	medtype(cline) ///
	medline(lcolor(white) lwidth(vthin) lpattern(solid)) ///
	cwhiskers lines(lwidth(vthin)) alsize(0) ///
	intensity(90) ///
	lintensity(90) ///
	graphregion(margin(small)) ///
	box(1, color(pfblue)) ///
	box(2, color(pfblue)) ///
	box(3, color(pfblue)) ///
	box(4, color(pfyellow)) ///
	box(5, color(pfblue)) ///
	text(`"`: display `bd'[1,1]+0.001'"' 8 `"{it: N} = `: display `bd'[1,2]'"' " " "`: display `bd'[1,3]' studies", size(vsmall) color(white)) ///
	text(`"`: display `bd'[2,1]+0.002'"' 29 `"{it: N} = `: display `bd'[2,2]'"' " " "`: display `bd'[2,3]' studies", size(vsmall) color(white)) ///
	text(`"`: display `bd'[3,1]+0.002'"' 50 `"{it: N} = `: display `bd'[3,2]'"' " " "`: display `bd'[3,3]' studies", size(vsmall) color(white)) ///
	text(`"`: display `bd'[4,1]+0.004'"' 71 `"{it: N} = `: display `bd'[4,2]'"' " " "`: display `bd'[4,3]' studies", size(vsmall) color(white)) ///
	text(`"`: display `bd'[5,1]-0.002'"' 92 `"{it: N} = `: display `bd'[5,2]'"' " " "`: display `bd'[5,3]' studies", size(vsmall) color(black)) ///
	aspectratio(0.4) ///
	name(meta, replace)
graph export "~/tonal_analysis/outputs/figures/Figure-D.1-meta.pdf", replace fontface("Avenir-Light") as(pdf)

* Correlation between readability scores and citations.
use `article', clear
binscatter asinhCiteCount _flesch_score if Year<1990 ///
	, scheme(publishing-female) ///
	legend(off) ///
	name(corr1990, replace) ///
	color(pfblue pfblue) ///
	xtitle("Flesch Reading Ease", placement(seast) size(medium)) ///
	title("") ///
	ytitle("Citation count (asinh)", size(medium)) ///
	subtitle("Papers published before 1990", placement(nwest) size(medium))
graph export "~/tonal_analysis/outputs/figures/Figure-D.1-early.pdf", replace fontface("Avenir-Light") as(pdf)
binscatter asinhCiteCount _flesch_score if Year>2000 ///
	, scheme(publishing-female) ///
	legend(off) ///
	name(corr2000, replace) ///
	color(pfblue pfblue) ///
	xtitle("Flesch Reading Ease", placement(seast) size(medium)) ///
	ytitle("Citation count (asinh)", size(medium)) ///
	title("") ///
	subtitle("Papers published after 2000", placement(nwest) size(medium))
graph export "~/tonal_analysis/outputs/figures/Figure-D.1-late.pdf", replace fontface("Avenir-Light") as(pdf)
********************************************************************************
