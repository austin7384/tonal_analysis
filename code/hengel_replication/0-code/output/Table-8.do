********************************************************************************
************** Table 8: Gender gap in readability at increasing t **************
********************************************************************************
* Gender gap in readability at increasing t
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
      eststo `stat'_`namelist'_`i': regress _`stat'_score `namelist' `male' `femblind' Maxt N asinhCiteCount i.Editor i.Journal#i.Year i.MaxInst i.NativeEnglish if `tif' [aweight=AuthorWeight]
      local n`i++' = e(N)
    }
    eststo `stat'_`namelist': suest2 `stat'_`namelist'_*, cluster(AuthorID Editor)

    tempname b se
    forvalues j=1/`=`i'-1' {
      matrix `b' = nullmat(`b') \ _b[`stat'_`namelist'_`j'_mean:`namelist']
      matrix `se' = nullmat(`se') \ _se[`stat'_`namelist'_`j'_mean:`namelist']
    }

    * All observations together. (Note that sample sizes are too small to estimate population-averaged regression.)
    if "`namelist'"=="FemSolo" {
      reghdfe _`stat'_score FemSolo i.FemSolo#1.Blind Maxt asinhCiteCount i.NativeEnglish, absorb(i.Editor i.Journal#i.Year i.MaxInst i.MaxT) vce(cluster AuthorID)
      local n6 = e(N_full)
    }
    else {
     xtreg _`stat'_score `namelist' `male' `femblind' Maxt N i.Editor i.Journal#i.Year i.MaxInst asinhCiteCount i.MaxT i.NativeEnglish `if', pa corr(ar 1) vce(robust)
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

capture program drop tth_pub_table
program define tth_pub_table
  syntax , type(string)

  estout reg_* using "~/tonal_analysis/outputs/tables/tex/Table-8-`type'.tex", style(publishing-female_latex) ///
    stats(obs editor blind jnlyr Nj inst qual native, labels("No. observations" "\midrule${n}Editor effects" ///
      "Blind review" "Journal#Year effects" "\(N_j\)" "Institution effects" "Quality controls" "Native speaker")) ///
    prefoot("\midrule")
  create_latex using "`r(fn)'", tablename("tableH2") type("`type'")
end

capture program drop tth_pub_sig
program define tth_pub_sig
  syntax namelist

  tempname P Chi
  foreach stat in flesch fleschkincaid gunningfog smog dalechall {
  	estimates restore `stat'_`namelist'
  	tempname p chi
  	forvalues i=2/5 {
  		test [`stat'_`namelist'_1_mean]`namelist' = [`stat'_`namelist'_`i'_mean]`namelist'
  		matrix `p' = nullmat(`p') , r(p)
  		matrix `chi' = nullmat(`chi') , r(chi2)
  	}
  	test [`stat'_`namelist'_2_mean]`namelist' = [`stat'_`namelist'_3_mean]`namelist'
  	matrix `P' = nullmat(`P') \ (`p' , r(p))
  	matrix `Chi' = nullmat(`Chi') \ (`chi' , r(chi2))
  }
  matrix rownames `P' = _flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score
  matrix rownames `Chi' = _flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score

  * Display p-values.
  matrix list `P'

  estout matrix(`Chi', fmt(3)) using "~/tonal_analysis/outputs/tables/tex/Table-I.3.tex", style(tex) mlabels(none) label collabels(none) replace
  create_latex using "`r(fn)'", tablename("tableH3") type("`type'")
end

use `author', clear
tth_pub FemRatio using `author', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
tth_pub_table, type(FemRatio)
tth_pub_sig FemRatio

* Solo-authored.
tth_pub FemSolo using `author', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
tth_pub_table, type(FemSolo)

* Exclusively female-authored.
tth_pub Fem100 using `author', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
tth_pub_table, type(Fem100)

* At least one female author.
tth_pub Female using `author', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
tth_pub_table, type(Fem1)

* Majority female-authored.
tth_pub Fem50 using `author', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
tth_pub_table, type(Fem50)

* Senior female author.
tth_pub FemSenior using `author', stats(flesch fleschkincaid gunningfog smog dalechall) colnames(_flesch_score _fleschkincaid_score _gunningfog_score _smog_score _dalechall_score)
tth_pub_table, type(FemSenior)

* Alternative program for calculating readability statistics.
tth_pub FemRatio using `author', stats(r_fleschkincaid r_gunningfog r_smog) colnames(_fleschkincaid_score _gunningfog_score _smog_score)
tth_pub_table, type(R)
********************************************************************************
