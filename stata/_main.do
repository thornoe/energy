****	Install both packages for FEIV	****
/*
findit ivreg210
ssc install xtivreg2, replace
* Reference: https://ideas.repec.org/c/boc/bocode/s456501.html
help xtivreg2
help xtivreg
*/

////////////////////////////////////////////////////////////////////////////////
////////	0. Global set up 											////////
////////////////////////////////////////////////////////////////////////////////
set scheme s1color

clear all

use "data_stata", clear

xtset grid date, clocktime delta(1 hour) // strongly balanced


*** Global variable lists ***
global x_w "n_w temp* trend i.year i.week" // wholesale
global x_hh "n_hh temp* daytime trend i.year i.week" // households
global x_17_19 "i(1 2 3 4 5).day_bd#i(17 18 19).hour i.month#i(17 18 19).hour" // i1.non_bd#i(17 18 19).hour as baseline


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
label variable e_hh "log retail consumption"
label variable DK1 "Price region DK1"
label variable p "log spot price"
label variable wp "Wind power prognosis same region"
label variable wp_other "Wind power prognosis other region"
label variable n_w "log wholesale meters"
label variable n_hh "log retail meters"
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
xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w ///
	o0.day_bd#i.hour i.month#i.hour ///
	if bd==1 & inrange(hour,12,15), re vce(cluster grid) first
estadd scalar cons = _b[_cons]
est store peak, title("Peak: 12-15")

xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1) $x_w  daytime ///
	o0.day_bd#i.hour i.month#i.hour ///
	if bd==1 & inrange(hour,5,11)|inrange(hour,16,23), re vce(cluster grid) first
estadd scalar cons = _b[_cons]
est store shoulder, title("Shoulder")

xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1) $x_w ///
	o0.day_bd#i.hour i.month#i.hour ///
	if bd==1 & inrange(hour,0,4), re vce(cluster grid) first
estadd scalar cons = _b[_cons]
est store off_peak, title("Off-peak: 00-04")

xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1) $x_w daytime ///
	i.hour i.month#i.hour ///
	if non_bd==1, re vce(cluster grid) first
estadd scalar cons = _b[_cons]
est store non_bd, title("Non-business days")

estout _all using "ws_preferred.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc) )
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
		o0.day_bd o12.month ///
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
**** 	Pooled 2SLS for Radius, 17-19 only									****
********************************************************************************
est clear
ivregress 2sls e_hh s_tout (p = wp wp_other) $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar cons = _b[_cons]
est store all, title("All days")

ivregress 2sls e_hh s_tout (p = wp wp_other) $x_hh $x_17_19 ///
	if bd==1 & grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar cons = _b[_cons]
est store bd, title("Business days")

ivregress 2sls e_hh s_tout (p = wp wp_other) $x_hh ///
	i1.non_bd#i(17 18 19).hour i.month#i(17 18 19).hour ///
	if non_bd==1 & grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar cons = _b[_cons]
est store nbd, title("Non-business days")

estout _all using "hh_radius_17-19.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc) )

estout _all using $tables/hh_radius_17-19.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N, labels("Constant" "Observations") fmt(1 %12.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")

	
********************************************************************************
**** 	Pooled 2SLS for Radius, 17-19: Testing endogeneity 					****
********************************************************************************
est clear
* Simple OLS
reg e_hh s_tout p $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar cons = _b[_cons]
est store OLS, title("OLS")

* 1st stage
reg p s_tout wp wp_other $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
predict vhat, residuals
estadd scalar cons = _b[_cons]
est store first, title("1st stage, y = log price")
test wp = wp_other = 0 // F-statistic: 230
// t- and F-test are strongly rejected
// i.e instruments are strongly correlated with price, thus, are relevant

* 2nd stage
ivregress 2sls e_hh s_tout (p = wp wp_other) $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar cons = _b[_cons]
est store second, title("2nd stage")
// Very different from OLS, thus p is likely to be endogenous

* Endogeneity test (Hausman)
reg e_hh s_tout p vhat $x_hh ///
	i(1 2 3 4 5).day_bd#i(17 18 19).hour $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar cons = _b[_cons]
est store endogeneity, title("Endogeneity")
// We reject the t-test that vhat=0, thus p is endogenous and we prefer 2SLS.

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
**** 	Pooled 2SLS for Radius, 17-19: Testing for homoscedasticity			 ****
********************************************************************************
est clear
* OLS w. non-robust s.e.
reg e_hh s_tout p $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19)
* The Breusch-Pagan / Cook-Weisberg test for heteroskedasticity
estat hettest, rhs mtest(bonf)
// The simultaneous test clearly rejects that the variance is constant
// The Bonferroni-adjusted p-values for price and daytime are as low as 0.000
est store non_robust, title("OLS, non-robust s.e.")

