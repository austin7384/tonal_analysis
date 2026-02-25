********************************************************************************
***************** Figure D.2: Abstract vs. article readability *****************
********************************************************************************
use `nber', clear
merge 1:1 NberID using "~/tonal_analysis/data/raw/hengel_generated/articlestat", keep(match) nogenerate
foreach stat in fleschkincaid gunningfog {
  * Coordinates of location for point estimates.
  if "`stat'"=="fleschkincaid" {
    local coords "19 20"
  }
  else {
    local coords "23 25"
  }

  * Multiple stat by -1 (it looks better on the graph).
  replace nber_r_`stat' = -1*nber_r_`stat'
  replace article_r_`stat' = -1*article_r_`stat'

  * Regression line beta and standard error.
  regress article_r_`stat' nber_r_`stat', robust
  local beta = string(_b[nber_r_`stat'],"%03.2f")
  local se = string(_se[nber_r_`stat'],"%03.2f")

  binscatter article_r_`stat' nber_r_`stat', ///
    scheme(publishing-female) ///
    name(`stat', replace) ///
    color(pfblue pfblue) ///
    subtitle("`: variable label _`stat'_score'", placement(nwest) size(medium)) ///
    xtitle("Abstract readability", size(medium)) ///
    ytitle("Article readability", size(medium)) ///
    text(`coords' `"{fontface "Avenir-Light"}{it:{&beta}} = `beta'"' "(`se')", color(gray))
  graph export "~/tonal_analysis/outputs/figures/Figure-D.2-`stat'.pdf", replace fontface("Avenir-Light") as(pdf)
}
********************************************************************************
