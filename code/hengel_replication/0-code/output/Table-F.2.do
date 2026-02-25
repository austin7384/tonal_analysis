********************************************************************************
***** Figure F.2: Gender differences in readability, author-level analysis *****
********************************************************************************
* Program to estimate author-level effects
capture program drop author_level
program define author_level, eclass
	syntax name using/ [if], stats(string)

	estimates clear
	use `using', clear

	* Replace FemSenior, Fem100 and Fem50 equal to zero for more variation in the data.
	if "`namelist'"=="FemSenior" | "`namelist'"=="Fem100" | "`namelist'"=="Fem50" | "`namelist'"=="FemSolo" {
		replace `namelist' = 0 if missing(`namelist') & FemRatio!=1
	}

	* FemRatio and FemSenior are continuous; Fem1 and Fem50 are discrete; Fem100 and FemSolo don't estimate the interaction.
	if "`namelist'"=="FemRatio" | "`namelist'"=="FemSenior" {
		local male c.`namelist'#0.Female
		local femblind c.`namelist'#1.Blind
	}
	else if "`namelist'"=="Fem1" | "`namelist'"=="Fem50" {
		local male 1.`namelist'#0.Female
		local femblind 1.`namelist'#1.Blind
	}
	else {
		local male
	}

	sort AuthorID t
	tempname b se mb mV p diffsargan r B z
	foreach stat in `stats' {
		eststo author: xtabond2 _`stat'_score L._`stat'_score `namelist' `male' `femblind' N asinhCiteCount Maxt MaxT NativeEnglish i.MaxInst i.Journal i.Editor ///
		`if' [aweight=AuthorWeight], gmm(L._`stat'_score, collapse) iv(`namelist' `male' `femblind' N asinhCiteCount Maxt MaxT NativeEnglish i.MaxInst i.Journal i.Editor) ///
		h(3) robust small

		* Return coefficients on female ratio for women, men, the interaction between female ratio and male author and the lagged score.
		* Except when using solo- and exclusively female-authored papers, then just return the female ratio for women and lagged score.
		if "`namelist'"=="FemRatio" | "`namelist'"=="Fem50" | "`namelist'"=="Fem1" | "`namelist'"=="FemSenior" {
			lincom _b[`namelist'] + _b[`male']
			matrix `b' = (_b[`namelist'] , r(estimate), _b[`male'], _b[L._`stat'_score])
			matrix `se' = (_se[`namelist'] , r(se), _se[`male'], _se[L._`stat'_score])
			local colnames Female Male Interaction L._stat_score
		}
		else {
			matrix `b' = (_b[`namelist'] , _b[L._`stat'_score])
			matrix `se' = (_se[`namelist'] , _se[L._`stat'_score])
			local colnames Female L._stat_score
		}

		* Difference between male and female scores as a percentage of male scores.
		tempname r
		if "`namelist'"=="FemRatio" {
			margins, at(FemRatio=0 Female=0)
			matrix `r' = r(b)
			display _n as text "Percentage difference between genders (`stat'): " as error round(100*abs(_b[FemRatio]/`r'[1,1]), 0.01)
		}

		ereturn_post `b', se(`se') obs(`e(N)') dof(`e(df_r)') ///
			local(editor ✓ blind ✓ journal ✓ inst ✓ qual ✓² Nj ✓ native ✓) ///
			scalar(N_g `e(N_g)' ar1 `e(ar1)' ar2 `e(ar2)' j `e(j)' hansenp `e(hansenp)' sarganp `e(sarganp)') ///
			colnames(`colnames') ///
			store(xtabond_`stat')
	}
end

capture program drop author_level_table
program define author_level_table
	syntax , type(string)

	estout xtabond_* using "~/tonal_analysis/outputs/tables/tex/Table-F.2-`type'.tex", style(publishing-female_latex) ///
		stats(N hansenp sarganp ar1 ar2 editor blind journal Nj inst qual native, fmt(%9.0fc 3 3 3) ///
			labels( ///
				"\midrule${n}No. observations" "\mcol{\textit{Tests of instrument validity}} \\\${n}\quad Hansen test (\(p\)-value)" "\quad Sargan test (\(p\)-value)" ///
				"\mcol{\textit{\(z\)-test for no serial correlation}} \\\${n}\quad Order 1" "\quad Order 2" ///
				"\midrule${n}Editor effects" "Blind review" "Journal effects" "\(N_j\)" ///
				"Institution effects" "Quality controls" "Native speaker")) ///
		varlabels(Female "Female ratio for women (\(\beta_1\))" Male "Female ratio for men (\(\beta_1+\beta_2\))" ///
			Interaction "Female ratio#male (\(\beta_2\))" L._stat_score "Lagged score (\(\beta_0\))", ///
				prefix("\mrow{4cm}{") suffix("}"))
	create_latex using "`r(fn)'", tablename("table4") type("`type'")
end

* Female ratio.
author_level FemRatio using `author', stats(flesch fleschkincaid gunningfog smog dalechall)
author_level_table, type(FemRatio)

* Exclusively female-authored.
author_level Fem100 using `author', stats(flesch fleschkincaid gunningfog smog dalechall)
author_level_table, type(Fem100)

* Solo-authored.
author_level FemSolo using `author', stats(flesch fleschkincaid gunningfog smog dalechall)
author_level_table, type(FemSolo)

* At least one female author.
author_level Fem1 using `author', stats(flesch fleschkincaid gunningfog smog dalechall)
author_level_table, type(Fem1)

* Majority female-authored.
author_level Fem50 using `author', stats(flesch fleschkincaid gunningfog smog dalechall)
author_level_table, type(Fem50)

* Senior female author.
author_level FemSenior using `author', stats(flesch fleschkincaid gunningfog smog dalechall)
author_level_table, type(FemSenior)

* Alternative program for calculating readability statistics.
author_level FemRatio using `author', stats(r_fleschkincaid r_gunningfog r_smog)
author_level_table, type(R)
********************************************************************************
