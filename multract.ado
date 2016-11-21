*! version 1.0.0 Qayam Jetha - Nov, 2016

program multract, rclass

	/* 	Extracts multiple response option strings ("select all that
		apply survey questions") based on the parse character(s) 
		provided and creates a set of dummy variables for each unique value.
	*/
	
	version 14.2
	
	#d ;
	
	syntax [varlist(str)] [if] [in], 
	
	/* parse character(s) */
	[Parse(string asis)]
	
	/* generate prefix - new variables name structure: "varname_generate_option" */
	[GENerate(str)]
	
	/* whether to drop the original string variables  */
	[drop]
	
	/* whether to add variable labels */
	[varlab]
		
	/* values for missings (missing, dont know, other, not applicable, refuse to answer) */
	[MISSing(string) dtknw(string) OTHer(string) na(string) REFuse(string)] ;
		
	#d cr
	
	
	quietly {
	
	
	*Deciding what to parse - if parse isn't specified default is space
		if `"`parse'"' == `""' {
			local parse `"" ""'
		}
	
	
	*Observations to use
		marksample touse, strok novarlist
		quietly count if `touse'
		
		if r(N) == 0 {
			error 2000
		}
		
	
	*If generate is specified, including a "_" prefix to conform to the naming convention (varname_prefix_option)
		if (`"`generate'"' != `""') & (substr(`"`generate'"', 1, 1) != "_") {
			local generate "_`generate'"
		}
		
	
	*Creating a parse list
		foreach x of local parse {
			local list `"`list'", "`x'"'
		}
	
		local list `"`list'""'
		local list : subinstr local list `"","' " "
	
	
	*Subroutine (1) - Checking whether a parse value is contained within the other option
		parse_prob `"`parse'"' `"`other'"'
		local p_prob = r(parse_prob)
		
	
	*Subroutine (2) - If a parse character is contained within the special values, ensures that it occurs at the beginning of the special value 
		no_middle `"`parse'"' `"`missing'"' `"`dtknw'"' `"`other'"' `"`na'"' `"`refuse'"'
				
	
	*Subroutine (3) - Ensuring that values that contain missings (miss, dtknw, ref, na) do not contain any other values - no multiple response options
		noval_miss `"`list'"' `"`varlist'"' `"`missing'"' `"`dtknw'"' `"`na'"' `"`refuse'"' `touse'
	
			
	*Subroutine (4) - Ensuring that observations within varlist do not have multiple parse characters
		no_multiple `"`varlist'"' `"`parse'"' `"`other'"' `p_prob' `touse'
	
		
	/* 	Main Nested Loop Structure:
			(1) Looping through varlist
			(2) Looping through parse characters
			(3) Looping through split variables
			(4) Looping through each value
	*/
	
	
	*Looping through each variable that needs to be extracted
		foreach name of local varlist {
		
		local newvars_var
		
		*Looping through each parse character
			foreach pchar in `parse' {
			
			*Splitting the variable on the parse character
				tempname split_vars
				split `name' if `touse', parse(`"`pchar'"') gen(`split_vars')
				
				local parsing `r(varlist)'

			*Looping through each parse character
				foreach var of local parsing {
					
					levelsof `var' if `touse', local(options)
					
				*Looping through each value of the split variable
					foreach opt of local options {
					
					*Defining Locals
						local name_opt = strtrim(stritrim(strtoname(`"`name'`generate'_`opt'"'), 0))
						
						
						/* 5 types of values to consider: 
							(1) values that contain a different parse character 			- Do not gen new variable 
							(2) legitimate values that need to be created					- Gen new variable
							(3) "other" values that need their own oth variable				- Gen new variable
							(4) "other values" that need their own value variable			- Gen new variable
							(4) special chars ("dtknw", "na", "ref" - but no "oth")			- Replace values across new variables to the missing value 
							(5) erroneously created special character variables				- Drop new variables
						*/

						
					*Type (1) - Skip
						local count_1 = 0
						
						foreach pchar1 in `parse' {
							local skip = strpos("`opt'", "`pchar1'") > 0
							local count_1 = `count_1' + `skip'
						}
						
						
					*Type (2) - Generate
						cap assert !inlist("`opt'", "`missing'", "`dtknw'", "`na'", "`other'", "`refuse'")
						
						if (_rc == 0) & (`count_1' == 0) {
						
						*Subroutine (5) - Checking to see whether new variable is in original dataset
							new_var `"`name_opt'"' `"`newvars_var'"'
							
						*If satisfy check - create new variable
							cap gen byte `name_opt' = .
							replace `name_opt' = 1 if `var'==`"`opt'"' & `touse'
							
							local newvars_var `newvars_var' `name_opt'
						}
					}
				}
			}
						
						
		*Type (3) - Generate
			if (`"`other'"' != `""') {
			
			local namegen_oth = (strtoname(`"`name'`generate'_oth"'), 0)

			*Subroutine (5) - Checking to see whether other variable is in original dataset
				new_var `"`namegen_oth'"' `"`newvars_var'"'
							
			*If satisfy check - create new variable
				cap gen byte `namegen_oth' = .
				local newvars_var `newvars_var' `namegen_oth'
						
			*Subroutine (6) - Identifying "true" other values
				identification `"`other'"' `"`namegen_oth'"' `"`name'"' `"`list'"' `touse'
									
				local newvars_var `newvars_var' `namegen_oth'
						
						
		*Type (4) - Generate				
			*Generating an other value variable
				local prefix = strtoname("`name'`generate'", 0)
				local suffix = strtoname("`other'", 0)

				if substr("`suffix'", 1, 1) != "_" {
					local suffix = "_`suffix'"
				}
				
				local namegen_oth_value = "`prefix'`suffix'"

			*Subroutine (5) - Checking to see whether other value variable is in original dataset
				new_var `"`namegen_oth_value'"' `"`newvars_var'"'
						
			*If satisfy check - create new variable
				capture gen byte `namegen_oth_value' = .
				replace `namegen_oth_value' = .
				
				if `p_prob' == 0 {
				*Subroutine (7) - Running program for correction of other value variable
					identification_1 `"`other'"' `"`namegen_oth_value'"' `"`name'"' `"`list'"' `touse'
				}
	
				if `p_prob' !=0 {
				*Subroutine (8) - Running program for correction of other value variable
					identification_2 `"`other'"' `"`namegen_oth_value'"' `"`name'"' `"`list'"' `touse' 
				}

				local newvars_var `newvars_var' `namegen_oth_value'

			}
			
		
		*Defining locals
			local newvars_var : list uniq newvars_var
			local newvars_var : list sort newvars_var
			local newvars_`name' `newvars_var'
			local numvars_var : list sizeof newvars_var
			local newvars_tot `newvars_tot' `newvars_var'
			local numvars_tot = `numvars_tot' + `numvars_var'
			
			
		*Type (5) - Replace
			foreach missingval in `missing' `dtknw' `na' `refuse' {
				foreach newvar of local newvars_var {
					replace `newvar' = `missingval' if `name' == "`missingval'" & `touse'
					replace `newvar' = . if `name' == ""
				}
			}
			
			
		*Ordering multi-response variables
			order `newvars_var', after(`name') seq
	
	
		*Replacing missings with zeroes
			foreach newvar of local newvars_var {
				replace `newvar' = 0 if `newvar'==. & `name'!="" & `touse'
			}
			
		*Adding variable labels if option specified 
			if `"`varlab'"' == "varlab" {
			
				local var_lab : variable label `name'
	
				foreach newvar of local newvars_var {
					local pos = subinstr(`"`newvar'"', strtoname("`name'`generate'_"), "", 1)
					label variable `newvar' "`pos':`var_lab'"
				}
			}
								
		}
		

	*Type (6) - Drop
		foreach newvar of local newvars_tot {
			count if `newvar' == 1
			if r(N) == 0 {
				drop `newvar'
				local droppedvars `droppedvars' `newvar'
				local numvars_tot = `numvars_tot' - 1
				
				foreach name of local varlist {
					local newvars_`name' : list newvars_`name' - droppedvars
				}
			}
		}
	
		local newvars_tot : list newvars_tot - droppedvars
	
	
	*Dropping original strings if "drop" option specified
		if `"`drop'"' == "drop" {
			drop `varlist'
		}
		
		
	*Creating returned output
		return local nvars `numvars_tot'
		return local new_varlist "`newvars_tot'"
		
		if `"`drop'"' != "drop" {
			return local old_varlist "`varlist'"
		}

		
	*Displaying output
		noisily display _newline
		noisily display as text _column(4) "{sf}variable" 						///
								_column(15) "{c |}"								///
								_column(20) "created dummy variables" _newline	///
								"{hline 14}{c +}{hline 72}"
		
		foreach n of local varlist {
												
			local w_count : word count `newvars_`n''
			local wordnum = 1
			
			*6 varnames on each line. Each varname is abbreviated to 10 chars.
			while `wordnum' < `w_count' {
				if `wordnum' == 1 { 
					
					forvalues six = 1 / 6 {
						local word`six' : word `six' of `newvars_`n''
					}
					
					noisily display as text _column(4) abbrev("`n'", 11) _column(15) "{c |}" _column(18) 							///
											%-12s abbrev("`word1'", 10) %-12s abbrev("`word2'", 10) %-12s abbrev("`word3'", 10) 	///
											%-12s abbrev("`word4'", 10) %-12s abbrev("`word5'", 10) %-12s abbrev("`word6'", 10)
				}
					
				if `wordnum' !=1 {
					local start = `wordnum'
					local end = `wordnum' + 5
						
					forvalues six = `start'/`end' {
						local mod = mod(`six', 6)
						local word`mod' : word `six' of `newvars_`n''
					}
						
					noisily display as text _column(15) "{c |}" _column(18)															///
											%-12s abbrev("`word1'", 10) %-12s abbrev("`word2'", 10) %-12s abbrev("`word3'", 10) 	///
											%-12s abbrev("`word4'", 10) %-12s abbrev("`word5'", 10) %-12s abbrev("`word0'", 10)
				}

				local wordnum = `wordnum' + 6
			}
			
			noisily display "{hline 14}{c +}{hline 72}"
		}
						
	}


end



/// Subroutines:

* (1) Checking whether a parse value is contained within the other option
program parse_prob, rclass
	args parse other
	
	local parse_prob = 0
		foreach num in `parse' {
			local char = strpos("`other'", "`num'") 
			local p_prob = `p_prob' + `char'
		}

	return local parse_prob "`p_prob'"

