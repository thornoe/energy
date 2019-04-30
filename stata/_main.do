****	Install both packages	****
findit ivreg210
ssc install xtivreg2, replace
* Reference: https://ideas.repec.org/c/boc/bocode/s456501.html
help xtivreg2
help xtivreg

////////////////////////////////////////////////////////////////////////////////
////////	0. Global set up 											////////
////////////////////////////////////////////////////////////////////////////////
set scheme s1color

clear all

use "data_stata", clear

xtset grid date, clocktime delta(1 hour) // strongly balanced


*** Global variable lists ***
global x_w "n_w temp* daytime trend i.year i.week" // wholesale
global x_hh "n_hh temp* daytime trend i.year i.week" // households

*** Global directories, Thor ***
cd 				"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\stata"
global figures	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\latex\03_figures"
global tables	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\latex\04_tables"


*** Global directories, Cathrine ***
cd 				"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\stata"
global figures	"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\latex\03_figures"
global tables	"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\latex\04_tables"



////////////////////////////////////////////////////////////////////////////////
////	1. Descriptive statistics											////
////////////////////////////////////////////////////////////////////////////////
do "_descriptive" // reload data before running

/*	overall: Pooled mean, std.dev., var, min and max
	between: Cross-section std.dev. and var (not mean, min. or max!)
			 Permanent differences between grids
			 (dif. between the overtime-means for each grid)
	within:	 Time series std.dev. and var (not mean, min. or max!)
			 Differences across time within each grid
			 e.g. time-of-day & day-of-week deviations, business cycles or trend
*/

////////////////////////////////////////////////////////////////////////////////
////	2. Load and set up data for regressions								////
////////////////////////////////////////////////////////////////////////////////
drop n_f n_r holy _*


label variable e_w "log wholesale consumption"
label variable e_hh "log household consumption"
label variable DK1 "Price region DK1"
label variable p "log spot price"
label variable wp "Wind power prognosis same region"
label variable wp_other "Wind power prognosis other region"
label variable n_w "log wholesale meters"
label variable n_hh "log household meters"
label variable trend "Time trend"
label variable temp "Temperature"
label variable temp_sq "Temperature squared"
label variable daytime "Daytime"
label variable temp "Temperature"
label variable daytime "Daytime"
label variable s_tout "Time-of-use tariff"

*xtdescribe


////////////////////////////////////////////////////////////////////////////////
////	3. Regressions for Wholesale		 								////
////////////////////////////////////////////////////////////////////////////////

********************************************************************************
**** 	Preferred specifications											****
********************************************************************************
est clear
xtivreg e_w (p = wp wp_other) $x_w ///
	o0.day_bd#i.hour i.month#i.hour ///
	if bd==1 & inrange(hour,12,15), fe vce(cluster grid)
estadd scalar cons = _b[_cons]
est store peak, title("Peak: 12-15")

estout _all using "ws_preferred.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )

