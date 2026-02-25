********************************************************************************
****************** Table C.1: Tertiary JEL code classification *****************
********************************************************************************
* Import list of JEL codes.
import delimited "~/tonal_analysis/data/raw/hengel_generated/JEL.csv", clear varnames(1) case(preserve) encoding("utf-8") bindquotes(strict)

* Classify all JEL codes without an Empirical or Theory classifications as "Other".
replace Type = "Other" if missing(Type)

* Create lists of empirical, theory and other JEL codes.
levelsof JEL if Type=="Empirical", local(empirical) clean
levelsof JEL if Type=="Theory", local(theory) clean
levelsof JEL if Type=="Other", local(other) clean

clear
set obs 3
* Create a dataset with two variables: 1 is Type (empirical/theory/other)
generate Type = "Empirical" in 1
replace Type = "Theory" in 2
replace Type = "Other" in 3
* The second variable is the corresponding list of JEL codes.
generate JEL = `"`empirical'"' if Type=="Empirical"
replace JEL = `"`theory'"' if Type=="Theory"
replace JEL = `"`other'"' if Type=="Other"

* Export to LaTeX table.
listtex * using "~/tonal_analysis/outputs/tables/tex/Table-C.1.tex", replace end("\\")
create_latex using "~/tonal_analysis/outputs/tables/tex/Table-C.1.tex", tablename("jel")
********************************************************************************