end



* (2) Ensuring that if a parse character is contained within the other option that it occurs at the beginning of the other option
program no_middle
	args parse miss dtknw other na ref 
	
	foreach num in `parse' {
		foreach special in miss dtknw other na ref {
			local char = strpos("``special''", "`num'")
			local char1 = strrpos("``special''", "`num'")
				
			if (!inlist(`char', 0, 1)) | (!inlist(`char1', 0, 1)) {
				noisily display as error "special value {bf}``special''{sf} can only contain one parse character "		///
										 "at the beginning of the option"
				exit 9
			}
		}
	}

end



* (3) Ensuring that values that contain missings (miss, dtknw, ref, na) do not contain any other values - no multiple response options
program noval_miss
	args list varlist missing dtknw na refuse touse
	
	foreach missingval in missing dtknw na refuse {
		if `"``missingval''"' == `""' {
			continue
		}
		
		else {
			foreach name of local varlist {
				
				local start = 1
				local end = strlen(`"``missingval''"')
				local go = 0
	
				while `go' == 0 {
				
				*Checking to see if any observation with: (nothing | parse char) + missingval + parse char
					count if substr(`name', `start', `end') == `"``missingval''"' & inlist(substr(`name',`start'+`end', 1), `list') & 			///
					inlist(substr(`name', `start'-1, 1), "", `list') & `touse'
					
					local check = r(N)
					
				*Checking to see if any observation with: parse char + missingval + (nothing | parse char)
					count if substr(`name', `start', `end') == `"``missingval''"' & inlist(substr(`name', `start'+`end', 1), "", `list') & 		///
					inlist(substr(`name', `start'-1, 1), `list') & `touse'
					
					local check = `check' + r(N)
										
					if `check'!=0 {
						noisily display as error "{bf}`name'{sf} contains at least one observation with a " ///
												 "{bf}`missingval' {sf}value plus other parse characters. " _newline ///
												 `"{bf}Observations with "``missingval''" values must not include "' ///
												 "other parse characters."
						exit 9
					}
					
					local ++start
		
					count if substr(`name', `start'+1, 1) != ""
					if r(N) == 0 {
						local go = 1
					}
				}
			}
		}
	}