estout _all using $tables/ws_preferred.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N, labels("Constant" "Observations") fmt(1 %12.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")

* how to show estimation method and instruments? (first stage)

********************************************************************************
**** 	Elasticity for each hour (business days joint)						****
********************************************************************************
est clear
foreach h of numlist 0/23 {
	xtivreg e_w (p = wp wp_other) $x_w ///
		o0.day_bd i.month ///
		if bd==1 & hour==`h', fe vce(cluster grid)
	est store bd_h_`h'
}
estout _all using "ws_bd-hour.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )


********************************************************************************
**** 	Elasticity for each single hour-day combination						****
********************************************************************************
est clear
foreach d of numlist 1/5 {
	est clear
	foreach h of numlist 0/23 {
		xtivreg e_w (p = wp wp_other) $x_w ///
			i.hour i.month ///
			if day_bd==`d' & hour==`h', fe vce(cluster grid)
		est store bd_`d'_h_`h'
	}
	estout _all using "ws_bd`d'-hour.xls", replace ///
		label cells( b(star fmt(5)) se(par fmt(5)) ) ///
		starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
		stats(N, fmt(1 %12.0gc) )
}
est clear
foreach h of numlist 0/23 {
	xtivreg e_w (p = wp wp_other) $x_w ///
		i.hour i.month ///
		if non_bd==1 & hour==`h', fe vce(cluster grid)
	est store nbd_h_`h'
}
estout _all using "ws_non-bd-hour.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )


*****	BACK TO WHOLESALE AGAIN!
********************************************************************************
**** 	Trying Differenct peak periods										****
********************************************************************************
est clear
foreach a of numlist 7/12 {
	foreach b of numlist 12/18 {
		xtivreg e_w (p = wp wp_other) $x ///
			o0.day_bd#i.hour i.month#i.hour ///
			if bd==1 & inrange(hour,`a',`b'), fe vce(cluster grid)
		est store bd_`a'_to_`b'
}
}
estout _all using "ws_peaks-comparison.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )


********************************************************************************
**** 	Trying Differenct shoulder periods									****
********************************************************************************
est clear
foreach a of numlist 7/12 {
	foreach b of numlist 12/18 {
		xtivreg e_w (p = wp wp_other) $x ///
			o0.day_bd#i.hour i.month#i.hour ///
			if bd==1 & inrange(hour,`a',`b'), fe vce(cluster grid)
		est store bd_`a'_to_`b'
}
}
estout _all using "ws_different-shoulders.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )

	
********************************************************************************
**** 	FE, RE, FEIV, REIV comparison										****
********************************************************************************
xtreg e_w p n_w days temp* dt i.h_* i.d_* i.week i.month i.year ///
	if bd==1 & inrange(hour,12,15), re vce(cluster grid)
estadd scalar cons = _b[_cons]
est store re, title("RE")

xtreg e_w p n_w days temp* dt i.hour_* i.week i.month i.year ///
	if bd==1 & inrange(hour,12,15), fe vce(cluster grid)
estadd scalar cons = _b[_cons]
est store fe, title("FE")

xtivreg e_w (p = wp wp_other) n_w days temp* dt i.h_* i.d_* i.week i.month i.year ///
	if bd==1 & inrange(hour,8,13), re vce(cluster grid) first
estadd scalar cons = _b[_cons]
est store reiv, title("REIV")

xtivreg e_w (p = wp wp_other) n_w days temp* dt i.h_* d_* i.week i.month i.year ///
	if bd==1 & inrange(hour,8,13), fe vce(cluster grid) first
estadd scalar cons = _b[_cons]
est store feiv, title("FEIV")

estout re fe reiv feiv, ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )

estout re fe reiv feiv using "ws_fe-re-feiv-reiv-comparison.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )




////////////////////////////////////////////////////////////////////////////////
////	4. Regressions for households and small companies		 			////
////////////////////////////////////////////////////////////////////////////////

********************************************************************************
**** 	Pooled OLS for Radius, 17-19 only									****
********************************************************************************
est clear
ivregress 2sls e_hh (p = wp wp_other) s_tout $x_hh ///
	i.month#i(17 18 19).hour ///
	i(1 2 3 4 5).day_bd#i(17 18 19).hour ///
	i1.non_bd#i(17 18 19).hour ///
	if grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar cons = _b[_cons]
est store all, title("All days")

ivregress 2sls e_hh (p = wp wp_other) s_tout $x_hh ///
	i.month#i(17 18 19).hour ///
	i(1 2 3 4 5).day_bd#i(17 18 19).hour ///
	if bd==1 & grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar cons = _b[_cons]
est store bd, title("Business days")

ivregress 2sls e_hh (p = wp wp_other) s_tout $x_hh ///
	i.month#i(17 18 19).hour ///
	i1.non_bd#i(17 18 19).hour ///
	if non_bd==1 & grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar cons = _b[_cons]
est store nbd, title("Non-business days")

estout _all using "hh_radius_17-19.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )

estout _all using $tables/hh_radius_17-19.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N, labels("Constant" "Observations") fmt(1 %12.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")

	
********************************************************************************
**** 	Pooled OLS for Radius, 17-19: Overidentification tests				****
********************************************************************************
est clear
reg p wp wp_other s_tout $x_hh ///
	i(1 2 3 4 5).day_bd#i(17 18 19).hour ///
	i1.non_bd#i(17 18 19).hour ///
	i.month#i(17 18 19).hour ///
	if grid==791 & inrange(hour,17,19), vce(robust)
predict vhat, residuals
estadd scalar cons = _b[_cons]
est store first, title("1st stage, y = log price")

ivregress 2sls e_hh (p = wp wp_other) s_tout $x_hh ///
	i(1 2 3 4 5).day_bd#i(17 18 19).hour ///
	i1.non_bd#i(17 18 19).hour ///
	i.month#i(17 18 19).hour ///
	if grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar cons = _b[_cons]
est store second, title("2nd stage")

reg e_hh p vhat s_tout $x_hh ///
	i(1 2 3 4 5).day_bd#i(17 18 19).hour ///
	i1.non_bd#i(17 18 19).hour ///
	i.month#i(17 18 19).hour ///
	if grid==791 & inrange(hour,17,19), vce(robust) first
estadd scalar cons = _b[_cons]
est store endogeneity, title("Endogeneity test")

estout _all using "hh_endogeneity.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )
estout _all using $tables/hh_endogeneity.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N, labels("Constant" "Observations") fmt(1 %12.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")
drop vhat



********************************************************************************
**** 	Pooled OLS for Radius, all hours, interaction with month			****
********************************************************************************
est clear
ivregress 2sls e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i(1 2 3 4 5).day_bd#i.hour i1.non_bd#i.hour i.week i.year ///
	if grid==791, vce(robust)
estadd scalar cons = _b[_cons]
est store all, title("All days")

ivregress 2sls e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i(1 2 3 4 5).day_bd#i.hour i.week i.year ///
	if bd==1 & grid==791, vce(robust)
estadd scalar cons = _b[_cons]
est store bd, title("Business days")

ivregress 2sls e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i.day#i.hour i.week i.year ///
	if non_bd==1 & grid==791, vce(robust)
estadd scalar cons = _b[_cons]
est store nbd, title("Non-business days")

estout _all using "hh_radius.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )

estout _all using $tables/hh_radius.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N, labels("Constant" "Observations") fmt(1 %12.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")


********************************************************************************
**** 	All grid companies													****
********************************************************************************
est clear
xtivreg e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i(1 2 3 4 5).day_bd#i.hour i1.non_bd#i.hour i.week i.year ///
	, fe vce(cluster grid)
estadd scalar cons = _b[_cons]
est store all, title("All days")

xtivreg e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i(1 2 3 4 5).day_bd#i.hour i.week i.year ///
	if bd==1, fe vce(cluster grid)
estadd scalar cons = _b[_cons]
est store bd, title("Business days")

xtivreg e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i1.non_bd#i.hour i.week i.month i.year ///
	if non_bd==1, fe vce(cluster grid)
estadd scalar cons = _b[_cons]
est store nbd, title("Non-business days")

estout _all using "hh_all.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )

estout _all using $tables/hh_all.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N, labels("Constant" "Observations") fmt(1 %12.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")

	
	
	
	

