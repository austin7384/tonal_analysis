********************************************************************************
************************************* DATA *************************************
********************************************************************************
* Variable labels.
import delimited varname label using ~/tonal_analysis/data/raw/hengel_labels/varlabels.csv, clear
generate command = "capture label variable " + varname + " " + label
tempfile varlabels
outfile command using `varlabels', replace noquote

* Value labels.
import delimited name value label using ~/tonal_analysis/data/raw/hengel_labels/vallabels.csv, clear
forvalues i=1/`=_N' {
	label define `=name[`i']' `=value[`i']' `=label[`i']', add
}
tempfile vallabels
label save using `vallabels', replace

* Generate editorial clusters.
import delimited "~/tonal_analysis/data/raw/hengel_generated/editors.csv", clear varnames(1) case(preserve) encoding("utf-8") bindquotes(strict)
by Journal Volume Issue Part (AuthorID), sort: generate j = _n
reshape wide AuthorID, i(Journal Volume Issue Part) j(j)
egen Editor = group(AuthorID*), missing
drop AuthorID*
tempfile cluster
save `cluster'
import delimited "~/tonal_analysis/data/raw/hengel_generated/article_editors.csv", clear varnames(1) case(preserve) encoding("utf-8") bindquotes(strict)
merge m:1 Journal Volume Issue Part using `cluster', keep(match) nogenerate
save `cluster', replace

