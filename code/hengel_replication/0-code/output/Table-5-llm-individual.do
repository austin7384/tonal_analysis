********************************************************************************
*** Table 5 LLM Individual: all 16 criteria, split into two sidewaystables ***
********************************************************************************
* nber_fe is redefined here so this file can run standalone (Table-5.do
* may be commented out in hengel_master.do).
capture program drop nber_fe
program define nber_fe, eclass
  syntax varname [if] using/, stats(string) colnames(string) [jel]
  use `using', clear

  * Get names of JEL dummy variables (needed for reghdfe, grr...).
  if "`jel'"=="jel" {
    local jcode1 "JEL1_*"
    local jel jel ✓
  }

  tempname b se B S bblind seblind
  foreach stat in `stats' {
    display "`stat'"

    if "`varlist'"=="FemRatio" | "`varlist'"=="FemSenior" {
      local female c.`varlist'
    }
    else {
      local female 1.`varlist'
    }
    eststo fe_`stat': reghdfe D._`stat'_score `female'##i.Blind Maxt MaxT asinhCiteCount N i.NativeEnglish Type_* `if', absorb(i.Editor i.Year##i.Journal `jcode1') vce(cluster Year)
    estadd local jnlyr = "✓"
    estadd local editor = "✓"
    matrix `b' = (nullmat(`b') , _b[`female'])
    matrix `se' = (nullmat(`se') , _se[`female'])

    matrix `bblind' = (nullmat(`bblind'), _b[1.Blind#`female'])
    matrix `seblind' = (nullmat(`seblind'), _se[1.Blind#`female'])
  }

  ereturn_post `b', se(`se') obs(`=e(N_full)') colnames(`colnames') store(fe) local(journal ✓ jnlyr ✓ editor ✓ Nj ✓ qual ✓² native ✓ `jel' theory ✓)
  ereturn_post `bblind', se(`seblind') colnames(`colnames') store(fe_blind)
end

