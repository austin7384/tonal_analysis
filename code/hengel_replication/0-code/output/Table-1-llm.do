********************************************************************************
****** Table 1 LLM: Difference in means by gender, all LLM criteria ***********
********************************************************************************
use `article', clear
replace Fem50 = 0 if missing(Fem50)
tempname B SE
local criteria readability modal_verb hedging qualifier ack_limits caution ///
  assertiveness active_passive directness imperative pronoun novelty ///
  jargon emotional evidence practical

foreach crit of local criteria {
  regress _llm_`crit' i.Fem50
  lincom _b[_cons] + _b[1.Fem50]
  matrix `B' = (nullmat(`B') , (_b[_cons] \ r(estimate) \ _b[1.Fem50]))
  matrix `SE' = (nullmat(`SE') , (_se[_cons] \ r(se) \ _se[1.Fem50]))
}

local colnames _llm_readability _llm_modal_verb _llm_hedging _llm_qualifier ///
  _llm_ack_limits _llm_caution _llm_assertiveness _llm_active_passive ///
  _llm_directness _llm_imperative _llm_pronoun _llm_novelty _llm_jargon ///
  _llm_emotional _llm_evidence _llm_practical

tempname b se
matrix `b' = `B'[1, 1...]
matrix `se' = `SE'[1, 1...]
count if Fem50==0
ereturn_post `b', se(`se') obs(`r(N)') dof(`e(df_r)') store(sum_1) colnames(`colnames')

matrix `b' = `B'[2, 1...]
matrix `se' = `SE'[2, 1...]
count if Fem50==1
ereturn_post `b', se(`se') obs(`r(N)') dof(`e(df_r)') store(sum_2) colnames(`colnames')

matrix `b' = `B'[3, 1...]
matrix `se' = `SE'[3, 1...]
count if Fem50==0 | Fem50==1
ereturn_post `b', se(`se') obs(`r(N)') dof(`e(df_r)') store(sum_3) colnames(`colnames')

estout sum_* using "~/tonal_analysis/outputs/tables/tex/Table-1-llm.tex", style(publishing-female_latex) ///
  cells("b(fmt(2) pattern(1 1 0)) b(star fmt(2) pattern(0 0 1))" "se(par fmt(2) pattern(1 1 0)) se(par fmt(2) pattern(0 0 1))") ///
  stats(N, labels("No. observations")) ///
  varlabels(, prefix("\mrow{5cm}{") suffix("}")) ///
  prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table1llm")
********************************************************************************
