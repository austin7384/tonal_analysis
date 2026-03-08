********************************************************************************
**************** Figure G.1 LLM: Blind review event study, LLM ****************
********************************************************************************
local _llm_g1_title "G1: Creativity & Hedging"
local _llm_g2_title "G2: Assertiveness & Voice"
local _llm_g3_title "G3: Structural Directness"
local _llm_g4_title "G4: Stance & Novelty"
local _llm_g5_title "G5: Support & Impact"

foreach stat in llm_g1 llm_g2 llm_g3 llm_g4 llm_g5 {
	use `nber_fe', clear

	* Create a continuous variable centered around zero, where zero represents the date at which a journal switched from double-blind review to single-blind review (or vice versa).
	generate BlindVol = Volume - 112 if Journal==4 // QJE was blind before 1998
	replace BlindVol = Volume - 87 if Journal==1 // AER was blind until 1998
	replace BlindVol = 81 - Volume if Journal==1 & Blind==0 & Year<1997 // AER pre-1991 non-blind
	replace BlindVol = . if Volume==113 & Journal==4
	replace BlindVol = . if Volume==88 & Journal==1

	* Create factor variable centered around policy change.
	egen BlindVolCut = cut(BlindVol), at(-10(2)25)
	summarize BlindVolCut
	local min = abs(r(min))
	replace BlindVolCut = `min' + BlindVolCut
	fvset base 28 BlindVolCut

	* Regress change in score on everything except the dummy variable for double-blind review.
	reghdfe D._`stat'_score FemRatio N Maxt MaxT asinhCiteCount i.NativeEnglish, absorb(i.Editor i.Year##i.Journal) vce(cluster Year) resid
	predict resid, residuals

	replace Fem50 = 0 if missing(Fem50)
	eststo man1: regress resid i.BlindVolCut if BlindVol<-1&Fem50==0
	eststo fem1: regress resid i.BlindVolCut if BlindVol<-1&Fem50==1
	eststo man2: regress resid i.BlindVolCut if BlindVol>1&Fem50==0
	eststo fem2: regress resid i.BlindVolCut if BlindVol>1&Fem50==1
	eststo suest: suest man1 man2 fem1 fem2

	* First panel gets full labels; others don't.
	if "`stat'"=="llm_g1" {
		local subtitle subtitle("Years before/after policy change", position(6) size(vsmall))
		local subtitle1 subtitle("Double-blind + pre-internet", ring(0) size(medium))
		local subtitle2 subtitle("Single-blind or post-internet", ring(0) size(medium))
		local ytitle ytitle("Unexplained change in score", size(small))
		local policy_text text(0 10.3 "Policy change", orientation(vertical) color("116 116 116"))
		local legend
	}
	else {
		local subtitle
		local subtitle1
		local subtitle2
		local ytitle ytitle("")
		local policy_text
		local legend legend(off)
	}

	* Create graph to the left of the policy change (double-blind review + pre-internet)
	margins if BlindVol<-1&BlindVolCut>0, over(BlindVolCut) ///
		predict(equation(fem1_mean)) ///
		predict(equation(man1_mean))
	marginsplot, noci `subtitle1' ///
		recast(scatter) ///
		name(g1, replace) ///
		legend(off) ///
		graphregion(margin(0 0 0 0)) ///
		xscale(range(0(2)10)) ///
		plot1opts(color(pfpink)) ///
		plot2opts(color(pfblue)) ///
		scheme(publishing-female) ///
		title("") ///
		xtitle("") `ytitle' ///
		xlabel(8 "2–3" 6 "4–5" 4 "6–7" 2 "8–9", labsize(small)) ///
		ylabel(, labsize(small)) ///
		addplot((lfit resid BlindVolCut if BlindVolCut<=8&BlindVolCut>0&Fem50==0, color(pfblue))(lfit resid BlindVolCut if BlindVolCut<=8&BlindVolCut>0&Fem50==1, color(pfpink)))

	* Create graph to the right of the policy change (single-blind review or post-internet)
	margins if BlindVol>1&BlindVolCut<=20, over(BlindVolCut) ///
		predict(equation(fem2_mean)) ///
		predict(equation(man2_mean))
	marginsplot, noci xline(10.7) `subtitle2' `policy_text' `legend' ///
		recast(scatter) ///
		name(g2, replace) ///
		yscale(off) ///
		xscale(range(10(2)20)) ///
		plot1opts(color(pfpink)) ///
		plot2opts(color(pfblue)) ///
		scheme(publishing-female) ///
		title("") ///
		xtitle("") ///
		xlabel(12 "2–3" 14 "4–5" 16 "6–7" 18 "8–9" 20 "10–11", labsize(small)) ///
		ylabel(, labsize(small)) ///
		addplot((lfit resid BlindVolCut if BlindVol>=2&BlindVol<=10&Fem50==0, color(pfblue))(lfit resid BlindVolCut if BlindVol>=2&BlindVol<=10&Fem50==1, ytitle("") color(pfpink)), legend(order(2 "Male" 1 "Female") ring(0)) xscale(range(10(2)20)))

	* Combine graphs.
	graph combine g1 g2, ycommon  imargin(0 0 0 0) commonscheme scheme(publishing-female) title("`_`stat'_title'", position(5) size(small)) `subtitle' name(`stat', replace)
}

* Create a combined graph of all five LLM group panels.
graph combine llm_g1 llm_g2 llm_g3 llm_g4 llm_g5, ycommon imargin(0 0 0 0) commonscheme scheme(publishing-female) name(combo_llm, replace)
graph export "~/tonal_analysis/outputs/figures/Figure-G.1-llm-combo.pdf", replace as(pdf) fontface("Avenir-Light")
********************************************************************************