* Generate article and author characteristic data.
import delimited "~/tonal_analysis/data/raw/hengel_generated/article_main.csv", clear varnames(1) case(preserve) encoding("utf-8") bindquotes(strict)
date_replace PubDate, mask("YMD")
label define Journal 1 "AER" 2 "ECA" 3 "JPE" 4 "QJE" 5 "P&P" 6 "RES"
encode_replace Journal
tempfile article_tmp
save `article_tmp'
import delimited "~/tonal_analysis/data/raw/hengel_generated/authorcorr.csv", clear varnames(1) case(preserve) encoding("utf-8") bindquotes(strict)
merge m:1 ArticleID using `article_tmp', assert(master match) keep(match) nogenerate
* Sort order determines how articles published in the same month are ordered.
* Articles published in the QJE and earlier in an issue assumed to be "newer"
* b/c shorter review times (Ellison, 2002).
gsort AuthorID PubDate -Journal -FirstPage
by AuthorID: generate t5 = _n
tempfile author_tmp
save `author_tmp'
import delimited "~/tonal_analysis/data/raw/hengel_generated/article_gender.csv", clear varnames(1) case(preserve) encoding("utf-8") bindquotes(strict)
label define gender 1 "Female" 0 "Male"
label values Female gender
date_replace PubDate, mask("YMD")
encode_replace Journal
merge 1:1 ArticleID AuthorID using `author_tmp', assert(master match)
generate Errata = _merge == 1 & Journal != 5
drop _merge
* Number of top-five articles at time of publication.
by AuthorID (PubDate), sort: replace t5 = t5[_n-1] if missing(t5)
replace t5 = 0 if missing(t5)
* Lifetime top-five publication count.
by AuthorID, sort: egen T5 = max(t5)
* Author with the highest number of top-five articles at the time of publication.
by ArticleID, sort: egen Maxt = max(t5)
* Author with the highest lifetime number of top-five publications.
by ArticleID, sort: egen MaxT = max(T5)
* Number of co-authors.
by ArticleID, sort: generate N = _N
* Female ratio.
by ArticleID, sort: egen FemRatio0 = mean(Female)
generate FemRatio = FemRatio0
replace FemRatio = 0 if FemRatio<0.5
* Senior author.
generate Senior = t==Maxt
* Number of senior authors.
by ArticleID, sort: egen SeniorN = total(Senior)
* Female and male seniority.
tempvar FemSenior
generate `FemSenior' = cond(t==Maxt&Female==1, 1, 0)
by ArticleID, sort: egen FemSenior = max(`FemSenior')
drop `FemSenior'
tempvar ManSenior
generate `ManSenior' = cond(t==Maxt&Female==0, 1, 0)
by ArticleID, sort: egen ManSenior = max(`ManSenior')
drop `ManSenior'
replace FemSenior = FemSenior * FemRatio0 // Make FemSenior proportional to the ratio of female authors.
replace FemSenior = . if FemSenior>0&ManSenior>0 // Make FemSenior strict (only equal to one if woman is the only senior author).
replace FemSenior = . if FemSenior==0 & FemRatio0>0 // Omit mixed-gendered papers with a male senior author.
* Senior female among non-senior-authored papers.
generate FemJunior = FemSenior
replace FemJunior = . if t > 3
* Female solo-authored.
generate FemSolo = .
replace FemSolo = 1 if FemRatio0==1 & N==1
replace FemSolo = 0 if FemRatio0==0 & N==1
* Exclusively female authored.
generate Fem100 = .
replace Fem100 = 1 if FemRatio0==1
replace Fem100 = 0 if FemRatio0==0
* At least 50% female authors.
generate Fem50 = .
replace Fem50 = 1 if FemRatio0>=0.5
replace Fem50 = 0 if FemRatio0==0
* At least one female author.
generate Fem1 = FemRatio0>0
* Save author-level data.
drop FirstPage PubDate Journal
tempfile author_chars
save `author_chars'
save "~/tonal_analysis/data/raw/hengel_generated/author_chars", replace
* Save article-level data.
collapse (firstnm) Maxt MaxT N FemRatio0 FemRatio SeniorN FemSenior FemJunior ManSenior FemSolo Fem100 Fem50 Fem1 Errata, by(ArticleID)
tempfile article_chars
save `article_chars'
save "~/tonal_analysis/data/raw/hengel_generated/article_chars", replace

* Generate institutional rank.
import delimited "~/tonal_analysis/data/raw/hengel_generated/inst_rank.csv", clear varnames(1) case(preserve) bindquotes(strict) encoding("utf-8")
xtset InstID Year
tssmooth ma maArticleN=ArticleN, window(5)
replace maArticleN = ArticleN if missing(maArticleN)
egen rankArticleN = rank(maArticleN), by(Year) field
summarize rankArticleN
egen InstRank = cut(rankArticleN), at(0(1)9, 10(10)60, `=r(max)+1')
tempfile instrank
save `instrank'
import delimited "~/tonal_analysis/data/raw/hengel_generated/inst_rank_author.csv", clear varnames(1) case(preserve) bindquotes(strict) encoding("utf-8")
merge m:m InstID Year using `instrank', assert(master match) nogenerate
replace InstRank = 60 if missing(InstRank) // P&P articles involving an unranked affiliation
save `instrank', replace
collapse (min) MaxInst=InstRank, by(ArticleID)
compress
tempfile article_instrank
save `article_instrank'
use `instrank', clear
collapse (min) InstRank, by(ArticleID AuthorID)
compress
tempfile author_instrank
save `author_instrank'

* Generate publication order.
import delimited "~/tonal_analysis/data/raw/hengel_generated/pub_order.csv", clear varnames(1) case(preserve) bindquotes(strict) encoding("utf-8")
by Journal Volume Issue (FirstPage), sort: generate PubOrder = _n
keep ArticleID PubOrder
compress
tempfile order
save `order'

* Generate native English.
import delimited "~/tonal_analysis/data/raw/hengel_generated/english.csv", clear varnames(1) case(preserve) bindquotes(strict) encoding("utf-8")
tempfile english
save `english'

* Generate theory/empirical.
import delimited "~/tonal_analysis/data/raw/hengel_generated/JEL.csv", clear varnames(1) case(preserve) encoding("utf-8") bindquotes(strict)
drop Description
tempfile type
save `type'
import delimited "~/tonal_analysis/data/raw/hengel_generated/theory_emp.csv", clear varnames(1) case(preserve) bindquotes(strict) encoding("utf-8")
merge m:1 JEL using `type', keep(master match) nogenerate
replace Type = "Other" if missing(Type)
keep ArticleID Type
duplicates drop
generate Type_ = 1
reshape wide Type_, i(ArticleID) j(Type) string
foreach var of varlist Type_* {
	replace `var' = 0 if missing(`var')
}
save `type', replace

* Generate primary JEL data.
import delimited "~/tonal_analysis/data/raw/hengel_generated/primary_jel.csv", clear varnames(1) case(preserve) bindquotes(strict) encoding("utf-8")
duplicates drop
encode_replace JEL
distinct JEL
forvalues i=1/`r(ndistinct)' {
	generate JEL1_`:label (JEL) `i'' = JEL == `i'
}
collapse (max) JEL1_*, by(ArticleID)
compress
tempfile primary_jel
save `primary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/primary_jel", replace

