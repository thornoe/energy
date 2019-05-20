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


*** Global variable lists ***
* Wholesale:
global x_w "n_w temp* trend i.year i.week" // without daytime)
* Retail:
global x_hh "n_hh temp* daytime trend i.year i.week"
* Using pooled 2SLS (P2SLS) for the relevant hours ('omit' doesn't work):
global x_11_15 "i(1 2 3 4).day_bd#i(11 12 13 14 15).hour i.month#i(11 12 13 14 15).hour" // baseline: i5.non_bd#i(11 12 13 14 15).hour
global x_17_19 "i(1 2 3 4 5).day_bd#i(17 18 19).hour i.month#i(17 18 19).hour" // baseline: i1.non_bd#i(17 18 19).hour


*** Load data ***
set scheme s1color

clear all

use "$data/data_stata.dta", clear

xtset grid date, clocktime delta(1 hour) // strongly balanced


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
drop n_f n_r holy wp_DK1 wp_DK2 _*

label variable e_w "log wholesale consumption"
label variable e_hh "log retail consumption"
label variable DK1 "Price region DK1"
label variable p "log spot price"
label variable wp "Wind power prognosis same region"
label variable wp_other "Wind power prognosis other region"
label variable wp_se "Wind power prognosis for Sweden"
label variable n_w "log wholesale meters"
label variable n_hh "log retail meters"
label variable trend "Time trend"
label variable temp "Temperature"
label variable temp_sq "Temperature squared"
label variable daytime "Daytime"
label variable temp "Temperature"
label variable daytime "Daytime"
label variable s_tout "Share time-of-use tariff"
label variable s_radius "Share TOUT in Radius"


////////////////////////////////////////////////////////////////////////////////
////	3. Regressions for Wholesale		 								////
////////////////////////////////////////////////////////////////////////////////

********************************************************************************
**** 	Preferred specifications											****
********************************************************************************
est clear
qui xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w ///
	o0.day_bd#i.hour o12.month#i.hour ///
	if bd==1 & inrange(hour,11,15), re vce(cluster grid)
est store peak, title("Peak: 11-15")

qui xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w ///
	o0.day_bd#i.hour o12.month#i.hour ///
	if bd==1 & inrange(hour,0,4), re vce(cluster grid)
est store off_peak, title("Off-peak: 00-04")

qui xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w  daytime ///
	o0.day_bd#i.hour o12.month#i.hour ///
	if bd==1 & inrange(hour,5,10)|inrange(hour,16,23), re vce(cluster grid)
est store shoulder, title("Shoulder")

qui xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w daytime ///
	i.hour o12.month#i.hour ///
	if non_bd==1, re vce(cluster grid) first
est store non_bd, title("Non-business days")

estout _all using "ws_preferred.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc) )
estout _all using $latex/ws_preferred.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(N, labels("Observations") fmt(%12.0gc) ) ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")


********************************************************************************
**** 	Elasticity for each hour (business days joint)						****
********************************************************************************
est clear
qui foreach h of numlist 0/23 {
	xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w ///
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
	qui foreach h of numlist 0/23 {
		xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w ///
			o0.hour o12.month ///
			if day_bd==`d' & hour==`h', fe vce(cluster grid)
		est store bd_`d'_h_`h'
	}
	estout _all using "ws_bd`d'-hour.xls", replace ///
		label cells( b(star fmt(5)) se(par fmt(5)) ) ///
		starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
		stats(N, fmt(1 %12.0gc) )
}
est clear
qui foreach h of numlist 0/23 {
	xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w ///
		o0.hour o12.month ///
		if non_bd==1 & hour==`h', fe vce(cluster grid)
	est store nbd_h_`h'
}
estout _all using "ws_non-bd-hour.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )


********************************************************************************
**** 	Robustness: For each region/year/month										****
********************************************************************************
*** For each price region and each year ***
est clear
qui xtivreg e_w (p = wp wp_other) $x_w ///
	o0.day_bd#i.hour o12.month#i.hour ///
	if DK1==1 & bd==1 & inrange(hour,11,15), re vce(cluster grid)
est store peak_DK1, title("Western DK")
qui xtivreg e_w (p = wp wp_other) $x_w ///
	o0.day_bd#i.hour o12.month#i.hour ///
	if DK1==0 & bd==1 & inrange(hour,11,15), re vce(cluster grid)
est store peak_DK2, title("Eastern DK")
forvalues y = 2016/2018 {
	qui xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) ///
		n_w temp* trend i.week ///
		o0.day_bd#i.hour o12.month#i.hour ///
		if year==`y' & bd==1 & inrange(hour,11,15), re vce(cluster grid)
	est store peak_`y', title("`y'")
}
estout _all using "ws_robustness_region_year.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc) )
estout _all using $latex/ws_robustness_region_year.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(N, labels("Observations") fmt(%12.0gc) ) ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")

