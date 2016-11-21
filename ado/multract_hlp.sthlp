{smcl}

{* *! version 1.0.0 October 2016}{...}
{title:Title}

{p2colset 6 18 20 2}{...}
{p2col :{cmd:multract} {hline 2}}Extract multiple response options{p_end}


{title:Syntax}

{p 5 17 2}
{cmd:multract} {it:strvarlist} {ifin} [{cmd:, }{it:options}]


{title:Description}

{pstd}{cmd:multract} extracts multiple response option string variables based on the parse character
provided (default is space) and creates a set of dummy variables for each unique value of the underlying
string variable. {cmd:multract} accomodates for the set of missing value options - missing, don't know, 
not applicable, refuse to answer, and other.


{title:Remarks}

{col 5} The following rules apply when using multract:

{p 8 11} 1. Variables can contain multiple parse characters but a single observation must have either 0 or 1 parse characters. {p_end}
{col 8} 2. If the original string variable takes the value of an empty string, the newly created dummies will be missing (.).
{col 8} 3. New dummy variables must not have the same name as a variable already present in the dataset.
{col 8} 4. If a parse character is contained within the other option value it must occur at the beginning of the other option value.
{p 8 11} 5. Observations that contain any missing value option except other (missing, don't know, not applicable, and refuse to answer) must not
contain any other values (no multiple response options). {p_end}


{title:Options}

{col 5}{it: options}{col 36}Description
{col 5}{hline 170}
{col 6}Main options
{p2colset 7 36 37 2}{...}
{p2col : {cmdab:p:arse}{it:(parse_strings)}} parse on specifed strings; default is to parse on spaces {p_end}
{p2col : {cmdab:gen:erate}{it:(stub)}} replace the middle of new variable names with {it:stub}; {it:varname_stub_option}; default is {it:varname_option} {p_end}
{p2col : {cmd: drop}} drops original string variables {p_end}
{p2col : {cmd: varlab}} replace the variable labels of the created dummy variables with that of the original string variable {p_end}


{col 6}Missing value options
{p2colset 7 36 37 2}{...}
{p2col : {cmdab:miss:ing}{it:(string)}}replace newly extracted variables to missing if the original string is coded as the missing value specified {p_end}
{p2col : {cmd:dtknw}{it:(string)}}replace newly extracted variables to don't know if the original string is coded as the don't know value specifed {p_end}
{p2col : {cmd:na}{it:(string)}}replace newly extracted variables to not applicable if the original string is coded as the not applicable value specifeid {p_end}
{p2col : {cmdab:ref:use}{it:(string)}}replace newly extracted variables to refuse to answer if the original string is coded as the refuse to answer value specifed {p_end}
{p2col : {cmdab:oth:er}{it:(string)}}creates a newly extracted "other" dummy variable that takes the value 1 if the original string is coded as the other value specified {p_end}


{col 9}{c TLC}{hline 6}{c TRC}
{col 5}{hline 4}{c BRC}{col 10} Main {c BLC}{hline 158}

{p 5 10}{cmd: parse}{it:(parse_strings)} specifies that, instead of using spaces, variables will be parse using one or more parse strings. Most commonly,
one string that is one punctuation character will be specified. For example, if {cmd:parse(-)} is specified then a multiple response option string 
variable named farm with an observation that takes on the value {bf}"1-2-5" {sf}will be broken into three dummy variables, {bf}farm_1 farm_2 farm_5{sf}
each taking the value 1 for the particular observation.

{p 10 10}The parse option can also accomodate multiple parse characters if multiple observations within a given string variable have more than one 
character that separates multiple response options or if across multiple variables different parse characters are used to separate multiple response 
options. When inputting multiple parse characters, separate the parse characters using spaces. If one of the many parse characters happens to be a
space, include the empty string (" ") as a parse character. For example, {cmd:parse(" " - /)} will split strings separated by a space, a - or / character.

{p 10 10}Note that although a variable can contain multiple parse characters, a given {bf}observation{sf} can only contain a single parse character. 
If this is not the case, {cmd:multract} will display an error message.

{p 5 10}{cmd: generate}{it:(stub)} specifies the middle characters of newly created dummy variables. The naming convention of created dummies 
is: {it:varname_stub_option}. For example, if the variable farm is broken into three dummy variables corresponding to the values 1, 2, and 5, and the
user entered the option, gen{it:(material)}{sf}, then the name of the three created dummies are: {bf}farm_material_1{sf}, {bf}farm_material_2{sf},
and {bf}farm_material_5{sf}.

{p 10 10}If the first character of the {it:stub} is "_", the name of the new dummy will not include two underscore characters after the name of the original string. 
If the first two characters of the {it:stub} are "__", the name of the dummy will include two underscore characters after the name of the original string. If illegal
naming characters are included in the {it:stub}, they will be automatically replaced with an "_".

{p 10 10}If a user did not specify the generate command, the naming syntax is {it:varname_option}.

{p 5 10}{cmd: drop} specifies that {cmd:multract} drop the original string variables included in the {it:varlist}.

{p 5 10}{cmd: varlab} specifies that the variable label attached to the original string variable be transferred to the created multiple response dummy 
variables. The variable label for the dummy variables starts with the value of the newly created dummy variable, followed by a colon, and then the
variable label of the original string.

{col 9}{c TLC}{hline 23}{c TRC}
{col 5}{hline 4}{c BRC}{col 10} Missing Value Options {c BLC}{hline 141}

{p 5 10}{cmd: missing}{it:(string)} specifies the "missing value" response option. All newly created dummy variables for a particular string variable will
take the value of the missing value option if the original string observation is coded as the missing value. This denotes that a particular survey
respondent was missing or unable to be surveyed.

{p 5 10}{cmd: dtknw}{it:(string)} specifies the "don't know" response option. All newly created dummy variables for a particular string variable will take
the value of the don't know value option if the original string observation is coded as the don't know value. This denotest that a particular survey 
respondent did not know the answer to the survey question.

{p 5 10}{cmd: na}{it:(string)} specifies the "not applicable" response option. All newly created dummy variables for a particular string variable will take
the value of the not application value option if the original string observation is coded as the not applicable value. This denotes that the survey question
did not apply to a particular survey respondent.

{p 5 10}{cmd: refuse}{it:(string)} specifies the "refuse to answer" response option. All newly created dummy variables for a particular string variable
will take the value of the refuse to answer value option if the original string observation is coded as the not applicable value. This denotes that a
particular survey respondent refused to answer the survey question. 

{p 5 10}{cmd: other}{it:(string)} specifies the "other" response option. If a variable contains an observation that takes the other value then a 
separate dummy variable will be created taking the value of 1 for that particular observation. All other values for the other newly created dummies for 
that particular observation will remain unchanged. The naming convention for the other variable is: {it:varname_stub_oth}. This denotes that a particular
survey respondent gave an other response to the survey question.

{p 10 10}There are a few rules to consider when using the other option. Consider an example when the parse character is a / and the other option value
is -98. If an observation is coded as "1/2/-98", a dummy for value 1, 2, and oth will be created each taking the value one for the observation. If an 
observaiton is coded as "1/2//-98", a dummy for value 1 and 2 will be created but oth will not. By having two parse characters preceding the other 
option value {cmd:multract} will create a dummy for the value -98 ({it:varname_stub_98}) instead of creating an oth variable.

{p 10 10}Now consider an example when the parse character is a - and the other option value is -98. If an observation is coded as "1-2-98", a dummy for 
value 1, 2, and 98 will be created each taking the value one for the observation (an oth value is {bf:not} created). If an observation is coded as
"1-2--98" an oth value will be created. If an observation is coded as "1-2---98" an oth value will not be created (instead a variable for 98 will be created
({it:varname_stiub_98}). 



{title:Stored results}

{col 5}{cmd:multract} stores the following in {bf}r(){sf}:

{p2colset 7 25 27 2}{...}
{p2col : {bf}r(old_varlist)}{sf}names of original string variables included in {it}varlist{sf}. This stored result is returned only if the option {bf}drop {sf}is not specified. {p_end}
{p2col : {bf}r(new_varlist)}{sf}names of newly created variables {p_end}
{p2col : {bf}r(nvars)}{sf}number of new variables created {p_end}


