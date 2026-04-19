********************************************************************************
***** Figure 6 LLM Individual: draft vs final for 9 individual LLM criteria ****
********************************************************************************
capture program drop fig6_llm_ind
program define fig6_llm_ind
  syntax, nber(string) auth(string) crit(string) fname(string) title(string)

  use "`nber'", clear
  merge m:m ArticleID using "`auth'", keep(match) nogenerate

  * Use a uniquely-named label to avoid redefinition errors across loop iterations.
  capture label define tBinInd 1 "1" 2 "2" 3 "3" 4 "4-5" 5 "6+"
  tempvar tBin
  recode t (1=1)(2=2)(3=3)(4/5=4)(nonmissing=5), generate(`tBin')
  label values `tBin' tBinInd

  eststo nber: regress nber_llm_`crit'_score c.FemRatio##c.`tBin' Maxt MaxT asinhCiteCount N i.NativeEnglish i.Year##i.Journal i.Editor [aweight=AuthorWeight]
  eststo reg:  regress _llm_`crit'_score     c.FemRatio##c.`tBin' Maxt MaxT asinhCiteCount N i.NativeEnglish i.Year##i.Journal i.Editor [aweight=AuthorWeight]
  eststo suest: suest nber reg, vce(cluster Editor)

  tempname b
  estimates restore suest
  margins, at(FemRatio=0) at(FemRatio=1) over(`tBin') predict(equation(nber_mean)) predict(equation(reg_mean))
  matrix `b' = r(table)'
  svmat_rownames `b', names(col) generate(rname) rowname clear
  generate version = real(regexs(1)) if regexm(rname, "^([0-9]+)")
  generate female = real(regexs(1))-1 if regexm(rname, "predict#([0-9]+)")
  generate t = real(regexs(1)) if regexm(rname, "at#([0-9]+)")
  sort female t version
  keep b version female t
  reshape wide b, i(t female) j(version)
  generate n = t + female*0.07
  graph twoway ///
    (scatter b1 n if !female, color(pfblue) msize(vlarge) msymbol(circle_hollow) mlwidth(medthin)) ///
    (scatter b2 n if !female, color(pfblue) msize(large) msymbol(diamond)) ///
    (scatter b1 n if  female, color(pfpink) msize(vlarge) msymbol(circle_hollow) mlwidth(medthin)) ///
    (scatter b2 n if  female, color(pfpink) msize(large) msymbol(diamond)) ///
    (pcspike b1 n b2 n if !female, color(pfblue) lwidth(vthin) lpattern(shortdash)) ///
    (pcspike b1 n b2 n if  female, color(pfpink) lwidth(vthin) lpattern(shortdash)) ///
    , legend(pos(5) ring(0) rows(1) order(1 "Male" 3 "Female") color(gray) size(small)) ///
    title("`title'", size(medsmall) color(gray)) ///
    xtitle("{it:t}th article", size(medsmall) color(gray) placement(seast) justification(right)) ///
    scheme(publishing-female) ///
    graphregion(margin(zero)) ///
    xscale(range(0.9 5.2)) ///
    xlabel(1 "1" 2 "2" 3 "3" 4 "4-5" 5 "6+")
  graph export "~/tonal_analysis/outputs/figures/Figure-6-llm-`fname'.pdf", replace fontface("Avenir-Light") as(pdf)
  estimates clear
end

fig6_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(modal_verb)    fname(modal-verb)    title("Modal Verb Strength")
fig6_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(hedging)       fname(hedging)       title("Hedging Frequency & Type")
fig6_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(ack_limits)    fname(ack-limits)    title("Acknowledgement of Limitations")
fig6_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(active_passive) fname(active-passive) title("Active/Passive Voice Ratio")
fig6_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(directness)    fname(directness)    title("Sentence Length & Directness")
fig6_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(pronoun)       fname(pronoun)       title("Pronoun Commitment")
fig6_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(novelty)       fname(novelty)       title("Novelty-Claim Strength")
fig6_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(jargon)        fname(jargon)        title("Jargon/Technicality Density")
fig6_llm_ind, nber(`"`nber'"') auth(`"`author'"') crit(evidence)      fname(evidence)      title("Evidence & Citation Usage")
********************************************************************************
