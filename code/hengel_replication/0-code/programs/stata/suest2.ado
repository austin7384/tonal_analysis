program suest2, eclass
	syntax anything, cluster(varlist min=2 max=2)
	
	tempvar group
	egen `group' = group(`cluster')
	
	tokenize `cluster'
	
	tempname V1 V2 V12 V b
	quietly suest `anything', vce(cluster `1')
	matrix `V1' = e(V)
	local N_g1 = e(N_clust)
	
	quietly suest `anything', vce(cluster `2')
	matrix `V2' = e(V)
	local N_g2 = e(N_clust)
	
	quietly suest `anything', vce(cluster `group')
	matrix `V12' = e(V)
	
	matrix `V' = `V1' + `V2' - `V12'
	
	ereturn repost V=`V'
	ereturn local clustvar = "`cluster'"
	ereturn scalar N_g1 = `N_g1'
	ereturn scalar N_g2 = `N_g2'
	
	suest
	
end
exit