program encode_replace
	syntax varname [, label(string) *]
		
	tempname `varlist'
	rename `varlist' ``varlist''
	encode ``varlist'', generate(`varlist') `options'
	if "`label'" != "" {
		label values `varlist' `label'
	}
	noisily display "`options'"
end
exit