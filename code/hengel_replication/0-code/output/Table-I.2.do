********************************************************************************
************ Table I.2: Average first, mean and final paper scores. ************
********************************************************************************
use `author', clear
sort AuthorID t
tempname B b
foreach stat in flesch fleschkincaid gunningfog smog dalechall {
	preserve
	collapse (mean) Mean=_`stat'_score (first) Female First=_`stat'_score (last) Last=_`stat'_score if T>2, by(AuthorID)
	label values Female gender
	mean First Mean Last, over(Female)
	ereturn_post e(b) e(V), obs(`e(N)') dof(`e(df_r)') store(firstlast_`stat')

	* Percentage change from first score (cf. Section 4.2)
	matrix `b' = e(b)
	matrix `b' = (`b'[1, 3]-`b'[1,1])/`b'[1,1] \ (`b'[1, 4]-`b'[1,2])/`b'[1,2] \ (`b'[1, 5]-`b'[1,1])/`b'[1,1] \ (`b'[1, 6]-`b'[1,2])/`b'[1,2]
	matrix `B' = nullmat(`B') , 100*`b'
	restore
}
matrix rownames `B' = Mean:Women Mean:Men Last:Women Last:Men

estout firstlast_* using "~/tonal_analysis/outputs/tables/tex/Table-I.2.tex", style(publishing-female_latex) ///
	cells(b(nostar fmt(2)) se(par fmt(2))) ///
  stats(N, labels("No. observations")) prefoot("\midrule") ///
	varlabels( ///
		c.First@0.Female "Men" ///
		c.First@1.Female "Women" ///
		c.Mean@0.Female "Men" ///
		c.Mean@1.Female "Women" ///
		c.Last@0.Female "Men" ///
		c.Last@1.Female "Women", ///
			elist( ///
				c.First@1.Female "${n}\midrule${n}\multicolumn{6}{l}{\textbf{Average mean paper score}}\\" ///
				c.Mean@1.Female "${n}\midrule${n}\multicolumn{6}{l}{\textbf{Average final paper score}}\\") ///
			prefix("\quad ") ///
			blist(c.First@0.Female "\multicolumn{6}{l}{\textbf{Average first paper score}}\\\${n}"))
create_latex using "`r(fn)'", tablename("tableH1")
********************************************************************************