* Generate tertiary JEL data.
import delimited "~/tonal_analysis/data/raw/hengel_generated/tertiary_jel.csv", clear varnames(1) case(preserve) bindquotes(strict) encoding("utf-8")
encode_replace JEL
distinct JEL
forvalues i=1/`r(ndistinct)' {
	generate byte JEL3_`i' = JEL == `i'
}
collapse (max) JEL3_*, by(ArticleID)
compress
tempfile tertiary_jel
save `tertiary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/tertiary_jel", replace

* Generate article-level P&P data.
import delimited "~/tonal_analysis/data/raw/hengel_generated/article_pp.csv", clear varnames(1) case(preserve) bindquotes(strict) encoding("utf-8")
reshape wide _, i(ArticleID) j(StatName) string
merge 1:1 ArticleID using `article_chars', assert(using match) keep(match) nogenerate
merge 1:1 ArticleID using `article_instrank', assert(using match) keep(match) nogenerate
merge 1:1 ArticleID using `order', assert(using match) keep(match) nogenerate
merge 1:1 ArticleID using `cluster', assert(using match) keep(match) nogenerate
merge 1:1 ArticleID using `english', assert(using match) keep(match) nogenerate
merge 1:1 ArticleID using `type', assert(using match) keep(match) nogenerate
merge m:1 ArticleID using "~/tonal_analysis/data/raw/hengel_generated/readstat", assert(using match) keep(match) nogenerate
egen JnlVol = group(Journal Volume)
egen JnlVolIss = group(Journal Volume Issue)
label define Journal 1 "AER" 2 "ECA" 3 "JPE" 4 "QJE" 5 "P&P" 6 "RES"
encode_replace Journal
date_replace PubDate, mask("YMD")
generate _wps_count = _word_count / _sent_count
generate _pps_count = _polysyblword_count / _sent_count
generate _spw_count = _sybl_count / _word_count
generate _pww_count = _polysyblword_count / _word_count
generate _dww_count = _notdalechall_count / _word_count
generate asinhCiteCount = ln(CiteCount + sqrt(1+CiteCount^2))
generate Blind = Year<=1997&(Journal==4|(PubDate>=date("1989-06-01", "YMD")&Journal==1))
* LLM group composite scores (higher = more assertive/direct; jargon already flipped in Python).
* Group 1: Creativity and Hedging
generate _llm_g1_score = (_llm_modal_verb + _llm_hedging + _llm_qualifier + _llm_ack_limits + _llm_caution) / 5
* Group 2: Assertiveness and Voice
generate _llm_g2_score = (_llm_assertiveness + _llm_active_passive) / 2
* Group 3: Structural Directness
generate _llm_g3_score = (_llm_directness + _llm_imperative) / 2
* Group 4: Authorial Stance and Novelty
generate _llm_g4_score = (_llm_pronoun + _llm_novelty + _llm_jargon + _llm_emotional) / 4
* Group 5: Support and Impact
generate _llm_g5_score = (_llm_evidence + _llm_practical) / 2
do `varlabels'
compress
* Save the full LLM dataset as a tempfile before pruning, so group datasets can be
* built from it later. The main article_pp/article datasets retain only _llm_readability.
tempfile article_llm_full
save `article_llm_full'
* Drop individual LLM criterion variables and group composites from main datasets.
drop _llm_modal_verb _llm_hedging _llm_qualifier _llm_ack_limits _llm_caution ///
	_llm_assertiveness _llm_active_passive _llm_directness _llm_imperative ///
	_llm_pronoun _llm_novelty _llm_jargon _llm_emotional _llm_evidence _llm_practical ///
	_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score
tempfile article_pp
save `article_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_pp", replace

* Generate article-level JEL data + P&P.
use `article_pp', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_primary_jel_pp
save `article_primary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_primary_jel_pp", replace

* Generate tertiary JEL data + P&P.
use `article_pp', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_tertiary_jel_pp
save `article_tertiary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_tertiary_jel_pp", replace

* Generate article-level data.
* Generate article data.
use `article_pp'
drop if Journal==5
tempfile article
save `article'
save "~/tonal_analysis/data/raw/hengel_generated/article", replace

* Generate article-level JEL data.
use `article', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_primary_jel
save `article_primary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_primary_jel", replace

* Generate tertiary JEL data.
use `article', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_tertiary_jel
save `article_tertiary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_tertiary_jel", replace

* Generate LLM group datasets (top four journals, no P&P).
* Each dataset contains all controls + that group's criterion variables + its composite score.
************* Group 1: Creativity and Hedging *************
use `article_llm_full', clear
drop _llm_assertiveness _llm_active_passive ///
	_llm_directness _llm_imperative ///
	_llm_pronoun _llm_novelty _llm_jargon _llm_emotional ///
	_llm_evidence _llm_practical ///
	_llm_g2_score _llm_g3_score _llm_g4_score _llm_g5_score
compress
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g1_pp", replace
use 'article_llm_g1_pp'
drop if Journal==5
tempfile article_llm_g1
save 'article_llm_g1'
save '~/tonal_analysis/data/raw/hengel_generated/article_llm_g1', replace

* Generate article-level JEL data + P&P.
use `article_llm_g1_pp', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_llm_g1_primary_jel_pp
save `article_llm_g1_primary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g1_primary_jel_pp", replace

* Generate tertiary JEL data + P&P.
use `article_llm_g1_pp', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_llm_g1_tertiary_jel_pp
save `article_llm_g1_tertiary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g1_tertiary_jel_pp", replace

* Generate article-level JEL data.
use `article_llm_g1', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_llm_g1_primary_jel
save `article_llm_g1_primary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g1_primary_jel", replace

* Generate tertiary JEL data.
use `article_llm_g1', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_llm_g1_tertiary_jel
save `article_llm_g1_tertiary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g1_tertiary_jel", replace

************* Group 2: Assertiveness and Voice *************
use `article_llm_full', clear
drop _llm_modal_verb _llm_hedging _llm_qualifier _llm_ack_limits _llm_caution ///
	_llm_directness _llm_imperative ///
	_llm_pronoun _llm_novelty _llm_jargon _llm_emotional ///
	_llm_evidence _llm_practical ///
	_llm_g1_score _llm_g3_score _llm_g4_score _llm_g5_score