end



* (4) Ensuring that observations within varlist do not have multiple parse characters
program no_multiple
	args varlist parse other p_prob touse

	foreach name of local varlist {
		tempvar count
		gen `count' = 0

		foreach num of local parse {
			replace `count' = `count' + 1 if strpos(`name', `"`num'"') > 0 & `touse'
		}
				
		if `p_prob' !=0 {
			replace `count' = `count' - 1 if strlen("`other'") == strlen(`name') & strpos(`name', "`other'") > 0 & `touse'

			foreach num of local parse {
				replace `count' = `count' - 1 if strpos(`name', "`num'`other'") > 0  & strpos(`name', "`num'`num'`other'") == 0 ///
				& (strpos(`name', substr("`other'", 1, 1)) == strrpos(`name', substr("`other'", 1, 1))) & `touse'
				
				replace `count' = `count'- 1 if strpos(`name', "`other'") == 1 & strpos(`name', "`other'`num'")!=0 ///
				& (strpos(`name', substr("`other'", 1, 1)) == strrpos(`name', substr("`other'", 1, 1))) & `touse'
			}
		}
	
		capture assert inlist(`count', 0, 1)
		if _rc !=0 {
			local myrc = _rc
			noisily display as error "{bf}`name' {sf}contains at least one observation with multiple parse characters. "  ///
									 "Observations must contain only 1 parse character."
			exit `myrc'
		}
	}
	
end



* (5) Checking to see whether new variable is not already in dataset
program new_var
	args name_opt newvars_var

	local check : list name_opt in newvars_var
	if `check' == 0 {
		cap confirm new variable `name_opt'
		
		if _rc != 0 {
			di as err "variable name {bf}`name_opt' {sf}already exists" 
			exit _rc
		}
	}
	
end



* (6) - Identifying "true" other values
program identification
	args other namegen_oth name list touse
	
	local start = 1
	local end = strlen(`"`other'"')
	local go = 0
	
	while `go' == 0 {
	
	*Other variable to 1 if = (other + parse_char or "") & occurs at the string index = 1
		replace `namegen_oth' = 1 if substr(`name', `start', `end') == `"`other'"' & inlist(substr(`name', (`start'+`end'), 1), "", `list')	///
		& `start'==1 & `touse'
	
	*Other variable to 1 if = (parse_char + other + parse_char or "") & != (parse_char + parse_char + other + parse_char)
		replace `namegen_oth' = 1 if inlist(substr(`name', `start'-1, 1), `list') & substr(`name', `start', `end') == `"`other'"' 			///
		& inlist(substr(`name', `start'+`end', 1), "", `list') & !inlist(substr(`name', `start'-2, 1), `list') & !inlist(`start', 0, 1, 2) &`touse'
			
		local ++start
		
		count if substr(`name', `start'+1, 1) != ""
		if r(N) == 0 {
			local go = 1
		}
	}

end



* (7) Running program for correction of other value variable (p_prob == 0)
program identification_1
	args other namegen_oth_value name list touse
	
	local start = 1 
	local end = strlen(`"`other'"')
	local end1 = strlen(subinstr(strtoname(`"`other'"', 0), "_", "", 1))
	local go = 0

	while `go' == 0 {
	
	*Other value variable to 1 if = (parse_char + parse_char + other + parse_char or "")
		replace `namegen_oth_value' = 1 if inlist(substr(`name', `start'-1, 1), `list') & inlist(substr(`name', `start'-2, 1), `list')		///
		& substr(`name', `start', `end') == `"`other'"' & inlist(substr(`name', `start'+`end', 1), "", `list')
		
	*Other value variable to 1 if = (parse_char + other + parse_char or "") & occurs at the string index = 1
		replace `namegen_oth_value' = 1 if inlist(substr(`name', `start'-1, 1), `list') & substr(`name', `start', `end') == `"`other'"'		///
		& `start'==2 & inlist(substr(`name', `start'+`end', 1), "", `list') & `touse'
		
	*Other value variable to 1 if other is not amenable to a string name (-98) and original string = the strtoname of the other value (98)
		if strtoname(`"`other'"', 0) != `"`other'"' {
			replace `namegen_oth_value' = 1 if inlist(substr(`name', `start'-1, 1), "", `list')												///
			& substr(`name', `start', `end1') == subinstr(strtoname(`"`other'"', 0), "_", "", 1) 											///
			& inlist(substr(`name', `start'+`end1', 1), "", `list') & `touse'
		}
		
		local ++start
		
		count if substr(`name', `start'+1, 1) != ""
		if r(N) == 0 {
			local go = 1
		}
	}

end



* (8) Running program for correction of other value variable (p_prob != 0)
program identification_2
	args other namegen_oth_value name list touse

	local start = 1
	local end = strlen("`other'")
	local go = 0
		
	while `go' == 0 {
		
	*Other value variable to 1 if = (!parse_char + other + parse_char or "") & not at string index == 1
		replace `namegen_oth_value' = 1 if !inlist(substr(`name', `start'-1, 1), "", `list') & substr(`name', `start', `end') == `"`other'"'	///
		& inlist(substr(`name', `start'+`end', 1), "", `list') & `touse'

	*Other value variable to 1 if = (parse_char + parse_char + other + parse_char or "")
		replace `namegen_oth_value' = 1 if inlist(substr(`name', `start'-1, 1), `list') & inlist(substr(`name', `start'-2, 1), `list') 			///
		& substr(`name', `start', `end') == `"`other'"' & inlist(substr(`name', `start'+`end', 1), "", `list') & `touse'
	
	*Other value variable to 1 if = (parse_char + other + parse_char or "") & (parse_char + other) occurs at the string index = 1
		replace `namegen_oth_value' = 1 if inlist(substr(`name', `start'-1, 1), `list') & substr(`name', `start', `end') == `"`other'"'			///
		& `start'==2 & inlist(substr(`name', `start'+`end', 1), "", `list') & `touse'
	
	*Other value variable to 1 if = other value minus the parse character
		replace `namegen_oth_value' = 1 if substr(`name', `start', `end'-1) == subinstr(`"`other'"', substr(`"`other'"', 1, 1), "", 1)==1		///
		& inlist(substr(`name', `start'-1, 1), "", `list') & substr(`name', `start'-1, 1)!=substr(`"`other'"', 1, 1)							///
		& inlist(substr(`name', (`start'+`end'-1), 1), "", `list') & `touse'
			
		local ++start
		
		count if substr(`name', `start'+1, 1)!= ""
		if r(N) == 0 {
			local go = 1
		}
	}

end