* nber_fgls is redefined here with a firststats(string) option so the
* estimates restore call can refer to the first criterion in the stats list
* rather than always using ols*_llm_g1 (which only exists for composite tables).
* Note: blist "\\${n}" produces only "\" in estout tex output; the generated
* .tex files need a second "\" appended to group-header rows (post-processing).
capture program drop nber_fgls
program define nber_fgls, eclass
  syntax varname [if] [using/], stats(string) colnames(string) firststats(string) [jel]

  if "`using'"!="" {
    use `using', clear
  }

  * Get names of JEL dummy variables (needed for reghdfe, grr...).
  if "`jel'"=="jel" {
    local jcode1 "JEL1_*"
    local jel jel ✓
  }

  tempname B SE rb rse
  foreach stat in `stats' {

    if "`varlist'"=="FemRatio" | "`varlist'"=="FemSenior" {
      local female c.`varlist'
    }
    else {
      local female 1.`varlist'
    }

    * Rename NBER score variable to nber_score so it's constant across scores.
    rename nber_`stat'_score nber_score

    * Estimate OLS (first column).
    eststo ols_`stat': reghdfe _`stat'_score nber_score `female'##i.Blind N Maxt MaxT asinhCiteCount i.NativeEnglish Type_* `if', absorb(i.Year##i.Journal i.Editor `jcode1') vce(cluster Editor)
    local b_fem = _b[`female']
    local se_fem = _se[`female']

    local bblind_fem = _b[1.Blind#`female']
    local seblind_fem = _se[1.Blind#`female']

    local nber_b = _b[nber_score]
    local nber_se = _se[nber_score]

    * Rename NBER score its original name.
    rename nber_score nber_`stat'_score

    * FGLS (second to fourth columns).
    eststo nber: regress nber_`stat'_score `female'##i.Blind Maxt MaxT asinhCiteCount N i.NativeEnglish Type_* i.Year##i.Journal i.Editor `jcode1' `if'
    eststo reg: regress _`stat'_score `female'##i.Blind Maxt MaxT asinhCiteCount N i.NativeEnglish Type_* i.Year##i.Journal i.Editor `jcode1' `if'
    eststo suest: suest nber reg, vce(cluster Year)

    lincom _b[reg_mean:`female'] - _b[nber_mean:`female']
    local b_diff = r(estimate)
    local se_diff = r(se)

    lincom _b[reg_mean:`female'#1.Blind] - _b[nber_mean:`female'#1.Blind]
    local blindb_diff = r(estimate)
    local blindse_diff = r(se)

    matrix `B' = (nullmat(`B'), (`nber_b' \ `b_fem' \ `bblind_fem' \ _b[nber_mean:`female'] \ _b[nber_mean:1.Blind#`female'] \ _b[reg_mean:`female'] \ _b[reg_mean:1.Blind#`female'] \ `b_diff' \ `blindb_diff'))
    matrix `SE' = (nullmat(`SE'), (`nber_se' \ `se_fem' \ `seblind_fem' \ _se[nber_mean:`female'] \ _se[nber_mean:1.Blind#`female'] \ _se[reg_mean:`female'] \ _se[reg_mean:1.Blind#`female'] \ `se_diff' \ `blindse_diff'))
  }

  * Post results in e-class.
  tempname b se

  * OLS estimates controlling for draft score estimates.
  matrix `b' = `B'[1, 1...]
  matrix `se' = `SE'[1, 1...]
  estimates restore ols*_`firststats'
  ereturn_post `b', se(`se') colnames(`colnames') store(reg_nber)

  matrix `b' = `B'[2, 1...]
  matrix `se' = `SE'[2, 1...]
  estimates restore ols*_`firststats'
  ereturn_post `b', se(`se') obs(`=e(N_full)') colnames(`colnames') store(reg) local(jnlyr ✓ editor ✓ Nj ✓ qual ✓² native ✓ `jel' theory ✓)

  * Blind x female coefficient.
  matrix `b' = `B'[3, 1...]
  matrix `se' = `SE'[3, 1...]
  estimates restore ols*_`firststats'
  ereturn_post `b', se(`se') colnames(`colnames') store(reg_blind)

  * Working paper estimates.
  matrix `b' = `B'[4, 1...]
  matrix `se' = `SE'[4, 1...]
  estimates restore nber
  ereturn_post `b', se(`se') obs(`e(N)') colnames(`colnames') store(su_wp) local(jnlyr ✓ editor ✓ Nj ✓ qual ✓² native ✓ `jel' theory ✓)

  * Blind x female coefficient in working papers.
  matrix `b' = `B'[5, 1...]
  matrix `se' = `SE'[5, 1...]
  estimates restore nber
  ereturn_post `b', se(`se') colnames(`colnames') store(su_blind_wp)

  * Published paper estimates.
  matrix `b' = `B'[6, 1...]
  matrix `se' = `SE'[6, 1...]
  estimates restore reg
  ereturn_post `b', se(`se') obs(`e(N)') colnames(`colnames') store(su_pub) local(jnlyr ✓ editor ✓ Nj ✓ qual ✓² native ✓ `jel' theory ✓)

  * Blind x female coefficient in published papers.
  matrix `b' = `B'[7, 1...]
  matrix `se' = `SE'[7, 1...]
  estimates restore suest
  ereturn_post `b', se(`se') colnames(`colnames') store(su_blind_pub)

  * Difference.
  matrix `b' = `B'[8, 1...]
  matrix `se' = `SE'[8, 1...]
  estimates restore suest
  ereturn_post `b', se(`se') obs(`e(N)') colnames(`colnames') store(su_diff)

  * Blind x female difference.
  matrix `b' = `B'[9, 1...]
  matrix `se' = `SE'[9, 1...]
  estimates restore suest
  ereturn_post `b', se(`se') colnames(`colnames') store(su_blind_diff)
end

