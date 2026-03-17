********************************************************************************
************ Table 8 LLM: Gender gap in LLM scores at increasing t *************
********************************************************************************
capture program drop tth_pub_llm_table
program define tth_pub_llm_table
  syntax , type(string)

  estout reg_* using "~/tonal_analysis/outputs/tables/tex/Table-8-llm-`type'.tex", style(publishing-female_latex) ///
    stats(obs editor blind jnlyr Nj inst qual native, labels("No. observations" "\midrule${n}Editor effects" ///
      "Blind review" "Journal#Year effects" "\(N_j\)" "Institution effects" "Quality controls" "Native speaker")) ///
    varlabels(_llm_g1_score "LLM G1: Creativity \& Hedging" ///
              _llm_g2_score "LLM G2: Assertiveness \& Voice" ///
              _llm_g3_score "LLM G3: Structural Directness" ///
              _llm_g4_score "LLM G4: Authorial Stance \& Novelty" ///
              _llm_g5_score "LLM G5: Support \& Impact") ///
    prefoot("\midrule")
  create_latex using "`r(fn)'", tablename("tableH2llm") type("`type'")
end

* Female ratio.
tth_pub FemRatio using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
tth_pub_llm_table, type(FemRatio)

* Solo-authored.
tth_pub FemSolo using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
tth_pub_llm_table, type(FemSolo)

* Exclusively female-authored.
tth_pub Fem100 using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
tth_pub_llm_table, type(Fem100)

* At least one female author.
tth_pub Female using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
tth_pub_llm_table, type(Fem1)

* Majority female-authored.
tth_pub Fem50 using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
tth_pub_llm_table, type(Fem50)

* Senior female author.
tth_pub FemSenior using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
tth_pub_llm_table, type(FemSenior)
********************************************************************************
