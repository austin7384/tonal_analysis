program ereturn_post
	syntax anything [, obs(integer 0) dof(integer 0) se(name) store(name) colnames(string) local(string) scalar(string) matrix(string)]
	
	local first : word 1 of `anything'
	if `"`first'"'=="e(b)"|`"`first'"'=="matrix" {
		local count : word count `anything'
		
		tempname b
		matrix `b' = e(b)
		local anything `b'
		
		if `count' > 1 {
			tempname V
			matrix `V' = e(V)
			local anything `b' `V'
		}
	}
	
	local coefs : word 1 of `"`anything'"'
	local var : word 2 of `"`anything'"'
	if `"`coefs'"'=="e(b)"|`"`coefs'"'==`"matrix"' {
		tempname b
		matrix `b' = e(b)
		
	}
	
	if "`colnames'" != "" {
		foreach name in `anything' {
			matrix colnames `name' = `colnames'
		}
		if "`se'" != "" {
			matrix colnames `se' = `colnames'
		}
	}
	
	if `obs' {
		if `dof' {
			ereturn post `anything', obs(`obs') dof(`dof')
		}
		else {
			ereturn post `anything', obs(`obs')
		}
	}
	else {
		ereturn post `anything'
	}
	
	if "`se'" != "" {
		estadd matrix se = `se'
	}
	
	parse_addons `local', local
	parse_addons `scalar', scalar
	parse_addons `matrix', matrix colnames(`colnames')
	
	
	if "`store'" != "" {
		eststo `store'
	}
	
end

program parse_addons
	syntax [anything], [local scalar matrix colnames(string)]
	if "`anything'" != "" {
		
		local n : word count `anything'
		forvalues i=1/`=`n'/2' {
			local j = `i' * 2 - 1

			local name : word `j++' of `anything'
			local value : word `j' of `anything'
			
			if "`local'" != "" {
				estadd local `name' = `"`value'"'
			}
			else if "`scalar'" != "" {
				estadd scalar `name' = `value'
			}
			else if "`matrix'" != "" {
				* If adding a matrix, it must be in the form name value.
				* E.g., If to save the (existing) matrix A as e(A) in the estimation results: matrix(A A).
				if "`colnames'" != "" {
					matrix colnames `value' = `colnames'
				}
				estadd matrix `name' = `value'
			}
		}
	}
end
exit
