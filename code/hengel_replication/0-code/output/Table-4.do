********************************************************************************
********* Table 4: Textual characteristics, published papers vs. drafts ********
********************************************************************************
use `nber', clear
tempname b s B S
foreach stat in _sent_count _char_count _word_count _sybl_count _polysyblword_count _notdalechall_count _flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score {

  * Analyse changes in papers with a female ratio below 0.5.
  mean nber`stat' `stat' if FemRatio<0.5
  lincom _b[`stat']-_b[nber`stat']
  matrix `b' = (e(b), r(estimate))
  matrix `s' = (vecdiag(cholesky(e(V))), r(se))
  local N = e(N)
  local dof = r(df)

  * Analyse changes in papers with a female ratio above 0.5.
  mean nber`stat' `stat' if Fem50==1
  lincom _b[`stat']-_b[nber`stat']
  matrix `b' = (`b', e(b), r(estimate))
  matrix `s' = (`s', vecdiag(cholesky(e(V))), r(se))
  local N_f = e(N)
  local dof_f = r(df)

  * Difference-in-differences.
  generate diff`stat' = `stat' - nber`stat'
  regress diff`stat' i.Fem50
  matrix `b' = (`b', _b[1.Fem50])
  matrix `s' = (`s', _se[1.Fem50])
  local N_all = e(N)
  local dof_all = r(df)

  matrix `B' = nullmat(`B') \ `b'
  matrix `S' = nullmat(`S') \ `s'
}

forvalues i=1/7 {
  matrix `b' = `B'[1...,`i']'
  matrix `s' = `S'[1...,`i']'
  if `i' == 4 {
    local N = `N_f'
    local dof = `dof_f'
  }
  if `i' == 7 {
    count
    local N = `r(N)'
  }
  ereturn_post `b', se(`s') obs(`N') dof(`dof') colnames(_sent_count _char_count _word_count _sybl_count _polysyblword_count _notdalechall_count _flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score) store(sum_`i')
}

* Create LaTeX table.
estout sum_* using "~/tonal_analysis/outputs/tables/tex/Table-4.tex", style(publishing-female_latex) ///
  cells("b(fmt(2) pattern(1 1 0 1 1 0 0)) b(star fmt(3) pattern(0 0 1 0 0 1 1))" "se(par fmt(2) pattern(1 1 0 1 1 0 0)) se(par fmt(3) pattern(0 0 1 0 0 1 1))") ///
  stats(N, labels("No. observations")) ///
  varlabels(, prefix("\mrow{3cm}{") suffix("}") blist(_flesch_score "\midrule${n}")) ///
  prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table5")
********************************************************************************
