********************************************************************************
*** Table 8 LLM Individual: all 16 criteria, split into two tables per type ***
********************************************************************************
* tth_pub is redefined here so this file can run standalone (Table-8.do
* may be commented out in hengel_master.do).
capture program drop tth_pub
program define tth_pub, eclass
  syntax namelist using/, stats(string) colnames(string)

  estimates clear
  use `using', clear

  if "`namelist'"=="FemRatio" | "`namelist'"=="FemSenior" {
    local male c.`namelist'#0.Female
    local femblind c.`namelist'#1.Blind
  }
  else {
    local male i.`namelist'#0.Female
    local femblind i.`namelist'#1.Blind
  }

  tempname B S P
  foreach stat in `stats' {
    * Truncate stat name so _est_<sname>_<namelist>_<i> stays within 32 chars.
    local sname = substr("`stat'", 1, `=24-length("`namelist'")')
    local i = 1
    foreach tif in t==1 t==2 t==3 t==4|t==5 t>5 {
      * Restrict columns for solo-authored papers.
      if "`namelist'"=="FemSolo" {
        if "`tif'"=="t==3" {
          local tif "t==3|t==4|t==5"
        }
        else if "`tif'"=="t==4|t==5" {
          continue
        }
      }

      * No MaxT: small sample sizes.
      eststo `sname'_`namelist'_`i': regress _`stat'_score `namelist' `male' `femblind' Maxt N asinhCiteCount i.Editor i.Journal#i.Year i.MaxInst i.NativeEnglish if `tif' [aweight=AuthorWeight]
      local n`i++' = e(N)
    }
    eststo `sname'_`namelist': suest2 `sname'_`namelist'_*, cluster(AuthorID Editor)

    tempname b se
    forvalues j=1/`=`i'-1' {
      matrix `b' = nullmat(`b') \ _b[`sname'_`namelist'_`j'_mean:`namelist']
      matrix `se' = nullmat(`se') \ _se[`sname'_`namelist'_`j'_mean:`namelist']
    }

    * All observations together.
    if "`namelist'"=="FemSolo" {
      reghdfe _`stat'_score FemSolo i.FemSolo#1.Blind Maxt asinhCiteCount i.NativeEnglish, absorb(i.Editor i.Journal#i.Year i.MaxInst i.MaxT) vce(cluster AuthorID)
      local n6 = e(N_full)
    }
    else {
      xtreg _`stat'_score `namelist' `male' `femblind' Maxt N i.Editor i.Journal#i.Year i.MaxInst asinhCiteCount i.MaxT i.NativeEnglish, pa corr(ar 1) vce(robust)
      local n6 = e(N)
    }

    matrix `B' = nullmat(`B'), (`b' \ _b[`namelist'])
    matrix `S' = nullmat(`S'), (`se' \ _se[`namelist'])
  }

  tempname b se
  forvalues i=1/`=rowsof(`B')-1' {
    matrix `b' = `B'[`i', 1...]
    matrix `se' = `S'[`i', 1...]
    ereturn_post `b', se(`se') obs(`e(N)') scalar(obs `n`i'') local(Nj ✓ editor ✓ blind ✓ jnlyr ✓ inst ✓ qual ✓³ native ✓) store(reg_`i') colnames(`colnames')
  }
  matrix `b' = `B'[`=rowsof(`B')', 1...]
  matrix `se' = `S'[`=rowsof(`B')', 1...]
  ereturn_post `b', se(`se') obs(`e(N)') scalar(obs `n6') local(Nj ✓ editor ✓ blind ✓ jnlyr ✓ inst ✓ qual ✓¹ native ✓) store(reg_all) colnames(`colnames')
end

capture program drop tth_pub_llm_ind_table
program define tth_pub_llm_ind_table
  syntax, type(string) subtable(integer)

  * FemSolo has one fewer t-bin column (5 estimates vs 6).
  if "`type'"=="FemSolo" {
    local mc 6
  }
  else {
    local mc 7
  }

  if `subtable'==1 {
    estout reg_* using "~/tonal_analysis/outputs/tables/tex/Table-8-llm-individual-1-`type'.tex", style(publishing-female_latex) ///
      stats(obs editor blind jnlyr Nj inst qual native, labels("No. observations" "\midrule${n}Editor effects" ///
        "Blind review" "Journal\(\times\)Year effects" "\(N_j\)" "Institution effects" "Quality controls" "Native speaker")) ///
      varlabels( ///
        _llm_modal_verb_score     "\quad Modal Verb Strength" ///
        _llm_hedging_score        "\quad Hedging Frequency \& Type" ///
        _llm_qualifier_score      "\quad Qualifier Density" ///
        _llm_ack_limits_score     "\quad Acknowledgement of Limitations" ///
        _llm_caution_score        "\quad Caution-Signaling Connectors" ///
        _llm_assertiveness_score  "\quad Assertiveness \& Voice" ///
        _llm_active_passive_score "\quad Active/Passive Voice Ratio" ///
        _llm_directness_score     "\quad Sentence Length \& Directness" ///
        _llm_imperative_score     "\quad Imperative-Form Occurrence" ///
        , prefix("\mrow{3cm}{") suffix("}") ///
        blist( ///
          _llm_modal_verb_score    "\multicolumn{`mc'}{l}{\textbf{G1: Creativity \& Hedging}}\\${n}" ///
          _llm_assertiveness_score "\midrule\multicolumn{`mc'}{l}{\textbf{G2: Assertiveness \& Voice}}\\${n}" ///
          _llm_directness_score    "\midrule\multicolumn{`mc'}{l}{\textbf{G3: Structural Directness}}\\${n}" ///
        ) ///
      ) ///
      prefoot("\midrule")
    create_latex using "`r(fn)'", tablename("tableH2llmind1") type("`type'")
  }
  else {
    estout reg_* using "~/tonal_analysis/outputs/tables/tex/Table-8-llm-individual-2-`type'.tex", style(publishing-female_latex) ///
      stats(obs editor blind jnlyr Nj inst qual native, labels("No. observations" "\midrule${n}Editor effects" ///
        "Blind review" "Journal\(\times\)Year effects" "\(N_j\)" "Institution effects" "Quality controls" "Native speaker")) ///
      varlabels( ///
        _llm_pronoun_score     "\quad Pronoun Commitment" ///
        _llm_novelty_score     "\quad Novelty-Claim Strength" ///
        _llm_jargon_score      "\quad Jargon/Technicality Density\ensuremath{^\dagger}" ///
        _llm_emotional_score   "\quad Emotional Valence" ///
        _llm_evidence_score    "\quad Evidence \& Citation Usage" ///
        _llm_practical_score   "\quad Practical/Impact Orientation" ///
        _llm_readability_score "\quad Readability" ///
        , prefix("\mrow{3cm}{") suffix("}") ///
        blist( ///
          _llm_pronoun_score     "\multicolumn{`mc'}{l}{\textbf{G4: Authorial Stance \& Novelty}}\\${n}" ///
          _llm_evidence_score    "\midrule\multicolumn{`mc'}{l}{\textbf{G5: Support \& Impact}}\\${n}" ///
          _llm_readability_score "\midrule\multicolumn{`mc'}{l}{\textbf{Standalone}}\\${n}" ///
        ) ///
      ) ///
      prefoot("\midrule")
    create_latex using "`r(fn)'", tablename("tableH2llmind2") type("`type'")
  }