* OLS w. robust s.e.
reg e_hh s_tout p $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), robust
est store robust, title("OLS, robust s.e.")

estout _all using "hh_homoscedasticity.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc) )


********************************************************************************
**** 	Pooled 2SLS for Radius, 17-19: Testing overidentifying restrictions ****
********************************************************************************
* test only holds in case of homoscedasticity, however, this assumption doesn't hold
est clear
foreach z of varlist wp wp_other {
ivregress 2sls e_hh s_tout (p = `z') $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
predict uhat, residuals
estadd scalar cons = _b[_cons]
est store iv_`z', title("2SLS, `z' only")
reg uhat s_tout `z' $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar cons = _b[_cons]
est store OLS_`z', title("OLS, y = uhat(`z')")
drop uhat
}
* Both instruments
ivregress 2sls e_hh s_tout (p = wp wp_other) $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
predict uhat, residuals
estadd scalar cons = _b[_cons]
est store iv_both, title("2SLS, both")
reg uhat s_tout wp wp_other $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
estadd scalar nR2 = e(N)*e(r2) // .345
estadd scalar p_value = 1-chi2(1, e(N)*e(r2)) // chi-sq with df=1: p-value: 0.55
// we cannot reject H0: that at least one of wp and wp_other are not exogenous
estadd scalar cons = _b[_cons]
est store OLS_both, title("OLS, y = uhat(both)")
test wp = wp_other = 0 // F-statistic: 0.16, p-value: 0.85
// t- and F-tests cannot be rejected even at high confidence levels
// i.e. both instruments are uncorrelated with uhat, thus are exogenous.
drop uhat

estout _all using "hh_overidentifying.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N nR2 p_value, fmt(%12.0gc 3 3) )
estout _all using $tables/hh_overidentifying.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N nR2 p_value, labels("Constant" "Observations" "n*R2" "p-value") fmt(1 %12.0gc 3 3) ) ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")



********************************************************************************
**** 	Pooled OLS for Radius, all hours									****
********************************************************************************
est clear
/*
ivregress 2sls e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i(1 2 3 4 5).day_bd#i.hour i1.non_bd#i.hour i.week i.year ///
	if grid==791, vce(robust)
*/
estadd scalar cons = _b[_cons]
est store all, title("All days")

/*
ivregress 2sls e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i(1 2 3 4 5).day_bd#i.hour i.week i.year ///
	if bd==1 & grid==791, vce(robust)
*/
estadd scalar cons = _b[_cons]
est store bd, title("Business days")

/*
ivregress 2sls e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i.day#i.hour i.week i.year ///
	if non_bd==1 & grid==791, vce(robust)
*/
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
/*
xtivreg e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i(1 2 3 4 5).day_bd#i.hour i1.non_bd#i.hour i.week i.year ///
	, fe vce(cluster grid)
*/
estadd scalar cons = _b[_cons]
est store all, title("All days")

/*
xtivreg e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i(1 2 3 4 5).day_bd#i.hour i.week i.year ///
	if bd==1, fe vce(cluster grid)
*/
estadd scalar cons = _b[_cons]
est store bd, title("Business days")

/*
xtivreg e_hh (p = wp wp_other) s_tout n_hh trend temp* daytime ///
	i.month#i.hour i1.non_bd#i.hour i.week i.month i.year ///
	if non_bd==1, fe vce(cluster grid)
*/
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

	
	
	
	

