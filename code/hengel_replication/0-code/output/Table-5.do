********************************************************************************
******* Table 5: The impact of peer review on the gender readability gap *******
********************************************************************************
* Program to generate OLS and FGLS estimates.
capture program drop nber_fgls
program define nber_fgls, eclass
  syntax varname [if] [using/], stats(string) colnames(string) [jel]

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

    * Rename NBER readability score variable to nber_score so it's constant across scores (easier to generate Table L.1).
    rename nber_`stat'_score nber_score

    * Estimate OLS (first column).
    eststo ols_`stat': reghdfe _`stat'_score nber_score `female'##i.Blind N Maxt MaxT asinhCiteCount i.NativeEnglish Type_* `if', absorb(i.Year##i.Journal i.Editor `jcode1') vce(cluster Editor)
    local b_fem = _b[`female']
    local se_fem = _se[`female']

    local bblind_fem = _b[1.Blind#`female']
    local seblind_fem = _se[1.Blind#`female']

    local nber_b = _b[nber_score]
    local nber_se = _se[nber_score]

    * Rename NBER readability score its original name.
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

  * OLS estimates controlling for draft readability estimates.
  matrix `b' = `B'[1, 1...]
  matrix `se' = `SE'[1, 1...]
  estimates restore ols*_fleschkincaid
  ereturn_post `b', se(`se') colnames(`colnames') store(reg_nber)

  matrix `b' = `B'[2, 1...]
  matrix `se' = `SE'[2, 1...]
  estimates restore ols*_fleschkincaid
  ereturn_post `b', se(`se') obs(`=e(N_full)') colnames(`colnames') store(reg) local(jnlyr ✓ editor ✓ Nj ✓ qual ✓² native ✓ `jel' theory ✓)

  * Blind x female coefficient.
  matrix `b' = `B'[3, 1...]
  matrix `se' = `SE'[3, 1...]
  estimates restore ols*_fleschkincaid
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

* Program to generate change in score estimates.
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

capture program drop nber_table
program define nber_table
  syntax , type(string) [jel]

  if "`jel'"!="" {
    local jel_effects "\textit{JEL} effects"
  }
  estout reg_nber reg reg_blind fe fe_blind su_wp su_blind_wp su_pub su_blind_pub su_diff su_blind_diff using "~/tonal_analysis/outputs/tables/tex/Table-5-`type'.tex", style(publishing-female_latex) ///
    stats(N editor jnlyr Nj qual native theory `jel', labels("No. observations" "\midrule${n}Editor effects" "Journal#Year effects" ///
      "\(N_j\)" "Quality controls" "Native speaker" "Theory/emp. effects" "`jel_effects'")) ///
    prefoot("\midrule")
  create_latex using "`r(fn)'", tablename("table6") type("`type'")
end

* Ratio of female authors.
estimates clear
nber_fe FemRatio using `nber_fe', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_fgls FemRatio using `nber', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_table, type(FemRatio)

* Exclusively female-authored.
estimates clear
nber_fe Fem100 using `nber_fe', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_fgls Fem100 using `nber', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_table, type(Fem100)

* Solo authored papers.
estimates clear
nber_fe FemSolo using `nber_fe', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_fgls FemSolo using `nber', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_table, type(FemSolo)

* Senior female-authored.
estimates clear
nber_fe FemSenior using `nber_fe', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_fgls FemSenior using `nber', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_table, type(FemSenior)

* Junior authored papers.
estimates clear
nber_fe FemSenior if Maxt<=3 using `nber_fe', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_fgls FemSenior if Maxt<=3 using `nber', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_table, type(FemJunior)

* At least one female author.
estimates clear
nber_fe Fem1 using `nber_fe', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_fgls Fem1 using `nber', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_table, type(Fem1)

* At least 50 percent female-authored.
estimates clear
nber_fe Fem50 using `nber_fe', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_fgls Fem50 using `nber', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_table, type(Fem50)

* NBER abstract is below the journal word limit.
estimates clear
nber_fe FemRatio if BelowAbstractLen using `nber_fe', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_fgls FemRatio if BelowAbstractLen using `nber', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
nber_table, type(wordlimit)

* Alternative program for calculating readability scores.
estimates clear
nber_fe FemRatio using `nber_fe', stats(r_fleschkincaid r_gunningfog r_smog) colnames(_fleschkincaid_score _gunningfog_score _smog_score)
nber_fgls FemRatio using `nber', stats(r_fleschkincaid r_gunningfog r_smog) colnames(_fleschkincaid_score _gunningfog_score _smog_score)
nber_table, type(R)

* Controlling for JEL codes
estimates clear
nber_fe FemRatio using `nber_fe_jel', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score) jel
nber_fgls FemRatio using `nber_jel', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score) jel
nber_table, type(jel) jel
********************************************************************************
