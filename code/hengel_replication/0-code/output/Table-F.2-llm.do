********************************************************************************
** Table F.2 LLM: Gender differences in LLM tonal composites, author-level ****
********************************************************************************
* Redefine only the table output program; author_level is reused as-is.
capture program drop author_level_table
program define author_level_table
	syntax , type(string)

	estout xtabond_* using "~/tonal_analysis/outputs/tables/tex/Table-F.2-llm-`type'.tex", style(publishing-female_latex) ///
		stats(N hansenp sarganp ar1 ar2 editor blind journal Nj inst qual native, fmt(%9.0fc 3 3 3) ///
			labels( ///
				"\midrule${n}No. observations" "\mcol{\textit{Tests of instrument validity}} \\\${n}\quad Hansen test (\(p\)-value)" "\quad Sargan test (\(p\)-value)" ///
				"\mcol{\textit{\(z\)-test for no serial correlation}} \\\${n}\quad Order 1" "\quad Order 2" ///
				"\midrule${n}Editor effects" "Blind review" "Journal effects" "\(N_j\)" ///
				"Institution effects" "Quality controls" "Native speaker")) ///
		varlabels(Female "Female ratio for women (\(\beta_1\))" Male "Female ratio for men (\(\beta_1+\beta_2\))" ///
			Interaction "Female ratio#male (\(\beta_2\))" L._stat_score "Lagged score (\(\beta_0\))", ///
				prefix("\mrow{4cm}{") suffix("}"))
	create_latex using "`r(fn)'", tablename("table4llm") type("`type'")
end

* Female ratio.
author_level FemRatio using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5)
author_level_table, type(FemRatio)

* Exclusively female-authored.
author_level Fem100 using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5)
author_level_table, type(Fem100)

* Solo-authored.
author_level FemSolo using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5)
author_level_table, type(FemSolo)

* At least one female author.
author_level Fem1 using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5)
author_level_table, type(Fem1)

* Majority female-authored.
author_level Fem50 using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5)
author_level_table, type(Fem50)

* Senior female author.
author_level FemSenior using `author', stats(llm_g1 llm_g2 llm_g3 llm_g4 llm_g5)
author_level_table, type(FemSenior)
********************************************************************************
