********************************************************************************
*** Table 3 LLM Individual: all 16 criteria, split into two sidewaystables ***
********************************************************************************
* article_level is defined here so this file can run standalone (Table-3.do
* may be commented out in hengel_master.do).
capture program drop article_level
program define article_level, eclass
  syntax varname using/, stats(string) data_jel1(string) data_jel3(string) colnames(string)

  estimates clear
  * Differentiate continuous from discontinuous measures of article gender.
  if "`varlist'"=="FemRatio" | "`varlist'"=="FemSenior" | "`varlist'"=="FemJunior" {
    local femcoef `varlist'
    local femblind c.`varlist'##i.Blind
  }
  else {
    local femcoef 1.`varlist'
    local femblind i.`varlist'##i.Blind
  }

  * Save list of JEL primary and tertiary codes.
  use `data_jel1', clear
  local jcode1
  foreach jel of varlist JEL1_* {
    local jcode1 "`jcode1' `jel'"
  }
  use `data_jel3', clear
  local jcode3
  foreach jel of varlist JEL3_* {
    local jcode3 "`jcode3' `jel'"
  }

  tempname b1 b2 b3 b4 b5 b6 b7 b8 b9 se1 se2 se3 se4 se5 se6 se7 se8 se9
  foreach stat in `stats' {

    * (1) Journal and editor.
    use `using', clear
    reghdfe _`stat'_score `femblind', absorb(i.Journal i.Editor) vce(cluster Editor)
    matrix `b1' = (nullmat(`b1'), _b[`femcoef'])
    matrix `se1' = (nullmat(`se1'), _se[`femcoef'])
    local obs1 = e(N_full)
    local dof1 = e(df_r)

    * (2) Journal, editor and year.
    reghdfe _`stat'_score `femblind', absorb(i.Journal i.Editor i.Year) vce(cluster Editor)
    matrix `b2' = (nullmat(`b2'), _b[`femcoef'])
    matrix `se2' = (nullmat(`se2'), _se[`femcoef'])
    local obs2 = e(N_full)
    local dof2 = e(df_r)

    * (3) Journal, editor, year and journal-year interaction.
    reghdfe _`stat'_score `femblind', absorb(i.Journal##i.Year i.Editor) vce(cluster Editor)
    matrix `b3' = (nullmat(`b3'), _b[`femcoef'])
    matrix `se3' = (nullmat(`se3'), _se[`femcoef'])
    local obs3 = e(N_full)
    local dof3 = e(df_r)

    * (4) Journal, editor, year, journal-year interaction, institution.
    reghdfe _`stat'_score `femblind' N, absorb(i.Journal##i.Year i.Editor i.MaxInst) vce(cluster Editor)
    matrix `b4' = (nullmat(`b4'), _b[`femcoef'])
    matrix `se4' = (nullmat(`se4'), _se[`femcoef'])
    local obs4 = e(N_full)
    local dof4 = e(df_r)

    * (5) Journal, editor, year, journal-year interactions, institution, quality controls and native English.
    reghdfe _`stat'_score `femblind' asinhCiteCount Maxt N, absorb(i.Journal##i.Year i.Editor i.MaxInst i.MaxT i.NativeEnglish) vce(cluster Editor)
    matrix `b5' = (nullmat(`b5'), _b[`femcoef'])
    matrix `se5' = (nullmat(`se5'), _se[`femcoef'])
    local obs5 = e(N_full)
    local dof5 = e(df_r)

    * (6) Same as (5), sample restricted to articles with JEL codes.
    use `data_jel1', clear
    reghdfe _`stat'_score `femblind' asinhCiteCount Maxt N, absorb(i.Journal##i.Year i.Editor i.MaxInst i.MaxT i.NativeEnglish) vce(cluster Editor)
    matrix `b6' = (nullmat(`b6'), _b[`femcoef'])
    matrix `se6' = (nullmat(`se6'), _se[`femcoef'])
    local obs6 = e(N_full)
    local dof6 = e(df_r)

    * (7) Add primary JEL codes.
    reghdfe _`stat'_score `femblind' asinhCiteCount Maxt N, absorb(i.Journal##i.Year i.Editor i.MaxInst i.MaxT i.NativeEnglish `jcode1') vce(cluster Editor)
    matrix `b7' = (nullmat(`b7'), _b[`femcoef'])
    matrix `se7' = (nullmat(`se7'), _se[`femcoef'])
    local obs7 = e(N_full)
    local dof7 = e(df_r)

    * (8) Add theory/empirical.
    reghdfe _`stat'_score `femblind' asinhCiteCount Maxt N, absorb(i.Journal##i.Year i.Editor i.MaxInst i.MaxT i.NativeEnglish Type_*) vce(cluster Editor)
    matrix `b8' = (nullmat(`b8'), _b[`femcoef'])
    matrix `se8' = (nullmat(`se8'), _se[`femcoef'])
    local obs8 = e(N_full)
    local dof8 = e(df_r)

    * (9) Add tertiary JEL codes.
    use `data_jel3', clear
    reghdfe _`stat'_score `femblind' asinhCiteCount Maxt N, absorb(i.Journal##i.Year Editor MaxInst MaxT NativeEnglish `jcode3') vce(cluster Editor)
    matrix `b9' = (nullmat(`b9'), _b[`femcoef'])
    matrix `se9' = (nullmat(`se9'), _se[`femcoef'])
    local obs9 = e(N_full)
    local dof9 = e(df_r)
  }

  * Store estimates.
  ereturn_post `b1', se(`se1') obs(`obs1') dof(`dof1') store(est_1_Editor) colnames(`colnames') local(editor ✓ blind ✓ journal ✓)
  ereturn_post `b2', se(`se2') obs(`obs2') dof(`dof2') store(est_2_Editor) colnames(`colnames') local(editor ✓ blind ✓ journal ✓ year ✓)
  ereturn_post `b3', se(`se3') obs(`obs3') dof(`dof3') store(est_3_Editor) colnames(`colnames') local(editor ✓ blind ✓ jnlyr ✓)
  ereturn_post `b4', se(`se4') obs(`obs4') dof(`dof4') store(est_4_Editor) colnames(`colnames') local(editor ✓ blind ✓ jnlyr ✓ Nj ✓ inst ✓)
  ereturn_post `b5', se(`se5') obs(`obs5') dof(`dof5') store(est_5_Editor) colnames(`colnames') local(editor ✓ blind ✓ jnlyr ✓ Nj ✓ inst ✓ qual ✓¹ native ✓)
  ereturn_post `b6', se(`se6') obs(`obs6') dof(`dof6') store(est_6_Editor) colnames(`colnames') local(editor ✓ blind ✓ jnlyr ✓ Nj ✓ inst ✓ qual ✓¹ native ✓)
  ereturn_post `b7', se(`se7') obs(`obs7') dof(`dof7') store(est_7_Editor) colnames(`colnames') local(editor ✓ blind ✓ jnlyr ✓ Nj ✓ inst ✓ qual ✓¹ native ✓ jel ✓)
  ereturn_post `b8', se(`se8') obs(`obs8') dof(`dof8') store(est_8_Editor) colnames(`colnames') local(editor ✓ blind ✓ jnlyr ✓ Nj ✓ inst ✓ qual ✓¹ native ✓ theory ✓)
  ereturn_post `b9', se(`se9') obs(`obs9') dof(`dof9') store(est_9_Editor) colnames(`colnames') local(editor ✓ blind ✓ jnlyr ✓ Nj ✓ inst ✓ qual ✓¹ native ✓ jel3 ✓)
end

* ── Helper: write both individual tables for a given gender measure ──────────
* Outputs Table-3-llm-individual-1-{type}.tex (G1--G3) and
*           Table-3-llm-individual-2-{type}.tex (G4--G5 + Readability).
* Note: estout blist "\\${n}" produces only "\" in the tex output due to an
* estout/Stata escaping quirk. The group-header rows in the generated files
* therefore need a second "\" appended (making "\\") before compilation.
capture program drop article_level_individual_table
program define article_level_individual_table
  syntax varname using/, type(string) data_jel1(string) data_jel3(string)

  * Table 1: G1 + G2 + G3 (9 criteria).
  article_level `varlist' using `"`using'"', ///
    stats(llm_modal_verb llm_hedging llm_qualifier llm_ack_limits llm_caution ///
          llm_assertiveness llm_active_passive ///
          llm_directness llm_imperative) ///
    data_jel1(`"`data_jel1'"') data_jel3(`"`data_jel3'"') ///
    colnames(_llm_modal_verb_score _llm_hedging_score _llm_qualifier_score ///
             _llm_ack_limits_score _llm_caution_score ///
             _llm_assertiveness_score _llm_active_passive_score ///
             _llm_directness_score _llm_imperative_score)
  estout est_*_Editor ///
    using "~/tonal_analysis/outputs/tables/tex/Table-3-llm-individual-1-`type'.tex", ///
    style(publishing-female_latex) ///
    stats(N editor blind journal year jnlyr Nj inst qual native jel theory jel3, ///
      labels("No. obs." "\midrule${n}Editor" "Blind" "Journal" ///
        "Year" "Journal#Year" "\(N_j\)" "Institution" "Quality" "Native speaker" ///
        "\textit{JEL} (primary)" "Theory/empirical" "\textit{JEL} (tertiary)")) ///
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
      , prefix("\mrow{4.5cm}{") suffix("}") ///
      blist( ///
        _llm_modal_verb_score    "\multicolumn{10}{l}{\textbf{G1: Creativity \& Hedging}}\\${n}" ///
        _llm_assertiveness_score "\midrule\multicolumn{10}{l}{\textbf{G2: Assertiveness \& Voice}}\\${n}" ///
        _llm_directness_score    "\midrule\multicolumn{10}{l}{\textbf{G3: Structural Directness}}\\${n}" ///
      ) ///
    ) ///
    prefoot("\midrule")
  create_latex using "`r(fn)'", tablename("table3llmind1") type("`type'")

  * Table 2: G4 + G5 + Standalone Readability (7 criteria).
  * \ensuremath{^\dagger} avoids the $->\$ substitution bug for the jargon label.
  article_level `varlist' using `"`using'"', ///
    stats(llm_pronoun llm_novelty llm_jargon llm_emotional ///
          llm_evidence llm_practical ///
          llm_readability) ///
    data_jel1(`"`data_jel1'"') data_jel3(`"`data_jel3'"') ///
    colnames(_llm_pronoun_score _llm_novelty_score _llm_jargon_score ///
             _llm_emotional_score ///
             _llm_evidence_score _llm_practical_score ///
             _llm_readability_score)
  estout est_*_Editor ///
    using "~/tonal_analysis/outputs/tables/tex/Table-3-llm-individual-2-`type'.tex", ///
    style(publishing-female_latex) ///
    stats(N editor blind journal year jnlyr Nj inst qual native jel theory jel3, ///
      labels("No. obs." "\midrule${n}Editor" "Blind" "Journal" ///
        "Year" "Journal#Year" "\(N_j\)" "Institution" "Quality" "Native speaker" ///
        "\textit{JEL} (primary)" "Theory/empirical" "\textit{JEL} (tertiary)")) ///
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
        _llm_pronoun_score     "\multicolumn{10}{l}{\textbf{G4: Authorial Stance \& Novelty}}\\${n}" ///
        _llm_evidence_score    "\midrule\multicolumn{10}{l}{\textbf{G5: Support \& Impact}}\\${n}" ///
        _llm_readability_score "\midrule\multicolumn{10}{l}{\textbf{Standalone}}\\${n}" ///
      ) ///
    ) ///
    prefoot("\midrule")
  create_latex using "`r(fn)'", tablename("table3llmind2") type("`type'")