* ── Helper: write both individual tables for a given gender measure ──────────
* Outputs Table-5-llm-individual-1-{type}.tex (G1--G3) and
*           Table-5-llm-individual-2-{type}.tex (G4--G5 + Readability).
* Note: estout blist "\\${n}" produces only "\" in the tex output due to an
* estout/Stata escaping quirk. The group-header rows in the generated files
* therefore need a second "\" appended (making "\\") before compilation.
capture program drop nber_individual_table
program define nber_individual_table
  syntax , type(string) subtable(integer) [jel]

  if "`jel'"!="" {
    local jel_effects "\textit{JEL} effects"
  }

  if `subtable'==1 {
    estout reg_nber reg reg_blind fe fe_blind su_wp su_blind_wp su_pub su_blind_pub su_diff su_blind_diff ///
      using "~/tonal_analysis/outputs/tables/tex/Table-5-llm-individual-1-`type'.tex", ///
      style(publishing-female_latex) ///
      stats(N editor jnlyr Nj qual native theory `jel', ///
        labels("No. observations" "\midrule${n}Editor effects" "Journal\(\times\)Year effects" ///
          "\(N_j\)" "Quality controls" "Native speaker" "Theory/emp. effects" "`jel_effects'")) ///
      varlabels( ///
        _llm_modal_verb_score     "\quad Modal Verb Strength" ///
        _llm_hedging_score        "\quad Hedging Frequency \& Type" ///
        _llm_qualifier_score      "\quad Qualifier Density" ///
        _llm_ack_limits_score     "\quad Acknowledgement of Limitations" ///
        _llm_caution_score        "\quad Caution-Signaling Connectors" ///
        _llm_assertiveness_score  "\quad Assertiveness \& Voice" ///
        _llm_active_passive_score "\quad Active/Passive Voice Ratio" ///
        _llm_directness_score     "\quad Sentence Length \& Directness" ///
        , prefix("\mrow{4.5cm}{") suffix("}") ///
        blist( ///
          _llm_modal_verb_score    "\multicolumn{12}{l}{\textbf{G1: Creativity \& Hedging}}\\${n}" ///
          _llm_assertiveness_score "\midrule\multicolumn{12}{l}{\textbf{G2: Assertiveness \& Voice}}\\${n}" ///
          _llm_directness_score    "\midrule\multicolumn{12}{l}{\textbf{G3: Structural Directness}}\\${n}" ///
        ) ///
      ) ///
      prefoot("\midrule")
    create_latex using "`r(fn)'", tablename("table6llmind1") type("`type'")
  }
  else {
    estout reg_nber reg reg_blind fe fe_blind su_wp su_blind_wp su_pub su_blind_pub su_diff su_blind_diff ///
      using "~/tonal_analysis/outputs/tables/tex/Table-5-llm-individual-2-`type'.tex", ///
      style(publishing-female_latex) ///
      stats(N editor jnlyr Nj qual native theory `jel', ///
        labels("No. observations" "\midrule${n}Editor effects" "Journal\(\times\)Year effects" ///
          "\(N_j\)" "Quality controls" "Native speaker" "Theory/emp. effects" "`jel_effects'")) ///
      varlabels( ///
        _llm_pronoun_score     "\quad Pronoun Commitment" ///
        _llm_novelty_score     "\quad Novelty-Claim Strength" ///
        _llm_jargon_score      "\quad Jargon/Technicality Density\ensuremath{^\dagger}" ///
        _llm_emotional_score   "\quad Emotional Valence" ///
        _llm_evidence_score    "\quad Evidence \& Citation Usage" ///
        _llm_practical_score   "\quad Practical/Impact Orientation" ///
        _llm_readability_score "\quad Readability" ///
        , prefix("\mrow{4.5cm}{") suffix("}") ///
        blist( ///
          _llm_pronoun_score     "\multicolumn{12}{l}{\textbf{G4: Authorial Stance \& Novelty}}\\${n}" ///
          _llm_evidence_score    "\midrule\multicolumn{12}{l}{\textbf{G5: Support \& Impact}}\\${n}" ///
          _llm_readability_score "\midrule\multicolumn{12}{l}{\textbf{Standalone}}\\${n}" ///
        ) ///
      ) ///
      prefoot("\midrule")
    create_latex using "`r(fn)'", tablename("table6llmind2") type("`type'")
  }
end

local stats_g13 "llm_modal_verb llm_hedging llm_qualifier llm_ack_limits llm_caution llm_assertiveness llm_active_passive llm_directness"
local cols_g13  "_llm_modal_verb_score _llm_hedging_score _llm_qualifier_score _llm_ack_limits_score _llm_caution_score _llm_assertiveness_score _llm_active_passive_score _llm_directness_score"

local stats_g45 "llm_pronoun llm_novelty llm_jargon llm_emotional llm_evidence llm_practical llm_readability"
local cols_g45  "_llm_pronoun_score _llm_novelty_score _llm_jargon_score _llm_emotional_score _llm_evidence_score _llm_practical_score _llm_readability_score"

* ── Ratio of female authors ───────────────────────────────────────────────────
estimates clear
nber_fe   FemRatio using `nber_fe', stats(`stats_g13') colnames(`cols_g13')
nber_fgls FemRatio using `nber',    stats(`stats_g13') colnames(`cols_g13') firststats(llm_modal_verb)
nber_individual_table, type(FemRatio) subtable(1)

estimates clear
nber_fe   FemRatio using `nber_fe', stats(`stats_g45') colnames(`cols_g45')
nber_fgls FemRatio using `nber',    stats(`stats_g45') colnames(`cols_g45') firststats(llm_pronoun)
nber_individual_table, type(FemRatio) subtable(2)

* ── Exclusively female-authored ──────────────────────────────────────────────
estimates clear
nber_fe   Fem100 using `nber_fe', stats(`stats_g13') colnames(`cols_g13')
nber_fgls Fem100 using `nber',    stats(`stats_g13') colnames(`cols_g13') firststats(llm_modal_verb)
nber_individual_table, type(Fem100) subtable(1)

estimates clear
nber_fe   Fem100 using `nber_fe', stats(`stats_g45') colnames(`cols_g45')
nber_fgls Fem100 using `nber',    stats(`stats_g45') colnames(`cols_g45') firststats(llm_pronoun)
nber_individual_table, type(Fem100) subtable(2)

* ── Solo authored papers ─────────────────────────────────────────────────────
estimates clear
nber_fe   FemSolo using `nber_fe', stats(`stats_g13') colnames(`cols_g13')
nber_fgls FemSolo using `nber',    stats(`stats_g13') colnames(`cols_g13') firststats(llm_modal_verb)
nber_individual_table, type(FemSolo) subtable(1)

