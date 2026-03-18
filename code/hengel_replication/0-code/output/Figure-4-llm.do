********************************************************************************
*************** Figure 4 LLM: LLM readability of authors' tth publication **************
********************************************************************************
use `author', clear
binscatter _llm_readability_score t, ///
  by(Female) ///
  scheme(publishing-female) ///
  xtitle("") ///
  legend(order(1 2) label(2 "Female") label(1 "Male")) ///
  color(pfblue pfpink) ///
  xtitle("{it:t}th article", placement(seast) size(medsmall)) ///
  ytitle("LLM Readability", size(medsmall)) ///
  aspectratio(0.6)
graph export "~/tonal_analysis/outputs/figures/Figure-4-llm.pdf", replace fontface("Avenir-Light") as(pdf)
********************************************************************************
