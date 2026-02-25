********************************************************************************
*********** Table 2: Textual characteristics per sentence, by gender ***********
********************************************************************************
use `article', clear
replace Fem50 = 0 if missing(Fem50)
tempname B SE N
foreach stat in char word sybl polysyblword notdalechall {
  replace _`stat'_count = _`stat'_count / _sent_count
  regress _`stat'_count i.Fem50
  lincom _b[_cons] + _b[1.Fem50]
  matrix `B' = (nullmat(`B') , (_b[_cons] \ r(estimate) \ _b[1.Fem50]))
  matrix `SE' = (nullmat(`SE') , (_se[_cons] \ r(se) \ _se[1.Fem50]))
}

tempname b se n
matrix `b' = `B'[1, 1...]
matrix `se' = `SE'[1, 1...]
count if Fem50==0
ereturn_post `b', se(`se') obs(`r(N)') dof(`e(df_r)') store(sum_1) colnames(_char_count _word_count _sybl_count _polysyblword_count _notdalechall_count)

matrix `b' = `B'[2, 1...]
matrix `se' = `SE'[2, 1...]
count if Fem50==1
ereturn_post `b', se(`se') obs(`r(N)') dof(`e(df_r)') store(sum_2) colnames(_char_count _word_count _sybl_count _polysyblword_count _notdalechall_count)

matrix `b' = `B'[3, 1...]
matrix `se' = `SE'[3, 1...]
count if Fem50==0 | Fem50==1
ereturn_post `b', se(`se') obs(`r(N)') dof(`e(df_r)') store(sum_3) colnames(_char_count _word_count _sybl_count _polysyblword_count _notdalechall_count)

estout sum_* using "~/tonal_analysis/outputs/tables/tex/Table-2.tex", style(publishing-female_latex) ///
  cells("b(fmt(2) pattern(1 1 0)) b(star fmt(2) pattern(0 0 1))" "se(par fmt(2) pattern(1 1 0)) se(par fmt(2) pattern(0 0 1))") ///
  stats(N, labels("No. observations")) ///
  varlabels(, prefix("\mrow{4cm}{") suffix("}")) ///
  prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table2")
********************************************************************************
