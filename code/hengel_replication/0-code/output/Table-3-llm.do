********************************************************************************
** Table 3 LLM: Gender differences in LLM tonal composites, article-level *****
********************************************************************************
* Redefine only the table output program; article_level is reused as-is.
capture program drop article_level_table
program define article_level_table
  syntax , type(string)

  estout est_*_Editor using "~/tonal_analysis/outputs/tables/tex/Table-3-llm-`type'.tex", style(publishing-female_latex) ///
    stats(N editor blind journal year jnlyr Nj inst qual native jel theory jel3, labels("No. obs." "\midrule${n}Editor" "Blind" "Journal" ///
      "Year" "Journal#Year" "\(N_j\)" "Institution" "Quality" "Native speaker" ///
      "\textit{JEL} (primary)" "Theory/empirical" "\textit{JEL} (tertiary)")) ///
    varlabels(, prefix("\mrow{3cm}{") suffix("}")) ///
    prefoot("\midrule")
  create_latex using "`r(fn)'", tablename("table3llm") type("`type'")
end

* Female ratio.
article_level FemRatio using `article', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
article_level_table, type(FemRatio)

* Exclusively female-authored.
article_level Fem100 using `article', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
article_level_table, type(Fem100)

* Solo-authored.
article_level FemSolo using `article', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
article_level_table, type(FemSolo)

* At least one female author.
article_level Fem1 using `article', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
article_level_table, type(Fem1)

* Majority female-authored.
article_level Fem50 using `article', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
article_level_table, type(Fem50)

* Senior female author.
article_level FemSenior using `article', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
article_level_table, type(FemSenior)

* Junior authors.
article_level FemJunior using `article', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score)
article_level_table, type(FemJunior)
********************************************************************************
