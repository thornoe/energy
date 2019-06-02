////////////////////////////////////////////////////////////////////////////////
////////	0. Global set up 											////////
////////////////////////////////////////////////////////////////////////////////
/*
**** TO RUN DIRECTLY IN THIS DO FILE: SET THE DIRECTORIES AND LOAD THE DATA ****
**** (SAME GLOBALS AS WHEN RUNNING THROUGH MAIN-FILE)						****


*** Global directories, Cathrine ***
cd 				"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\stata"
*global data		"??? \Google Drev\Energy Economics\Data"
global latex	"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\latex\04_tables"
global results	"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\results"


*** Global directories, Thor ***
cd 				"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\stata"
global data		"D:\Google Drev\KU Thor\Energy Economics\Data"
global latex	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\latex\04_tables"
global results	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\results"


*** Load data ***
set scheme s1color

clear all

use "$data/data_stata.dta", clear

xtset grid date, clocktime delta(1 hour) // strongly balanced
*/


////////////////////////////////////////////////////////////////////////////////
////	A. Load and set up the time-series data								////
////////////////////////////////////////////////////////////////////////////////
label variable _e_w "Wholesale electricity consumption, MWh"
label variable _e_hh "Retail electricity consumption, MWh"
label variable _n_w "Number of wholesale meters"
label variable _n_hh "Number of retail meters"
label variable _n_f "- of which flex-settled"
label variable _n_r "- of which residual"
label variable _p "Electricity spot price, DKK/MWh"
label variable wp_DK1 "Wind power prognosis for DK1, GWh"
label variable wp_DK2 "Wind power prognosis for DK2, GWh"
label variable wp_se "Wind power prognosis for Sweden, GWh"
label variable DK1 "Price region DK1 (Western Denmark)"
label variable s_tout "Share time-of-use tariff (Radius only)"
label variable temp "Temperature"
label variable daytime "Daytime"
label variable trend "Time trend"
label variable holy "Holiday (not in a weekend)"


////////////////////////////////////////////////////////////////////////////////
////	B. Descriptive statistics											////
////////////////////////////////////////////////////////////////////////////////
estpost tabstat _* wp_DK1 wp_DK2 wp_se DK1 s_tout temp daytime trend holy ///
	, listwise statistics(mean sd min p25 p50 p75 max) columns(statistics)
esttab using $latex/descriptive.tex, style(tex) delimiter("&") replace ///
	cells("mean sd min p50 max") label nostar nonumbers ///
	stats(N, fmt(%12.0gc) labels("Observations")) ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule\end{tabular}")

xtdescribe

xtsum _* wp_DK1 wp_DK2 wp_se DK1 s_tout temp daytime trend holy