compress
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g2_pp", replace
use 'article_llm_g2_pp'
drop if Journal==5
tempfile article_llm_g2
save 'article_llm_g2'
save '~/tonal_analysis/data/raw/hengel_generated/article_llm_g2', replace

* Generate article-level JEL data + P&P.
use `article_llm_g2_pp', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_llm_g2_primary_jel_pp
save `article_llm_g2_primary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g2_primary_jel_pp", replace

* Generate tertiary JEL data + P&P.
use `article_llm_g2_pp', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_llm_g2_tertiary_jel_pp
save `article_llm_g2_tertiary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g2_tertiary_jel_pp", replace

* Generate article-level JEL data.
use `article_llm_g2', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_llm_g2_primary_jel
save `article_llm_g2_primary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g2_primary_jel", replace

* Generate tertiary JEL data.
use `article_llm_g2', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_llm_g2_tertiary_jel
save `article_llm_g2_tertiary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g2_tertiary_jel", replace

************* Group 3: Structural Directness *************
use `article_llm_full', clear
drop _llm_modal_verb _llm_hedging _llm_qualifier _llm_ack_limits _llm_caution ///
	_llm_assertiveness _llm_active_passive ///
	_llm_pronoun _llm_novelty _llm_jargon _llm_emotional ///
	_llm_evidence _llm_practical ///
	_llm_g1_score _llm_g2_score _llm_g4_score _llm_g5_score
compress
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g3_pp", replace
use 'article_llm_g3_pp'
drop if Journal==5
tempfile article_llm_g3
save 'article_llm_g3'
save '~/tonal_analysis/data/raw/hengel_generated/article_llm_g3', replace

* Generate article-level JEL data + P&P.
use `article_llm_g3_pp', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_llm_g3_primary_jel_pp
save `article_llm_g3_primary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g3_primary_jel_pp", replace

* Generate tertiary JEL data + P&P.
use `article_llm_g3_pp', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_llm_g3_tertiary_jel_pp
save `article_llm_g3_tertiary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g3_tertiary_jel_pp", replace

* Generate article-level JEL data.
use `article_llm_g3', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_llm_g3_primary_jel
save `article_llm_g3_primary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g3_primary_jel", replace

* Generate tertiary JEL data.
use `article_llm_g3', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_llm_g3_tertiary_jel
save `article_llm_g3_tertiary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g3_tertiary_jel", replace

************* Group 4: Authorial Stance and Novelty *************
use `article_llm_full', clear
drop _llm_modal_verb _llm_hedging _llm_qualifier _llm_ack_limits _llm_caution ///
	_llm_assertiveness _llm_active_passive ///
	_llm_directness _llm_imperative ///
	_llm_evidence _llm_practical ///
	_llm_g1_score _llm_g2_score _llm_g3_score _llm_g5_score
compress
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g4_pp", replace
use 'article_llm_g4_pp'
drop if Journal==5
tempfile article_llm_g4
save 'article_llm_g4'
save '~/tonal_analysis/data/raw/hengel_generated/article_llm_g4', replace

* Generate article-level JEL data + P&P.
use `article_llm_g4_pp', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_llm_g4_primary_jel_pp
save `article_llm_g4_primary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g4_primary_jel_pp", replace

* Generate tertiary JEL data + P&P.
use `article_llm_g4_pp', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_ll4m_g4_tertiary_jel_pp
save `article_llm_g4_tertiary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g4_tertiary_jel_pp", replace

* Generate article-level JEL data.
use `article_llm_g4', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_llm_g4_primary_jel
save `article_llm_g4_primary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g4_primary_jel", replace

* Generate tertiary JEL data.
use `article_llm_g4', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_llm_g4_tertiary_jel
save `article_llm_g4_tertiary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g4_tertiary_jel", replace