*** For each month ***
est clear
forvalues m = 1/12 {
	qui xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w ///
		o0.day_bd#i.hour ///
		if month==`m' & bd==1 & inrange(hour,11,15), re vce(cluster grid)
	est store peak_`m', title("Month `m'")
}
estout _all using "ws_robustness_month.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc) )


********************************************************************************
**** 	Robustness: For different grids										****
********************************************************************************
*** For each price region and each year ***
est clear
qui ivregress 2sls e_w (p = wp wp_other) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
est store peak_131, title("EnergiMidt (DK1)")
qui ivregress 2sls e_w (p = wp wp_other) $x_w $x_11_15 ///
	if grid==151 & bd==1 & inrange(hour,11,15), robust
est store peak_151, title("NRGI (DK1)")
qui ivregress 2sls e_w (p = wp wp_other) $x_w $x_11_15 ///
	if grid==344 & bd==1 & inrange(hour,11,15), robust
est store peak_344, title("SE (DK1)")
qui ivregress 2sls e_w (p = wp wp_se) $x_w $x_11_15 ///
	if grid==740 & bd==1 & inrange(hour,11,15), robust
est store peak_740, title("SEAS-NVE (DK2)")
qui ivregress 2sls e_w (p = wp wp_se) $x_w $x_11_15 ///
	if grid==791 & bd==1 & inrange(hour,11,15), robust
est store peak_791, title("Radius (DK2)")

estout _all using "ws_robustness_grid.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc) )
estout _all using $latex/ws_robustness_grid.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(N, labels("Observations") fmt(%12.0gc) ) ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")

	
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

	
********************************************************************************
////////////////////////////////////////////////////////////////////////////////
////	4. Wholesale in single-grids: Statistical tests				 		////
////////////////////////////////////////////////////////////////////////////////
********************************************************************************
/*	
For wholesale consumption on business days, peak hours 11-15

Using the two biggest grids (one in each price region):
- DK1: EnergiMidt, grid number 131
- DK2: Radius, grid number 791
*/

qui ivregress 2sls e_w (p = wp wp_other) $x_w $x_11_15 ///
	if grid==`i' & bd==1 & inrange(hour,11,15), robust
est store peak_131, title("EnergiMidt (DK1)")

qui ivregress 2sls e_w (p = wp wp_se) $x_w $x_11_15 ///
	if grid==791 & bd==1 & inrange(hour,11,15), robust
est store peak_791, title("Radius (DK2)")

********************************************************************************
**** 	Testing for homoscedasticity										****
********************************************************************************
est clear
foreach i in 131 791 {
	* OLS w. non-robust s.e.
	qui reg e_w p $x_w $x_11_15 if grid==`i' & bd==1 & inrange(hour,11,15)
	estat hettest, rhs mtest(bonf)
	estadd scalar hettest = r(chi2)
	estadd scalar hetp = r(p)
	est store non_robust_`i', title("`i': POLS, non-robust s.e.")
	matrix A = r(mtest)
	estout matrix(A, fmt(3 0 3 3)) using "$results/ws_homoscedasticity_bp_`i'.md", style(html) replace ///
		label starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
		stats(r2 r2_a hettest hetp N, fmt(3 3 3 3 %12.0gc) labels("Chi&sup2" "p-val" "R&sup2" "Adjusted R&sup2" "Observations") ) ///
		prehead("**Table:** Testing for homoscedasticity (log wholesale electricity consumption, business days, hours 11-15)<br>*Grid number 131 is EnergiMidt (DK1), grid number 791 is Radius (in DK2)*<br><html><table>") ///
		postfoot("</table>Standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Chi&sup2 and p-val are for the simultaneous Breusch-Pagan / Cook-Weisberg test for heteroscedasticity using Bonferroni-adjusted p-values.<br>Baseline: Each hour on fridays.</html>")
	/*
	The Breusch-Pagan / Cook-Weisberg test for heteroskedasticity
	H0: Constant variance, i.e. homoscedasticity
	Both:
 	- The simultaneous test clearly rejects H0 (p=0.000)
	EnergiMidt (DK1):
	- The Bonferroni-adjusted p-values for price, n_w, & temperature are 0.000
	Radius (DK2):
	- The Bonferroni-adjusted p-val for price, n_w, & temperature are ~1 however
	*/
	* OLS w. robust s.e.
	qui reg e_w p $x_w $x_11_15 if grid==`i' & bd==1 & inrange(hour,11,15), robust
	est store robust_`i', title("`i': POLS, robust s.e.")
	/*
	The differences between non-robust s.e. and robust s.e. are
	- Relatively large for EnergiMidt (DK1)
	- Relatively small for Radius (DK2)
	*/
}
qui reg e_w p $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15)
estat hettest, rhs mtest(bonf)
matrix B_chi2 = A[.,1]
matrix B_p = A[.,4]

