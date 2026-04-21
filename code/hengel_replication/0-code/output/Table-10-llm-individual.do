********************************************************************************
***** Table 10 LLM Individual: tth paper scores for 9 individual LLM criteria **
********************************************************************************
capture program drop tbl10_llm_ind
program define tbl10_llm_ind
  syntax, nber(string) auth(string) crit(string) fname(string) tblname(string)

  use "`nber'", clear
  merge m:m ArticleID using "`auth'", keep(match) nogenerate

  capture label define tBinTbl 1 "1" 2 "2" 3 "3" 4 "4-5" 5 "6+"
  tempvar tBin
  recode t (1=1)(2=2)(3=3)(4/5=4)(nonmissing=5), generate(`tBin')
  label values `tBin' tBinTbl

  eststo nber: regress nber_llm_`crit'_score c.FemRatio##c.`tBin' Maxt MaxT asinhCiteCount N i.NativeEnglish i.Year##i.Journal i.Editor [aweight=AuthorWeight]
  eststo reg:  regress _llm_`crit'_score     c.FemRatio##c.`tBin' Maxt MaxT asinhCiteCount N i.NativeEnglish i.Year##i.Journal i.Editor [aweight=AuthorWeight]
  eststo suest: suest nber reg, vce(cluster Editor)

  tempname B SE se b

  * Direct impact of peer review: Female.
  margins, at(FemRatio=1) over(`tBin') expression(predict(equation(reg_mean))-predict(equation(nber_mean)))
  matrix `B' = nullmat(`B') \ r(b)
  matrix `se' = r(table)
  matrix `SE' = nullmat(`SE') \ `se'[rownumb(`se',"se"), 1...]

  * Direct impact of peer review: Male.
  margins, at(FemRatio=0) over(`tBin') expression(predict(equation(reg_mean))-predict(equation(nber_mean)))
  matrix `B' = nullmat(`B') \ r(b)
  matrix `se' = r(table)
  matrix `SE' = nullmat(`SE') \ `se'[rownumb(`se',"se"), 1...]

  * Impact of female ratio: published articles.
  margins, dydx(FemRatio) over(`tBin') predict(equation(reg_mean))
  matrix `B' = nullmat(`B') \ r(b)
  matrix `se' = r(table)
  matrix `SE' = nullmat(`SE') \ `se'[rownumb(`se',"se"), 1...]

  * Impact of female ratio: working papers.
  margins, dydx(FemRatio) over(`tBin') predict(equation(nber_mean))
  matrix `B' = nullmat(`B') \ r(b)
  matrix `se' = r(table)
  matrix `SE' = nullmat(`SE') \ `se'[rownumb(`se',"se"), 1...]

  * Difference.
  margins, at(FemRatio=0 FemRatio=1) over(`tBin') contrast(atcontrast(r)) expression(predict(equation(reg_mean))-predict(equation(nber_mean)))
  matrix `B' = nullmat(`B') \ r(b)
  matrix `se' = r(table)
  matrix `SE' = nullmat(`SE') \ `se'[rownumb(`se',"se"), 1...]

  forvalues i=1/`=colsof(`B')' {
    matrix `b' = `B'[1...,`i']'
    matrix `se' = `SE'[1...,`i']'
    ereturn_post `b', se(`se') colnames(women men reg nber diff) obs(`e(N)') store(est_`i') local(jnlyr ✓ editor ✓ Nj ✓ qual ✓² native ✓)
  }

  estout est_* using "~/tonal_analysis/outputs/tables/tex/Table-10-llm-`fname'.tex", style(publishing-female_latex) ///
    varlabels(women "\quad Women" ///
      men "\quad Men" ///
      diff "\midrule${n}\textbf{Diff.-in-diff.}" ///
      nber "\quad Draft paper" ///
      reg "\quad Published article" ///
      , blist(women "\multicolumn{6}{l}{\textbf{Predicted \(R_{jP}-R_{jW}\)}}\\\${n}" ///
          reg "\midrule\multicolumn{6}{l}{\textbf{Marginal effect of female ratio}}\\\${n}"))
  create_latex using "`r(fn)'", tablename("`tblname'")
  estimates clear
end

tbl10_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(modal_verb)    fname(modal-verb)    tblname(table9llmmodalverb)
tbl10_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(hedging)       fname(hedging)       tblname(table9llmhedging)
tbl10_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(ack_limits)    fname(ack-limits)    tblname(table9llmacklimits)
tbl10_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(active_passive) fname(active-passive) tblname(table9llmactivepas)
tbl10_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(directness)    fname(directness)    tblname(table9llmdirectness)
tbl10_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(pronoun)       fname(pronoun)       tblname(table9llmpronoun)
tbl10_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(novelty)       fname(novelty)       tblname(table9llmnovelty)
tbl10_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(jargon)        fname(jargon)        tblname(table9llmjargon)
tbl10_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(evidence)      fname(evidence)      tblname(table9llmevidence)
********************************************************************************
