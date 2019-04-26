////////////////////////////////////////////////////////////////////////////////
////////	0. Global set up 											////////
////////////////////////////////////////////////////////////////////////////////
/*

*** SET THE DIRECTORIES FIRST (SAME GLOBALS AS WHEN RUNNING THROUGH MAIN-FILE) ***

*** Global directories, Thor ***
cd 				"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\stata"
global figures	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\latex\03_figures"
global tables	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\latex\04_tables"

*** Global directories, Cathrine ***
cd 				"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\stata"
global figures	"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\latex\03_figures"
global tables	"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\latex\04_tables"
*/


////////////////////////////////////////////////////////////////////////////////
////	A. Load and set up the time-series data								////
////////////////////////////////////////////////////////////////////////////////
use "data_descriptive", clear

xtset grid date, clocktime delta(1 hour) // strongly balanced

label variable e_w "Wholesale electricity use"
label variable e_hh "Household electricity use"
label variable p "Electricity spot price"
label variable wp "Wind power prognosis same region"
label variable wp "Wind power prognosis other region"
label variable n_w "Wholesale meters"
label variable n_hh "Household meters"
label variable trend "Time trend"
label variable temp "Temperature"
label variable temp_sq "Temperature squared"
label variable daytime "Daytime"
label variable s_tout "Time-of-Use tariff"

*xtdescribe

////////////////////////////////////////////////////////////////////////////////
////	B. Descriptive statistics											////
////////////////////////////////////////////////////////////////////////////////
estpost tabstat e_w e_hh p wp wp_other n_w n_hh trend temp temp_sq daytime s_tout ///
	, listwise statistics(mean sd min p25 p50 p75 max) columns(statistics)
esttab using $tables/descriptive.tex, style(tex) delimiter("&") replace ///
	cells("mean sd min p25 p50 p75 max") label nostar nonumbers ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")
