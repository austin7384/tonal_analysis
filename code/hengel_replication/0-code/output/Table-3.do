********************************************************************************
****** Table 3: Gender differences in readability, article-level analysis ******
********************************************************************************
* Regress an article's gender on readability.
* Include different control sets in each regression.
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

  * Save list of JEL primary and tertiary codes. Variable list wildcards act like interaction terms in reghdfe.
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

    * (5) Journal, editor, year, journal-year interactions, institution, quality controls (max t, max T and IHS of citation count) and native English.
    reghdfe _`stat'_score `femblind' asinhCiteCount Maxt N, absorb(i.Journal##i.Year i.Editor i.MaxInst i.MaxT i.NativeEnglish) vce(cluster Editor)
    matrix `b5' = (nullmat(`b5'), _b[`femcoef'])
    matrix `se5' = (nullmat(`se5'), _se[`femcoef'])
    local obs5 = e(N_full)
    local dof5 = e(df_r)

    * (6) Journal, editor, year, journal-year interactions, institution, quality controls (max t, max T and IHS of citation count) and native English.
    * Sample restricted to articles with JEL codes.
    use `data_jel1', clear
    reghdfe _`stat'_score `femblind' asinhCiteCount Maxt N, absorb(i.Journal##i.Year i.Editor i.MaxInst i.MaxT i.NativeEnglish) vce(cluster Editor)
    matrix `b6' = (nullmat(`b6'), _b[`femcoef'])
    matrix `se6' = (nullmat(`se6'), _se[`femcoef'])
    local obs6 = e(N_full)
    local dof6 = e(df_r)

    * (7) Journal, editor, year, journal-year interactions, institution, quality controls (max t, max T and IHS of citation count), native English and primary JEL codes.
    reghdfe _`stat'_score `femblind' asinhCiteCount Maxt N, absorb(i.Journal##i.Year i.Editor i.MaxInst i.MaxT i.NativeEnglish `jcode1') vce(cluster Editor)
    matrix `b7' = (nullmat(`b7'), _b[`femcoef'])
    matrix `se7' = (nullmat(`se7'), _se[`femcoef'])
    local obs7 = e(N_full)
    local dof7 = e(df_r)

    * (8) Journal, editor, year, journal-year interactions, institution, quality controls (max t, max T and IHS of citation count), native English and theory/empirical.
    reghdfe _`stat'_score `femblind' asinhCiteCount Maxt N, absorb(i.Journal##i.Year i.Editor i.MaxInst i.MaxT i.NativeEnglish Type_*) vce(cluster Editor)
    matrix `b8' = (nullmat(`b8'), _b[`femcoef'])
    matrix `se8' = (nullmat(`se8'), _se[`femcoef'])
    local obs8 = e(N_full)
    local dof8 = e(df_r)

    * (9) Journal, editor, year, journal-year interactions, institution, quality controls (max t, max T and IHS of citation count), native English and tertiary JEL codes.
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

capture program drop article_level_table
program define article_level_table
  syntax , type(string)

  estout est_*_Editor using "~/tonal_analysis/outputs/tables/tex/Table-3-`type'.tex", style(publishing-female_latex) ///
    stats(N editor blind journal year jnlyr Nj inst qual native jel theory jel3, labels("No. obs." "\midrule${n}Editor" "Blind" "Journal" ///
      "Year" "Journal#Year" "\(N_j\)" "Institution" "Quality" "Native speaker" ///
      "\textit{JEL} (primary)" "Theory/empirical" "\textit{JEL} (tertiary)")) ///
    varlabels(, prefix("\mrow{3cm}{") suffix("}")) ///
    prefoot("\midrule")
  create_latex using "`r(fn)'", tablename("table3") type("`type'")
end

* Female ratio.
article_level FemRatio using `article', stats(flesch fleschkincaid gunningfog smog dalechall) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
article_level_table, type(FemRatio)

* Exclusively female-authored.
article_level Fem100 using `article', stats(flesch fleschkincaid gunningfog smog dalechall) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
article_level_table, type(Fem100)

* Solo-authored.
article_level FemSolo using `article', stats(flesch fleschkincaid gunningfog smog dalechall) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
article_level_table, type(FemSolo)

* At least one female author.
article_level Fem1 using `article', stats(flesch fleschkincaid gunningfog smog dalechall) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
article_level_table, type(Fem1)

* Majority female-authord.
article_level Fem50 using `article', stats(flesch fleschkincaid gunningfog smog dalechall) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
article_level_table, type(Fem50)

* Senior female author.
article_level FemSenior using `article', stats(flesch fleschkincaid gunningfog smog dalechall) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
article_level_table, type(FemSenior)

* Junior authors.
article_level FemJunior using `article', stats(flesch fleschkincaid gunningfog smog dalechall) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
article_level_table, type(FemJunior)

* Alternative program for calculating readability statistics.
article_level FemRatio using `article', stats(r_fleschkincaid r_gunningfog r_smog) data_jel1(`article_primary_jel') data_jel3(`article_tertiary_jel_pp') colnames(_fleschkincaid_score _gunningfog_score _smog_score)
article_level_table, type(R)
********************************************************************************