end

* ── FemRatio (original filenames preserved for existing references) ───────────
article_level FemRatio using `article', ///
  stats(llm_modal_verb llm_hedging llm_qualifier llm_ack_limits llm_caution ///
        llm_assertiveness llm_active_passive ///
        llm_directness llm_imperative) ///
  data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') ///
  colnames(_llm_modal_verb_score _llm_hedging_score _llm_qualifier_score ///
           _llm_ack_limits_score _llm_caution_score ///
           _llm_assertiveness_score _llm_active_passive_score ///
           _llm_directness_score _llm_imperative_score)

estout est_*_Editor using "~/tonal_analysis/outputs/tables/tex/Table-3-llm-individual-1.tex", ///
  style(publishing-female_latex) ///
  stats(N editor blind journal year jnlyr Nj inst qual native jel theory jel3, ///
    labels("No. obs." "\midrule${n}Editor" "Blind" "Journal" ///
      "Year" "Journal#Year" "\(N_j\)" "Institution" "Quality" "Native speaker" ///
      "\textit{JEL} (primary)" "Theory/empirical" "\textit{JEL} (tertiary)")) ///
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
    , prefix("\mrow{4.5cm}{") suffix("}") ///
    blist( ///
      _llm_modal_verb_score     "\multicolumn{10}{l}{\textbf{G1: Creativity \& Hedging}}\\${n}" ///
      _llm_assertiveness_score  "\midrule\multicolumn{10}{l}{\textbf{G2: Assertiveness \& Voice}}\\${n}" ///
      _llm_directness_score     "\midrule\multicolumn{10}{l}{\textbf{G3: Structural Directness}}\\${n}" ///
    ) ///
  ) ///
  prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table3llmind1")

article_level FemRatio using `article', ///
  stats(llm_pronoun llm_novelty llm_jargon llm_emotional ///
        llm_evidence llm_practical ///
        llm_readability) ///
  data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') ///
  colnames(_llm_pronoun_score _llm_novelty_score _llm_jargon_score ///
           _llm_emotional_score ///
           _llm_evidence_score _llm_practical_score ///
           _llm_readability_score)

