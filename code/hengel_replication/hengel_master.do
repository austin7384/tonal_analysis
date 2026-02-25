********************************************************************************
*********************************** MASTER DO **********************************
********************************************************************************
* Set version, seed, mata and matrix settings
clear all
version 17.0
set seed 677275986 // French mobile number
mata: mata set matafavor speed
set matsize 5000
set maxvar 32767

* Install third-party packages.
ssc install ftools
ssc install estout
ssc install psmatch2
ssc install xtabond2
ssc install listtex
ssc install reghdfe
ssc install binscatter
ssc install distinct
ssc install labutil
ssc install coefplot
net install "https://mloeffler.github.io/stata/wordwrap"

* Install personal ado files by copying them to your personal ado directory.
local files : dir `"0-code/programs/stata"' files "*"
foreach file of local files {
	copy `"0-code/programs/stata/`file'"' "`: sysdir PERSONAL'", replace
}

* Custom program to create LaTeX table.
capture program drop create_latex
program define create_latex
	syntax using/, tablename(string) [type(string)]
	preserve
	* Import Excel spreadsheet with LaTeX table components.
	import excel "~/tonal_analysis/data/raw/hengel_labels/tables.xlsx", firstrow clear case(preserve) allstring
	keep if TableName=="`tablename'" & Type=="`type'"
	local title `"`=Title[1]'"'
	local note `"`=Note[1]'"'
	local cellwidth `"`=CellWidth[1]'"'
	local header `"`=Header[1]'"'
	local label `"`=Label[1]'"'
	local float `"`=Float[1]'"'
	local star `"`=Star[1]'"'
	local adjustwidth `"`=AdjustWidth[1]'"'
	local sisetup `"`=SISetup[1]'"'
	local landscape `"`=Landscape[1]'"'
	local colnum `"`=ColNum[1]'"'
	local long `"`=Long[1]'"'
	restore
	if `"`adjustwidth'"'!= "" {
		local adjustwidth adjustwidth(`"`adjustwidth'"')
	}
	if `"`sisetup'"'!="" {
		local sisetup sisetup(`"`sisetup'"')
	}
	if `"`star'"'!="" {
		local star star(`"`star'"')
	}
	if `"`colnum'"'!="" {
		local colnum colnum(`colnum')
	}
	latextable using `"`using'"', title(`"`title'"') note(`"`note'"') cellwidth(`"`cellwidth'"') header(`"`header'"') label(`"`label'"') `star' `float' `adjustwidth' `sisetup' `landscape' `colnum' `long'
end

* Clear screen and start time.
timer clear 1
timer on 1
capture cls

* Start log
capture log close last_log
log using "~/tonal_analysis/data/raw/`: display %tCCCYY-NN-DD-HH-MM-SS Clock("`c(current_date)' `c(current_time)'", "DMYhms")'", name(last_log) replace smcl
display as error "{title:Publishing while Female replication.}" _n "Austin Coffelt" _n trim(c(current_date)) ", " c(current_time)

* Create datasets.
include "0-code/output/Data.do"

* Run analyses.
include "0-code/output/Figure-1.do"
include "0-code/output/Figure-2.do"
include "0-code/output/Table-2.do"
include "0-code/output/Table-3.do"
include "0-code/output/Table-4.do"
include "0-code/output/Table-5.do"
include "0-code/output/Table-6.do"
include "0-code/output/Table-7.do"
include "0-code/output/Figure-4.do"
include "0-code/output/Table-8.do"
include "0-code/output/Section-4.3.do"
include "0-code/output/Figure-6.do"
include "0-code/output/Table-10.do"
include "0-code/output/Table-B.1.do"
include "0-code/output/Table-C.1.do"
include "0-code/output/Figure-D.1.do"
include "0-code/output/Figure-D.2.do"
include "0-code/output/Table-F.1.do"
include "0-code/output/Figure-F.1.do"
include "0-code/output/Table-F.2.do"
include "0-code/output/Table-G.1.do"
include "0-code/output/Table-G.2.do"
include "0-code/output/Figure-G.1.do"
include "0-code/output/Table-G.4.do"
include "0-code/output/Table-H.3.do"
include "0-code/output/Table-H.4.do"
include "0-code/output/Table-I.2.do"
include "0-code/output/Table-J.2.do"
include "0-code/output/Figure-K.1.do"

* List timer, close log and exit.
timer off 1
timer list 1
display as error "Time to run code: `r(t1)' seconds"
log close last_log
beep
********************************************************************************