************* Group 5: Support and Impact *************
use `article_llm_full', clear
drop _llm_modal_verb _llm_hedging _llm_qualifier _llm_ack_limits _llm_caution ///
	_llm_assertiveness _llm_active_passive ///
	_llm_directness _llm_imperative ///
	_llm_pronoun _llm_novelty _llm_jargon _llm_emotional ///
	_llm_g1_score _llm_g2_score _llm_g3_score _llm_g4_score
compress
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g5_pp", replace
use 'article_llm_g5_pp'
drop if Journal==5
tempfile article_llm_g5
save 'article_llm_g5'
save '~/tonal_analysis/data/raw/hengel_generated/article_llm_g5', replace

* Generate article-level JEL data + P&P.
use `article_llm_g5_pp', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_llm_g5_primary_jel_pp
save `article_llm_g5_primary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g5_primary_jel_pp", replace

* Generate tertiary JEL data + P&P.
use `article_llm_g5_pp', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_llm_g5_tertiary_jel_pp
save `article_llm_g5_tertiary_jel_pp'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g5_tertiary_jel_pp", replace

* Generate article-level JEL data.
use `article_llm_g5', clear
merge 1:1 ArticleID using `primary_jel', keep(match) nogenerate
do `varlabels'
compress
tempfile article_llm_g5_primary_jel
save `article_llm_g5_primary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g5_primary_jel", replace

* Generate tertiary JEL data.
use `article_llm_g5', clear
merge 1:1 ArticleID using `tertiary_jel', keep(match) nogenerate
compress
tempfile article_llm_g5_tertiary_jel
save `article_llm_g5_tertiary_jel'
save "~/tonal_analysis/data/raw/hengel_generated/article_llm_g5_tertiary_jel", replace


* Generate author-level data for top four journals.
use `author_chars', clear
merge m:1 ArticleID using `article', assert(master match) keep(match) nogenerate
merge m:1 ArticleID AuthorID using `author_instrank', assert(using match) keep(match) nogenerate
* Sort order determines how articles published in the same month are ordered.
* Articles published in the QJE and earlier in an issue assumed to be "newer"
* b/c shorter review times (Ellison, 2002).
gsort AuthorID PubDate -Journal -FirstPage
by AuthorID, sort: generate t = _n
by AuthorID, sort: egen T = max(t)
* Downweight duplicate observations (i.e., co-authored papers).
* Weights are inversely proportionate to the number of co-authors.
bysort ArticleID: generate AuthorWeight = _N
summarize AuthorWeight
replace AuthorWeight = r(max) + 1 - AuthorWeight
egen AuthorEditor = group(AuthorID Editor)
recode t (1=1)(2=2)(3/6=3)(nonmissing=4), generate(tBin)
xtset AuthorID t
fvset base 64 Year
fvset base 80 Editor
fvset base 64 MaxInst
fvset base 30 MaxT
do `varlabels'
do `vallabels'
label values Female gender
label values tBin tbin
compress
tempfile author
save `author'
save "~/tonal_analysis/data/raw/hengel_generated/author", replace

* Generate author-level data for all top five journals.
import delimited "~/tonal_analysis/data/raw/hengel_generated/article_top5.csv", clear varnames(1) case(preserve) encoding("utf-8") bindquotes(strict)
merge 1:m ArticleID using `author_chars', assert(match) nogenerate
label define Journal 1 "AER" 2 "ECA" 3 "JPE" 4 "QJE" 5 "P&P" 6 "RES"
encode_replace Journal
date_replace PubDate, mask("YMD")
keep if Errata==0 & Journal!=5
drop Errata
* Downweight duplicate observations (i.e., co-authored papers).
* Weights are inversely proportionate to the number of co-authors.
bysort ArticleID: generate AuthorWeight = _N
summarize AuthorWeight
replace AuthorWeight = r(max) + 1 - AuthorWeight
xtset AuthorID t5
do `varlabels'
do `vallabels'
label values Female gender
compress
tempfile author5
save `author5'
save "~/tonal_analysis/data/raw/hengel_generated/author5", replace

