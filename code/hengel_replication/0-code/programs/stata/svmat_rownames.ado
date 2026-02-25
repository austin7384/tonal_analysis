program svmat_rownames
	syntax name, generate(namelist min=1 max=2) [clear rowname roweq colnames(string) *]
	
	if "`colnames'" != "" {
		matrix colnames `namelist' = `colnames'
	}
	
	if "`clear'" != "" {
		clear
	}
	
	svmat `type' `namelist', `options'
	
	tempvar rname req
	generate `rname' = ""
	generate `req' = ""
	local rnames : rownames `namelist'
	local reqs : roweq `namelist'
	forvalues i=1/`=_N' {
		replace `rname' = "`: word `i' of `rnames''" in `i'
		replace `req' = "`: word `i' of `reqs''" in `i'
	}
	
	local var1 : word 1 of `generate'
	if "`rowname'" == "" & "`roweq'" != "" {
		rename `req' `var1'
	}
	else {
		rename `rname' `var1'
		if "`roweq'" != "" {
			local var2 : word 2 of `generate'
			rename `req' `var2'
		}
	}
end
exit