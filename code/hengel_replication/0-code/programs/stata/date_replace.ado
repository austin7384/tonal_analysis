program date_replace
	syntax varname, mask(string)
	
	tempname `varlist'
	rename `varlist' ``varlist''
	generate `varlist' = date(``varlist'', "`mask'")
	format `varlist' %td
	
end
exit