* Generate NBER data.
import delimited "~/tonal_analysis/data/raw/hengel_generated/nber.csv", clear varnames(1) case(preserve) encoding("utf-8") bindquotes(strict)
reshape wide nber_, i(ArticleID NberID) j(StatName) string
merge m:1 ArticleID using `article', keep(match) nogenerate
generate nber_wps_count = nber_word_count / nber_sent_count
generate nber_pps_count = nber_polysyblword_count / _sent_count
generate nber_spw_count = nber_sybl_count / nber_word_count
generate nber_pww_count = nber_polysyblword_count / nber_word_count
generate nber_dww_count = nber_notdalechall_count / nber_word_count
generate SemiBlind = (Journal==1&Year<2012|Journal==4&Year<2005)&Year>1997
generate BelowAbstractLen = (Journal==3)|(Journal==4)|(nber_word_count<=100&Journal==1)|(nber_word_count<=150&Journal==2)
* NBER LLM group composite scores (jargon already negated in Python).
* Group 1: Creativity and Hedging
generate nber_llm_g1_score = (nber_llm_modal_verb + nber_llm_hedging + nber_llm_qualifier + nber_llm_ack_limits + nber_llm_caution) / 5
* Group 2: Assertiveness and Voice
generate nber_llm_g2_score = (nber_llm_assertiveness + nber_llm_active_passive) / 2
* Group 3: Structural Directness
generate nber_llm_g3_score = (nber_llm_directness + nber_llm_imperative) / 2
* Group 4: Authorial Stance and Novelty
generate nber_llm_g4_score = (nber_llm_pronoun + nber_llm_novelty + nber_llm_jargon + nber_llm_emotional) / 4
* Group 5: Support and Impact
generate nber_llm_g5_score = (nber_llm_evidence + nber_llm_practical) / 2
date_replace WPDate, mask("YMD")
* Add readability data calculated using alternative program.
merge 1:1 NberID using "~/tonal_analysis/data/raw/hengel_generated/nberstat", assert(using match) keep(match) nogenerate
merge m:1 ArticleID using "~/tonal_analysis/data/raw/hengel_generated/readstat", assert(using match) keep(match) nogenerate
do `varlabels'
compress
* Save the full nber LLM dataset as a tempfile before pruning, so group datasets can be
* built from it later. The main nber dataset retain only nber_llm_readability.
tempfile nber_llm_full
save `nber_llm_full'
* Drop individual LLM criterion variables and group composites from main datasets.
drop nber_llm_modal_verb nber_llm_hedging nber_llm_qualifier nber_llm_ack_limits nber_llm_caution ///
	nber_llm_assertiveness nber_llm_active_passive nber_llm_directness nber_llm_imperative ///
	nber_llm_pronoun nber_llm_novelty nber_llm_jargon nber_llm_emotional nber_llm_evidence nber_llm_practical ///
	nber_llm_g1_score nber_llm_g2_score nber_llm_g3_score nber_llm_g4_score nber_llm_g5_score
tempfile nber
save `nber'
save "~/tonal_analysis/data/raw/hengel_generated/nber", replace

* Generate data to use the change in score as a dependent variable.
use `nber', clear
reshape long @_score, i(NberID) j(stat) string
generate time = substr(stat, 1, 4)!="nber"
replace stat = substr(stat, 5, .) if !time
reshape wide _score, i(NberID time) j(stat) string
rename _score* *_score
egen id = group(NberID)
do `varlabels'
xtset id time
tempfile nber_fe
save `nber_fe'
save "~/tonal_analysis/data/raw/hengel_generated/nber_fe", replace

* Add JEL codes to FGLS and FE data.
use `nber'
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
tempfile nber_jel
save `nber_jel'
use `nber_fe'
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
sort id time
tempfile nber_fe_jel
save `nber_fe_jel'
save "~/tonal_analysis/data/raw/hengel_generated/nber_fe_jel", replace

* Generate NBER LLM group datasets.
* Each dataset contains all controls + that group's NBER criterion variables + its NBER composite
* score + the matching article-level composite score (needed for the FE paired-difference reshape).
************* NBER Group 1: Creativity and Hedging *************
use `nber_llm_full', clear
drop nber_llm_assertiveness nber_llm_active_passive ///
	nber_llm_directness nber_llm_imperative ///
	nber_llm_pronoun nber_llm_novelty nber_llm_jargon nber_llm_emotional ///
	nber_llm_evidence nber_llm_practical ///
	nber_llm_g2_score nber_llm_g3_score nber_llm_g4_score nber_llm_g5_score
merge m:1 ArticleID using `article_llm_full', keepusing(_llm_g1_score) keep(match) nogenerate
compress
tempfile nber_llm_g1
save `nber_llm_g1'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g1", replace
use `nber_llm_g1', clear
reshape long @_score, i(NberID) j(stat) string
generate time = substr(stat, 1, 4)!="nber"
replace stat = substr(stat, 5, .) if !time
reshape wide _score, i(NberID time) j(stat) string
rename _score* *_score
egen id = group(NberID)
do `varlabels'
xtset id time
compress
tempfile nber_llm_g1_fe
save `nber_llm_g1_fe'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g1_fe", replace
use `nber_llm_g1', clear
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
tempfile nber_llm_g1_jel
save `nber_llm_g1_jel'
use `nber_llm_g1_fe', clear
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
sort id time
tempfile nber_llm_g1_fe_jel
save `nber_llm_g1_fe_jel'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g1_fe_jel", replace

************* NBER Group 2: Assertiveness and Voice *************
use `nber_llm_full', clear
drop nber_llm_modal_verb nber_llm_hedging nber_llm_qualifier nber_llm_ack_limits nber_llm_caution ///
	nber_llm_directness nber_llm_imperative ///
	nber_llm_pronoun nber_llm_novelty nber_llm_jargon nber_llm_emotional ///
	nber_llm_evidence nber_llm_practical ///
	nber_llm_g1_score nber_llm_g3_score nber_llm_g4_score nber_llm_g5_score
