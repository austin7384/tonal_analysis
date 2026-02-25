program latextable
	syntax [using/] [, long *]
	
	if "`using'" == "" {
		local using "`r(fn)'"
	}
	
	tempname fh1
	tempfile tmp
	copy `"`using'"' `tmp', text
	file open `fh1' using `"`using'"', write text replace
	
	if "`long'" != "" {
		longtable using `tmp', fh1(`fh1') `options'
	}
	else {
		shorttable using `tmp', fh1(`fh1') `options'
	}
	
	file close `fh1'
end

program longtable
	syntax using/, fh1(namelist) cellwidth(string) header(string) colnum(integer) [title(string) label(string) note(string) opener(string) sample(string) separ(string) star(string) full(string)]
	
	file write `fh1' _col(1) "\begin{ThreePartTable}" _n
	file write `fh1' _col(5) "\begin{TableNotes}" _n
	file write `fh1' _col(9) "\tiny"
	
	tablenote, fh(`fh1') note(`"`note'"') opener(`"`opener'"') sample(`"`sample'"') separ(`"`separ'"') star(`"`star'"') full(`"`full'"')
	
	file write `fh1' _col(5) "\end{TableNotes}" _n
	file write `fh1' _col(5) "{\scriptsize\begin{longtable}[c]{`cellwidth'}" _n
	
	if "`label'" == "" {
		local match = regexm("`r(fn)'", ".*/(.*)\.tex")
		local label = regexs(1)
	}
	file write `fh1' _col(9) "\caption{`title'}\label{`label'} \\" _n
	
	file write `fh1' _col(9) "\toprule" _n
	file write `fh1' _col(9) "`header' \\" _n
	file write `fh1' _col(9) "\midrule" _n
	file write `fh1' _col(9) "\endfirsthead" _n
	file write `fh1' _col(9) "\multicolumn{`colnum'}{c}{\normalsize{\tablename~\thetable{} (continued)}} \\" _n
	file write `fh1' _col(9) "\toprule" _n
	file write `fh1' _col(9) "`header' \\" _n
	file write `fh1' _col(9) "\midrule" _n
	file write `fh1' _col(9) "\endhead" _n
	file write `fh1' _col(9) "\midrule" _n
	file write `fh1' _col(9) "\endfoot" _n
	file write `fh1' _col(9) "\bottomrule" _n
	file write `fh1' _col(9) "\insertTableNotes" _n
	file write `fh1' _col(9) "\endlastfoot" _n
	
	copytable using `"`using'"', fh1(`fh1')

	file write `fh1' _col(5) "\end{longtable}}" _n
	file write `fh1' _col(1) "\end{ThreePartTable}" _n
end

program shorttable
	syntax using/, fh1(namelist) cellwidth(string) [header(string) title(string) label(string) float note(string) opener(string) sample(string) separ(string) star(string) full(string) landscape adjustwidth(string) sisetup(string) span]
	
	if "`float'" != "" {
		local float "[H]"
	}
	if "`label'" == "" {
		local match = regexm("`r(fn)'", ".*/(.*)\.tex")
		local label = regexs(1)
	}
	if "`span'" != "" {
		local span "*"
	}
	if "`landscape'" != "" {
		file write `fh1' _col(1) "\begin{sidewaystable}" _n
	}
	else {
		file write `fh1' _col(1) "\begin{table`span'}`float'" _n
	}
	if "`adjustwidth'" != "" {
		file write `fh1' _col(5) "\begin{adjustwidth}{`adjustwidth'}{}" _n
	}
	file write `fh1' _col(5) "\footnotesize" _n
	file write `fh1' _col(5) "\centering" _n
	file write `fh1' _col(5) "\begin{threeparttable}" _n
	
	file write `fh1' _col(9) "\caption{`title'}" _n
	file write `fh1' _col(9) "\label{`label'}" _n
	
	if "`sisetup'" != "" {
		file write `fh1' _col(9) `"\sisetup{`sisetup'}"' _n
	}
	
	file write `fh1' _col(9) "\begin{tabular}{`cellwidth'}" _n
	file write `fh1' _col(13) "\toprule" _n
	if "`header'" != "" {
		file write `fh1' _col(13) "`header'\\" _n
		file write `fh1' _col(13) "\midrule" _n
	}
	
	copytable using `"`using'"', fh1(`fh1')
	
	file write `fh1' _col(13) "\bottomrule" _n
	file write `fh1' _col(9) "\end{tabular}" _n
	file write `fh1' _col(9) "\begin{tablenotes}" _n
	file write `fh1' _col(13) "\tiny" _n
	
	tablenote, fh(`fh1') note(`"`note'"') opener(`"`opener'"') sample(`"`sample'"') separ(`"`separ'"') star(`"`star'"') full(`"`full'"')
	
	file write `fh1' _col(9) "\end{tablenotes}" _n
	file write `fh1' _col(5) "\end{threeparttable}" _n
	if "`adjustwidth'" != "" {
		file write `fh1' _col(5) "\end{adjustwidth}" _n
	}
	if "`landscape'" != "" {
		file write `fh1' _col(1) _n "\end{sidewaystable}" _n
	}
	else {
		file write `fh1' _col(1) "\end{table`span'}"
	}