est store non_robust, title("131: POLS, non-robust s.e.")

estout matrix(A, fmt(3 0 3 3)) using "$results/ws_homoscedasticity_bp_131.md", ///
	style(html) replace ///
	prehead("**Table:** The Breusch-Pagan / Cook-Weisberg test for heteroskedasticity (log wholesale electricity consumption, business days, hours 11-15)<br>*Grid number 131 is EnergiMidt (DK1), grid number 791 is Radius (in DK2)*<br><html><table>") ///
	postfoot("</table>Columns 1-4 are the Chi&sup2, degrees of freedom, unadjusted p-value, and the Bonferroni-adjusted p-value.</html>")

estout non_robust, ///
	label cells( r(mtest)[.,1](star fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///

estout _all using "ws_homoscedasticity.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2 r2_a hettest hetp N, fmt(3 3 3 3 %12.0gc) )


estout _all using "ws_homoscedasticity.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2 r2_a hettest hetp N, fmt(3 3 3 3 %12.0gc) )
estout _all using "$results/ws_homoscedasticity.md", style(html) replace ///
	label cells( b(star fmt(5)) & se(par fmt(5)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2 r2_a hettest hetp N, fmt(3 3 3 3 %12.0gc) labels("Chi&sup2" "p-val" "R&sup2" "Adjusted R&sup2" "Observations") ) ///
	prehead("**Table:** Testing for homoscedasticity (log wholesale electricity consumption, business days, hours 11-15)<br>*Grid number 131 is EnergiMidt (DK1), grid number 791 is Radius (in DK2)*<br><html><table>") ///
	postfoot("</table>Standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Chi&sup2 and p-val are for the simultaneous Breusch-Pagan / Cook-Weisberg test for heteroscedasticity using Bonferroni-adjusted p-values.<br>Baseline: Each hour on fridays.</html>")

********************************************************************************
**** 	Predicting price (relevance of instruments)							****
********************************************************************************
est clear
qui reg p wp wp_other wp_se daytime $x if grid==131, robust
est store a_DK1, title("Price DK1")
qui reg p wp wp_other daytime $x if grid==131, robust
est store b_DK1, title("Price DK1")
qui reg p wp wp_se daytime $x if grid==131, robust
est store d_DK1, title("Price DK1")
qui reg p wp wp_other wp_se daytime $x if grid==131, robust
est store a_DK2, title("Price DK2")
qui reg p wp wp_other daytime $x if grid==131, robust
est store d_DK2, title("Price DK2")
qui reg p wp wp_se daytime $x if grid==131, robust
est store c_DK2, title("Price DK2")

estout _all using "price.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Control variables=*.*") drop(temp* trend daytime _cons) ///
	stats(r2_a N, fmt(3 %12.0gc) )
estout _all using $latex/price.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(r2_a N, labels("Adjusted \(R^2\)" "Observations") fmt(3 %12.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")
estout _all using "price.md", style(html) replace ///
	label cells( b(star fmt(5)) & se(par fmt(5)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_a N, labels("Adjusted R&sup2" "Observations") fmt(3 %12.0gc) ) ///
	prehead("<html><table>") postfoot("</table>Robust standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Each hour of non-business days as baseline.</html>")

	
********************************************************************************
**** 	Testing endogeneity (relevance of instrumenting)					****
********************************************************************************
foreach i in 131 791 {
	est clear
	* Simple OLS
	qui reg e_w p $x_w $x_11_15 if grid==`i' & bd==1 & inrange(hour,11,15), robust
	est store OLS, title("OLS")

	* 1st stage
	qui reg p wp wp_other $x_w $x_11_15 if grid==`i' & bd==1 & inrange(hour,11,15), robust
	predict vhat, residuals
	label variable vhat "Estimated residuals, 1st stage"
	est store first, title("1st stage, y = log price")
	test wp = wp_other = 0 // F-statistics: , 
	// t- and F-test are strongly rejected: F(2,3539)= 221, 178 respectively
	// i.e instruments are strongly correlated with price, thus, are relevant

	* 2nd stage
	qui ivregress 2sls e_w (p = wp wp_other) $x_w $x_11_15 ///
		if grid==`i' & bd==1 & inrange(hour,11,15), robust
	est store second, title("2SLS")
	// Very different from OLS, thus p is likely to be endogenous

	* Endogeneity test (Hausman)
	qui reg e_w vhat p $x_w $x_11_15 if grid==`i' & bd==1 & inrange(hour,11,15), robust
	est store endogeneity, title("Hausman-test: OLS")
	// We reject the t-test that vhat=0, thus p is endogenous and we prefer 2SLS.

	estout _all using "ws_endogeneity_`i'.xls", replace ///
		label cells( b(star fmt(5)) se(par fmt(5)) ) ///
		starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
		stats(N, fmt(1 %12.0gc) )
	estout _all using $latex/ws_endogeneity_`i'.tex, style(tex) replace ///
		label cells( b(star fmt(5)) se(par fmt(5)) ) ///
		starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
		indicate("Time variables=*.*") drop(trend _cons) ///
		stats(N, labels("Constant" "Observations") fmt(%12.0gc) ) ///	
		posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")
	drop vhat
}

********************************************************************************
**** 	Testing overidentifying restrictions 								****
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
estout _all using $latex/hh_overidentifying.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N nR2 p_value, labels("Constant" "Observations" "n*R2" "p-value") fmt(1 %12.0gc 3 3) ) ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")



********************************************************************************
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////	5. Regressions for households and small companies		 			////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
********************************************************************************
**** 	Pooled 2SLS for Radius, 17-19 only									****
********************************************************************************
est clear
qui ivregress 2sls e_hh s_tout (p = wp wp_other) $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
est store all, title("All days")

qui ivregress 2sls e_hh s_tout (p = wp wp_other) $x_hh $x_17_19 ///
	if bd==1 & grid==791 & inrange(hour,17,19), vce(robust)
est store bd, title("Business days")

qui ivregress 2sls e_hh s_tout (p = wp wp_other) $x_hh ///
	i1.non_bd#i(17 18 19).hour i.month#i(17 18 19).hour ///
	if non_bd==1 & grid==791 & inrange(hour,17,19), vce(robust)
est store nbd, title("Non-business days")

estout _all using "hh_radius_17-19.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc) )

estout _all using $latex/hh_radius_17-19.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(N, labels("Observations") fmt(%12.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")


********************************************************************************
**** 	Pooled 2SLS for Radius, 17-19: Testing for homoscedasticity			****
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
**** 	Pooled 2SLS for Radius, 17-19: Testing endogeneity 					****
********************************************************************************
est clear
* Simple OLS
reg e_hh s_tout p $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
est store OLS, title("OLS")

* 1st stage
reg p s_tout wp wp_other $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
predict vhat, residuals
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
estout _all using $latex/hh_endogeneity.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N, labels("Constant" "Observations") fmt(1 %12.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")
drop vhat


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
estout _all using $latex/hh_overidentifying.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N nR2 p_value, labels("Constant" "Observations" "n*R2" "p-value") fmt(1 %12.0gc 3 3) ) ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")


********************************************************************************
**** 	Robusness-check: Applying share-TOUT in Radius to other grids		****
********************************************************************************
est clear
qui forvalues i = 23/911 {
	count if grid == `i'
	if r(N) == 0 {
		continue
	}
	ivregress 2sls e_hh s_radius (p = wp wp_other) $x_hh $x_17_19 ///
		if grid==`i' & inrange(hour,17,19), vce(robust)
	est store grid_`i', title("Grid `i'")
}
estout _all using "hh_robustness.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc 3 3) )