estout est_*_Editor using "~/tonal_analysis/outputs/tables/tex/Table-3-llm-individual-2.tex", ///
  style(publishing-female_latex) ///
  stats(N editor blind journal year jnlyr Nj inst qual native jel theory jel3, ///
    labels("No. obs." "\midrule${n}Editor" "Blind" "Journal" ///
      "Year" "Journal#Year" "\(N_j\)" "Institution" "Quality" "Native speaker" ///
      "\textit{JEL} (primary)" "Theory/empirical" "\textit{JEL} (tertiary)")) ///
  varlabels( ///
    _llm_pronoun_score     "\quad Pronoun Commitment" ///
    _llm_novelty_score     "\quad Novelty-Claim Strength" ///
    _llm_jargon_score      "\quad Jargon/Technicality Density$^\dagger$" ///
    _llm_emotional_score   "\quad Emotional Valence" ///
    _llm_evidence_score    "\quad Evidence \& Citation Usage" ///
    _llm_practical_score   "\quad Practical/Impact Orientation" ///
    _llm_readability_score "\quad Readability" ///
    , prefix("\mrow{4.5cm}{") suffix("}") ///
    blist( ///
      _llm_pronoun_score     "\multicolumn{10}{l}{\textbf{G4: Authorial Stance \& Novelty}}\\${n}" ///
      _llm_evidence_score    "\midrule\multicolumn{10}{l}{\textbf{G5: Support \& Impact}}\\${n}" ///
      _llm_readability_score "\midrule\multicolumn{10}{l}{\textbf{Standalone}}\\${n}" ///
    ) ///
  ) ///
  prefoot("\midrule")
create_latex using "`r(fn)'", tablename("table3llmind2")

* ── Variant gender measures ──────────────────────────────────────────────────
* Exclusively female-authored.
article_level_individual_table Fem100 using `article', ///
  type(Fem100) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp')

* Solo female-authored.
article_level_individual_table FemSolo using `article', ///
  type(FemSolo) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp')

* At least one female author.
article_level_individual_table Fem1 using `article', ///
  type(Fem1) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp')

* Majority female-authored.
article_level_individual_table Fem50 using `article', ///
  type(Fem50) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp')

* Senior female author.
article_level_individual_table FemSenior using `article', ///
  type(FemSenior) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp')

* Junior female authors (t<=3).
article_level_individual_table FemJunior using `article', ///
  type(FemJunior) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp')

estimates clear
********************************************************************************