end

local stats_g13 "llm_modal_verb llm_hedging llm_qualifier llm_ack_limits llm_caution llm_assertiveness llm_active_passive llm_directness llm_imperative"
local cols_g13  "_llm_modal_verb_score _llm_hedging_score _llm_qualifier_score _llm_ack_limits_score _llm_caution_score _llm_assertiveness_score _llm_active_passive_score _llm_directness_score _llm_imperative_score"

local stats_g45 "llm_pronoun llm_novelty llm_jargon llm_emotional llm_evidence llm_practical llm_readability"
local cols_g45  "_llm_pronoun_score _llm_novelty_score _llm_jargon_score _llm_emotional_score _llm_evidence_score _llm_practical_score _llm_readability_score"

* ── Female ratio ───────────────────────────────────────────────────────────────
tth_pub FemRatio using `author', stats(`stats_g13') colnames(`cols_g13')
tth_pub_llm_ind_table, type(FemRatio) subtable(1)
tth_pub FemRatio using `author', stats(`stats_g45') colnames(`cols_g45')
tth_pub_llm_ind_table, type(FemRatio) subtable(2)

* ── Solo-authored ──────────────────────────────────────────────────────────────
tth_pub FemSolo using `author', stats(`stats_g13') colnames(`cols_g13')
tth_pub_llm_ind_table, type(FemSolo) subtable(1)
tth_pub FemSolo using `author', stats(`stats_g45') colnames(`cols_g45')
tth_pub_llm_ind_table, type(FemSolo) subtable(2)

* ── Exclusively female-authored ────────────────────────────────────────────────
tth_pub Fem100 using `author', stats(`stats_g13') colnames(`cols_g13')
tth_pub_llm_ind_table, type(Fem100) subtable(1)
tth_pub Fem100 using `author', stats(`stats_g45') colnames(`cols_g45')
tth_pub_llm_ind_table, type(Fem100) subtable(2)

* ── At least one female author ─────────────────────────────────────────────────
tth_pub Female using `author', stats(`stats_g13') colnames(`cols_g13')
tth_pub_llm_ind_table, type(Fem1) subtable(1)
tth_pub Female using `author', stats(`stats_g45') colnames(`cols_g45')
tth_pub_llm_ind_table, type(Fem1) subtable(2)

* ── Majority female-authored ───────────────────────────────────────────────────
tth_pub Fem50 using `author', stats(`stats_g13') colnames(`cols_g13')
tth_pub_llm_ind_table, type(Fem50) subtable(1)
tth_pub Fem50 using `author', stats(`stats_g45') colnames(`cols_g45')
tth_pub_llm_ind_table, type(Fem50) subtable(2)

* ── Senior female author ───────────────────────────────────────────────────────
tth_pub FemSenior using `author', stats(`stats_g13') colnames(`cols_g13')
tth_pub_llm_ind_table, type(FemSenior) subtable(1)
tth_pub FemSenior using `author', stats(`stats_g45') colnames(`cols_g45')
tth_pub_llm_ind_table, type(FemSenior) subtable(2)
********************************************************************************