end

program copytable
	syntax using/, fh1(namelist)
	tempname fh2
	file open `fh2' using `"`using'"', read
	file read `fh2' line
	while r(eof) == 0 {
		file write `fh1' _col(13) `"`macval(line)'"' _n
		file read `fh2' line
	}
	file close `fh2'
end
	
program tablenote
	syntax, fh(namelist) [note(string) opener(string) sample(string) separ(string) star(string) full(string)]
	
	* Sample size.
	if `"`sample'"' != "" {
		tokenize `"`sample'"', parse(",")
		confirm integer number `1'
		
		local N : display %10.0fc `1'
		local N = trim("`N'")
		
		if `"`3'"' != "" {
			local regexm = ustrregexm(`"`3'"', "^obs\((.*)\)$")
			local obs = " " + ustrtrim(ustrregexs(1))
		}
		
		local sample "Sample `N'`obs'. "
	}
	
	* full ouput.
	if `"`full'"' != "" {
		local full = "Full output in `full'. "
	}
	
	* Standard errors: normal, robust, bootstrapped, clustered, weighted
	if `"`separ'"' != "" {
		if `"`separ'"' == "normal" {
			local separ "Standard errors in parentheses. "
		}
		else {
			tokenize `"`separ'"', parse(",")
			if `"`1'"' == "robust" {
				local regexm = ustrregexm(`"`3'"', `"^paren\("(.*)"\)$"')
				if `regexm' {
					local text = " (" + ustrtrim(ustrregexs(1)) + ")"
				}
				local separ "Robust standard errors in parentheses`text'. "
			}
			else if `"`1'"' == "bootstrap" {
				local separ "Bootstrapped standard errors in parentheses. "
			}
			else if `"`1'"' == "cluster" | `"`1'"' == "weighted" {
				local regexm = ustrregexm(`"`3'"', "^by\((.*)\)$")
				local by = ustrtrim(ustrregexs(1))
				local separ "Standard errors in parentheses, `1'ed by `by'. "
			}
		}
	}
	
	* Stars
	if `"`star'"' != "" {
		if `"`star'"' == "all" {
			local star ""
		}
		local star "***, ** and * `star' statistically significant at 1\%, 5\% and 10\%, respectively. "
	}
	
	* First text.
	if "`opener'" == "" {
		local opener "Notes"
	}
	if `"`opener'"' != "" {
		local opener `"\textit{`opener'}. "'
	}
	
	* Find numbers and format.
	while ustrregexm(`"`note'"', "[^\w](\d{4,})") {
		local num = ustrregexs(1)
		local format_num : display %9.0fc `num'
		local note = usubinstr(`"`note'"', "`num'", "`format_num'", 1)
	}
	
	* Fix mis-formmated years.
	local note = subinstr(`"`note'"', "2,015", "2015", .)
	local note = subinstr(`"`note'"', "1,950", "1950", .)
	local note = subinstr(`"`note'"', "2,000", "2000", .)
	local note = subinstr(`"`note'"', "1,990", "1990", .)
	local note = subinstr(`"`note'"', "1,976", "1976", .)
	local note = subinstr(`"`note'"', "1,998", "1998", .)
	// local note = subinstr(`"`note'"', "1,970", "1970", .)
	
	* String together.
	local note `"`opener' `sample' `note' `separ' `star' `full'"'
	if `"note"' != "" {
		local note = ustrtrim(stritrim(`"`note'"'))
		local note = subinstr(`"`note'"', "( ", "(", .)
		local note = subinstr(`"`note'"', " )", ")", .)
		local note = subinstr(`"`note'"', " .", ".", .)
		file write `fh' _col(13) `"\item `note'"' _n
	}
end
exit