estimates clear
nber_fe   FemSolo using `nber_fe', stats(`stats_g45') colnames(`cols_g45')
nber_fgls FemSolo using `nber',    stats(`stats_g45') colnames(`cols_g45') firststats(llm_pronoun)
nber_individual_table, type(FemSolo) subtable(2)

* ── Senior female-authored ───────────────────────────────────────────────────
estimates clear
nber_fe   FemSenior using `nber_fe', stats(`stats_g13') colnames(`cols_g13')
nber_fgls FemSenior using `nber',    stats(`stats_g13') colnames(`cols_g13') firststats(llm_modal_verb)
nber_individual_table, type(FemSenior) subtable(1)

estimates clear
nber_fe   FemSenior using `nber_fe', stats(`stats_g45') colnames(`cols_g45')
nber_fgls FemSenior using `nber',    stats(`stats_g45') colnames(`cols_g45') firststats(llm_pronoun)
nber_individual_table, type(FemSenior) subtable(2)

* ── Junior authored papers (t<=3) ────────────────────────────────────────────
estimates clear
nber_fe   FemSenior if Maxt<=3 using `nber_fe', stats(`stats_g13') colnames(`cols_g13')
nber_fgls FemSenior if Maxt<=3 using `nber',    stats(`stats_g13') colnames(`cols_g13') firststats(llm_modal_verb)
nber_individual_table, type(FemJunior) subtable(1)

estimates clear
nber_fe   FemSenior if Maxt<=3 using `nber_fe', stats(`stats_g45') colnames(`cols_g45')
nber_fgls FemSenior if Maxt<=3 using `nber',    stats(`stats_g45') colnames(`cols_g45') firststats(llm_pronoun)
nber_individual_table, type(FemJunior) subtable(2)

* ── At least one female author ───────────────────────────────────────────────
estimates clear
nber_fe   Fem1 using `nber_fe', stats(`stats_g13') colnames(`cols_g13')
nber_fgls Fem1 using `nber',    stats(`stats_g13') colnames(`cols_g13') firststats(llm_modal_verb)
nber_individual_table, type(Fem1) subtable(1)

estimates clear
nber_fe   Fem1 using `nber_fe', stats(`stats_g45') colnames(`cols_g45')
nber_fgls Fem1 using `nber',    stats(`stats_g45') colnames(`cols_g45') firststats(llm_pronoun)
nber_individual_table, type(Fem1) subtable(2)

* ── At least 50 percent female-authored ──────────────────────────────────────
estimates clear
nber_fe   Fem50 using `nber_fe', stats(`stats_g13') colnames(`cols_g13')
nber_fgls Fem50 using `nber',    stats(`stats_g13') colnames(`cols_g13') firststats(llm_modal_verb)
nber_individual_table, type(Fem50) subtable(1)

estimates clear
nber_fe   Fem50 using `nber_fe', stats(`stats_g45') colnames(`cols_g45')
nber_fgls Fem50 using `nber',    stats(`stats_g45') colnames(`cols_g45') firststats(llm_pronoun)
nber_individual_table, type(Fem50) subtable(2)

* ── NBER abstract below the journal word limit ───────────────────────────────
estimates clear
nber_fe   FemRatio if BelowAbstractLen using `nber_fe', stats(`stats_g13') colnames(`cols_g13')
nber_fgls FemRatio if BelowAbstractLen using `nber',    stats(`stats_g13') colnames(`cols_g13') firststats(llm_modal_verb)
nber_individual_table, type(wordlimit) subtable(1)

estimates clear
nber_fe   FemRatio if BelowAbstractLen using `nber_fe', stats(`stats_g45') colnames(`cols_g45')
nber_fgls FemRatio if BelowAbstractLen using `nber',    stats(`stats_g45') colnames(`cols_g45') firststats(llm_pronoun)
nber_individual_table, type(wordlimit) subtable(2)

* ── Controlling for JEL codes ────────────────────────────────────────────────
estimates clear
nber_fe   FemRatio using `nber_fe_jel', stats(`stats_g13') colnames(`cols_g13') jel
nber_fgls FemRatio using `nber_jel',    stats(`stats_g13') colnames(`cols_g13') firststats(llm_modal_verb) jel
nber_individual_table, type(jel) subtable(1) jel

estimates clear
nber_fe   FemRatio using `nber_fe_jel', stats(`stats_g45') colnames(`cols_g45') jel
nber_fgls FemRatio using `nber_jel',    stats(`stats_g45') colnames(`cols_g45') firststats(llm_pronoun) jel
nber_individual_table, type(jel) subtable(2) jel

estimates clear
********************************************************************************