merge m:1 ArticleID using `article_llm_full', keepusing(_llm_g2_score) keep(match) nogenerate
compress
tempfile nber_llm_g2
save `nber_llm_g2'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g2", replace
use `nber_llm_g2', clear
reshape long @_score, i(NberID) j(stat) string
generate time = substr(stat, 1, 4)!="nber"
replace stat = substr(stat, 5, .) if !time
reshape wide _score, i(NberID time) j(stat) string
rename _score* *_score
egen id = group(NberID)
do `varlabels'
xtset id time
compress
tempfile nber_llm_g2_fe
save `nber_llm_g2_fe'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g2_fe", replace
use `nber_llm_g2', clear
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
tempfile nber_llm_g2_jel
save `nber_llm_g2_jel'
use `nber_llm_g2_fe', clear
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
sort id time
tempfile nber_llm_g2_fe_jel
save `nber_llm_g2_fe_jel'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g2_fe_jel", replace

************* NBER Group 3: Structural Directness *************
use `nber_llm_full', clear
drop nber_llm_modal_verb nber_llm_hedging nber_llm_qualifier nber_llm_ack_limits nber_llm_caution ///
	nber_llm_assertiveness nber_llm_active_passive ///
	nber_llm_pronoun nber_llm_novelty nber_llm_jargon nber_llm_emotional ///
	nber_llm_evidence nber_llm_practical ///
	nber_llm_g1_score nber_llm_g2_score nber_llm_g4_score nber_llm_g5_score
merge m:1 ArticleID using `article_llm_full', keepusing(_llm_g3_score) keep(match) nogenerate
compress
tempfile nber_llm_g3
save `nber_llm_g3'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g3", replace
use `nber_llm_g3', clear
reshape long @_score, i(NberID) j(stat) string
generate time = substr(stat, 1, 4)!="nber"
replace stat = substr(stat, 5, .) if !time
reshape wide _score, i(NberID time) j(stat) string
rename _score* *_score
egen id = group(NberID)
do `varlabels'
xtset id time
compress
tempfile nber_llm_g3_fe
save `nber_llm_g3_fe'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g3_fe", replace
use `nber_llm_g3', clear
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
tempfile nber_llm_g3_jel
save `nber_llm_g3_jel'
use `nber_llm_g3_fe', clear
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
sort id time
tempfile nber_llm_g3_fe_jel
save `nber_llm_g3_fe_jel'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g3_fe_jel", replace

************* NBER Group 4: Authorial Stance and Novelty *************
use `nber_llm_full', clear
drop nber_llm_modal_verb nber_llm_hedging nber_llm_qualifier nber_llm_ack_limits nber_llm_caution ///
	nber_llm_assertiveness nber_llm_active_passive ///
	nber_llm_directness nber_llm_imperative ///
	nber_llm_evidence nber_llm_practical ///
	nber_llm_g1_score nber_llm_g2_score nber_llm_g3_score nber_llm_g5_score
merge m:1 ArticleID using `article_llm_full', keepusing(_llm_g4_score) keep(match) nogenerate
compress
tempfile nber_llm_g4
save `nber_llm_g4'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g4", replace
use `nber_llm_g4', clear
reshape long @_score, i(NberID) j(stat) string
generate time = substr(stat, 1, 4)!="nber"
replace stat = substr(stat, 5, .) if !time
reshape wide _score, i(NberID time) j(stat) string
rename _score* *_score
egen id = group(NberID)
do `varlabels'
xtset id time
compress
tempfile nber_llm_g4_fe
save `nber_llm_g4_fe'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g4_fe", replace
use `nber_llm_g4', clear
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
tempfile nber_llm_g4_jel
save `nber_llm_g4_jel'
use `nber_llm_g4_fe', clear
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
sort id time
tempfile nber_llm_g4_fe_jel
save `nber_llm_g4_fe_jel'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g4_fe_jel", replace

************* NBER Group 5: Support and Impact *************
use `nber_llm_full', clear
drop nber_llm_modal_verb nber_llm_hedging nber_llm_qualifier nber_llm_ack_limits nber_llm_caution ///
	nber_llm_assertiveness nber_llm_active_passive ///
	nber_llm_directness nber_llm_imperative ///
	nber_llm_pronoun nber_llm_novelty nber_llm_jargon nber_llm_emotional ///
	nber_llm_g1_score nber_llm_g2_score nber_llm_g3_score nber_llm_g4_score
