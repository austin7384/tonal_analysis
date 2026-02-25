********************************************************************************
**************** Table B.1: Article count by journal and decade ****************
********************************************************************************
use `article', clear

* Define decade of publication.
generate Decade = "1950--59" if Year < 1960
replace Decade = "1960--69" if Year < 1970 & missing(Decade)
replace Decade = "1970--79" if Year < 1980 & missing(Decade)
replace Decade = "1980--89" if Year < 1990 & missing(Decade)
replace Decade = "1990--99" if Year < 2000 & missing(Decade)
replace Decade = "2000--09" if Year < 2010 & missing(Decade)
replace Decade = "2010--15" if missing(Decade)

* Collapse and count by journal and decade then reshape so that each row is a decade and each column a journal.
collapse (count) _=ArticleID, by(Decade Journal)
tempvar Journal
decode Journal, generate(`Journal')
drop Journal
rename `Journal' Journal
reshape wide _, i(Decade) j(Journal) string
egen DecadeTotal = rowtotal(_*)

* Create total row.
set obs 8
replace Decade = "Total" in 8
foreach var of varlist _AER-DecadeTotal {
  sum `var'
  replace `var' = r(sum) in 8
}

* Save as matrix and export as LaTeX table.
tempname N
mkmat _* DecadeTotal, matrix(`N') rownames(Decade)
estout matrix(`N', fmt(%9.0f)) using "~/tonal_analysis/outputs/tables/tex/Table-B.1.tex", varlabels(, blist(Total "\midrule${n}")) ///
	replace style(tex) substitute(" ." "  ") mlabels(none) collabels(none)
create_latex using "`r(fn)'", tablename("table1")
********************************************************************************
