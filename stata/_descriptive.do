////////////////////////////////////////////////////////////////////////////////
////////	0. Global set up 											////////
////////////////////////////////////////////////////////////////////////////////
/*
*** SET THE DIRECTORIES FIRST (SAME GLOBALS AS WHEN RUNNING THROUGH MAIN-FILE) ***

set scheme s1color

clear all

use "data_stata", clear

xtset grid date, clocktime delta(1 hour) // strongly balanced


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
label variable _e_w "Wholesale electricity use"
label variable _e_hh "Household electricity use"
label variable _n_w "Number of wholesale meters"
label variable _n_hh "Number of retail meters"
label variable _n_f "- of which flex-settled"
label variable _n_r "- of which residual"
label variable _p "Electricity spot price, DKK"
label variable wp "Wind power prognosis same region, GWh"
label variable wp_other "Wind power prognosis other region, GWh"
label variable wp_se "Wind power prognosis for Sweden, GWh"
label variable DK1 "Price region DK1"
label variable s_tout "Share time-of-use tariff"
label variable temp "Temperature"
label variable daytime "Daytime"
label variable trend "Time trend"
label variable holy "Holiday (not in a weekend)"


////////////////////////////////////////////////////////////////////////////////
////	B. Descriptive statistics											////
////////////////////////////////////////////////////////////////////////////////
estpost tabstat _* wp* DK1 s_tout temp daytime trend holy ///
	, listwise statistics(mean sd min p25 p50 p75 max) columns(statistics)
esttab using $tables/descriptive.tex, style(tex) delimiter("&") replace ///
	cells("mean sd min p50 max") label nostar nonumbers ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")

xtdescribe

xtsum _* wp* DK1 s_tout temp daytime trend holy