merge m:1 ArticleID using `article_llm_full', keepusing(_llm_g5_score) keep(match) nogenerate
compress
tempfile nber_llm_g5
save `nber_llm_g5'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g5", replace
use `nber_llm_g5', clear
reshape long @_score, i(NberID) j(stat) string
generate time = substr(stat, 1, 4)!="nber"
replace stat = substr(stat, 5, .) if !time
reshape wide _score, i(NberID time) j(stat) string
rename _score* *_score
egen id = group(NberID)
do `varlabels'
xtset id time
compress
tempfile nber_llm_g5_fe
save `nber_llm_g5_fe'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g5_fe", replace
use `nber_llm_g5', clear
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
tempfile nber_llm_g5_jel
save `nber_llm_g5_jel'
use `nber_llm_g5_fe', clear
merge m:1 ArticleID using `primary_jel', keep(match) nogenerate
sort id time
tempfile nber_llm_g5_fe_jel
save `nber_llm_g5_fe_jel'
save "~/tonal_analysis/data/raw/hengel_generated/nber_llm_g5_fe_jel", replace

* Generate review time data.
import delimited "~/tonal_analysis/data/raw/hengel_generated/time.csv", clear varnames(1) case(preserve) encoding("utf-8") bindquotes(strict)
merge m:1 ArticleID using `article_chars', assert(using match) keep(match) nogenerate
merge m:1 ArticleID using `article_instrank', keep(master match) nogenerate
merge m:1 ArticleID using `order', assert(using match) keep(match) nogenerate
merge m:1 ArticleID using `cluster', assert(using match) keep(match) nogenerate
merge m:1 ArticleID using `english', assert(using match) keep(match) nogenerate
merge m:1 ArticleID using `type', assert(using match) keep(match) nogenerate
generate asinhCiteCount = ln(CiteCount + sqrt(1+CiteCount^2))
date_replace PubDate, mask("YMD")
date_replace Received, mask("YMD")
date_replace Accepted, mask("YMD")
label define Journal 1 "AER" 2 "ECA" 3 "JPE" 4 "QJE" 5 "P&P" 6 "RES"
encode_replace Journal
merge m:1 ArticleID using `article', keep(master match) keepusing(_flesch_score) nogenerate
do `varlabels'
compress
tempfile duration
save `duration'
save "~/tonal_analysis/data/raw/hengel_generated/duration", replace

* Generate duration variants substituting LLM readability measures for _flesch_score.
* Duration with LLM readability criterion score
use `duration', clear
drop _flesch_score
merge m:1 ArticleID using `article', keep(master match) keepusing(_llm_readability) nogenerate
do `varlabels'
compress
tempfile duration_llm_readability
save `duration_llm_readability'
save "~/tonal_analysis/data/raw/hengel_generated/duration_llm_readability", replace

* Duration with LLM Group 1 (Creativity and Hedging) composite score
use `duration', clear
drop _flesch_score
merge m:1 ArticleID using `article_llm_full', keep(master match) keepusing(_llm_g1_score) nogenerate
do `varlabels'
compress
tempfile duration_llm_g1
save `duration_llm_g1'
save "~/tonal_analysis/data/raw/hengel_generated/duration_llm_g1", replace

* Duration with LLM Group 2 (Assertiveness and Voice) composite score
use `duration', clear
drop _flesch_score
merge m:1 ArticleID using `article_llm_full', keep(master match) keepusing(_llm_g2_score) nogenerate
do `varlabels'
compress
tempfile duration_llm_g2
save `duration_llm_g2'
save "~/tonal_analysis/data/raw/hengel_generated/duration_llm_g2", replace

* Duration with LLM Group 3 (Structural Directness) composite score
use `duration', clear
drop _flesch_score
merge m:1 ArticleID using `article_llm_full', keep(master match) keepusing(_llm_g3_score) nogenerate
do `varlabels'
compress
tempfile duration_llm_g3
save `duration_llm_g3'
save "~/tonal_analysis/data/raw/hengel_generated/duration_llm_g3", replace

* Duration with LLM Group 4 (Authorial Stance and Novelty) composite score
use `duration', clear
drop _flesch_score
merge m:1 ArticleID using `article_llm_full', keep(master match) keepusing(_llm_g4_score) nogenerate
do `varlabels'
compress
tempfile duration_llm_g4
save `duration_llm_g4'
save "~/tonal_analysis/data/raw/hengel_generated/duration_llm_g4", replace

* Duration with LLM Group 5 (Support and Impact) composite score
use `duration', clear
drop _flesch_score
merge m:1 ArticleID using `article_llm_full', keep(master match) keepusing(_llm_g5_score) nogenerate
do `varlabels'
compress
tempfile duration_llm_g5
save `duration_llm_g5'
save "~/tonal_analysis/data/raw/hengel_generated/duration_llm_g5", replace

* Get author names for matched pair table
import delimited "~/tonal_analysis/data/raw/hengel_generated/author_names.csv", clear varnames(1) case(preserve) encoding("utf-8") bindquotes(strict)
tempfile names
save `names'
********************************************************************************
