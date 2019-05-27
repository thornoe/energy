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
global x_w "n_w temp* trend i.year i.week" // daytime only relevant shoulder or off-peak
* Retail:
global x_hh "n_hh temp* daytime trend i.year i.week"
* Single-grid: Using pooled 2SLS (P2SLS) for the relevant hours ('omit' doesn't work):
global x_11_15 "i(11 12 13 14 15).hour#i(1 2 3 4 5).day_bd i(11 12 13 14 15).hour#i(1 2 3 4 5 6 7 8 9 10 11).month" // baseline: i12.month#i(11 12 13 14 15).hour
global x_17_19 "i(17 18 19).hour#i1.non_bd i(17 18 19).hour#i(1 2 3 4 5).day_bd i(17 18 19).hour#i(1 2 3 4 5 6 7 8 9 10 11).month" // baseline: i12.month#i(17 18 19).hour


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
xtivreg e_w (p = c.wp#DK1) $x_w i.hour#o0.day_bd i.hour#o12.month ///
	if bd==1 & inrange(hour,11,15), re vce(cluster grid) first
est store peak, title("Peak: 11-15")

qui xtivreg e_w (p = c.wp#DK1) $x_w i.hour#o0.day_bd i.hour#o12.month ///
	if bd==1 & inrange(hour,0,4), re vce(cluster grid)
est store off_peak, title("Off-peak: 00-04")

qui xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w  daytime ///
	o0.day_bd#i.hour o12.month#i.hour ///
	if bd==1 & inrange(hour,5,10)|inrange(hour,16,23), re vce(cluster grid)
est store shoulder, title("Shoulder")

qui xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w daytime ///
	i.hour o12.month#i.hour ///
	if non_bd==1, re vce(cluster grid)
est store non_bd, title("Non-business days")

estout _all using "ws_preferred.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_a N, fmt(4 %12.0gc) )
estout _all using $latex/ws_preferred.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(N, labels("Observations") fmt(%12.0gc) ) ///
	prehead("\begin{tabular}{lcccc}\toprule") posthead("\midrule") ///
	prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
estout _all using $results/ws_endog_overid_131.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(endog p_endog endog_reg p_endog_reg overid p_overid r2_a N, fmt(1 4 1 4 1 4 4 %12.0gc) labels("Score test of exogeneity" "p-val, exogeneity" "Regression-based F-test" "p-val, regression-based" "Test of overidentifying restrictions" "p-val, overidentifying restrictions" "n*R&sup2" "p-val" "Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Testing endogeneity and overidentifying restrictions (wholesale, business days, hours 11-15)<br>*For grid company EnergiMidt (DK1)*<br><html><table>") ///
	postfoot("</table>Robust standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Baseline: Each hour in December.</html>")

	
********************************************************************************
**** 	Elasticity for each hour (business days joint)						****
********************************************************************************
est clear
qui foreach h of numlist 0/23 {
	qui xtivreg e_w (p = c.wp#DK1) $x_w i.hour#o0.day_bd i.hour#o12.month ///
		if bd==1 & hour==`h', re vce(cluster grid)
	est store h_`h'
}
estout _all using "ws_hour.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 0 %12.0gc) labels ("R-sq within" "R-sq between" "Number of groups" "Obs. per group") )
estout _all using $results/ws_hour.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 0 %12.0gc) labels ("R&sup2& within" "R&sup2& between" "Number of groups" "Obs. per group") ) ///
	prehead("**Table:** log wholesale electricity consumption each hour (FEIV)<br>*Business days*<html><table>") ///
	postfoot("</table>Robust standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Baseline: Each hour in December.</html>")


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
	estout _all using "ws_bd`d'_hour.xls", replace ///
		label cells( b(star fmt(4)) se(par fmt(4)) ) ///
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
estout _all using "ws_non-bd_hour.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
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
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc) )
estout _all using $latex/ws_robustness_region_year.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(N, labels("Observations") fmt(%12.0gc) ) ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule\end{tabular}")

*** For each month ***
est clear
forvalues m = 1/12 {
	qui xtivreg e_w (p = c.wp#i.DK1 c.wp_other#i.DK1 DK1) $x_w ///
		o0.day_bd#i.hour ///
		if month==`m' & bd==1 & inrange(hour,11,15), re vce(cluster grid)
	est store peak_`m', title("Month `m'")
}
estout _all using "ws_robustness_month.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
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
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc) )
estout _all using $latex/ws_robustness_grid.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(N, labels("Observations") fmt(%12.0gc) ) ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule\end{tabular}")

	
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
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )

estout re fe reiv feiv using "ws_fe-re-feiv-reiv-comparison.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
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
	if grid==131 & bd==1 & inrange(hour,11,15), robust
est store peak_131, title("EnergiMidt (DK1)")

qui ivregress 2sls e_w (p = wp wp_se) $x_w $x_11_15 ///
	if grid==791 & bd==1 & inrange(hour,11,15), robust
est store peak_791, title("Radius (DK2)")

********************************************************************************
**** 	Testing for homoscedasticity										****
********************************************************************************
est clear
qui foreach i in 131 791 {
	* OLS w. non-robust s.e.
	qui reg e_w p $x_w $x_11_15 if grid==`i' & bd==1 & inrange(hour,11,15)
	estat hettest, rhs mtest(bonf)
	estadd scalar hettest = r(chi2)
	estadd scalar hetdf = r(df)
	estadd scalar hetp = r(p)
	est store non_robust_`i', title("`i': POLS, non-robust s.e.")
	matrix A_`i' = r(mtest)
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
estout _all using "ws_homoscedasticity.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(hettest hetdf hetp r2 r2_a N, fmt(0 0 3 3 3 %12.0gc) )
estout _all using "$results/ws_homoscedasticity.md", style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(hettest hetdf hetp r2 r2_a N, fmt(0 0 3 3 3 %12.0gc) labels("Chi&sup2" "DF" "Adj. p-val" "R&sup2" "Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Testing for homoscedasticity (log wholesale electricity consumption, business days, hours 11-15)<br>*Grid 131 is EnergiMidt (DK1), grid 791 is Radius (DK2)*<br><html><table>") ///
	postfoot("</table>Standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Chi&sup2, DF, and Adj. p-val are for the simultaneous Breusch-Pagan / Cook-Weisberg test for heteroscedasticity using Bonferroni-adjusted p-values.<br>Baseline: Each hour in December.</html>")
mat A1 = A_131[1..., 1]
mat A2 = A_131[1..., 4]
mat A3 = A_791[1..., 1]
mat A4 = A_791[1..., 4]
mat A = A1, A2, A3, A4
mat colnames A = Chi2_131 Adj_p_val_131 Chi2_791 Adj_p_val_791
mat list A
estout matrix(A, fmt(3 0 3 3)) using "$results/ws_homoscedasticity_bp.md", ///
	style(html) replace prehead("**Table:** The Breusch-Pagan / Cook-Weisberg test for heteroskedasticity w. Bonferroni-adjusted p-values<br>(log wholesale electricity consumption, business days, hours 11-15)<br>*Grid 131 is EnergiMidt (DK1), grid 791 is Radius (DK2)*<br><html><table>") ///
	postfoot("</table></html>")


********************************************************************************
**** 	Reduced form for log price (relevance of instruments)				****
********************************************************************************
est clear
* DK1:
qui reg p wp wp_other wp_se $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
test wp = wp_other = wp_se = 0
estadd scalar f3 = r(F)
estadd scalar f3_p = r(p)
test wp_other = wp_se = 0
estadd scalar f2 = r(F)
estadd scalar f2_p = r(p)
est store a_131, title("Price DK1")
qui reg p wp wp_other $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
test wp = wp_other = 0
estadd scalar f2 = r(F)
estadd scalar f2_p = r(p)
est store b_131, title("Price DK1")
qui reg p wp $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
est store c_131, title("Price DK1")
qui reg p $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
est store d_131, title("Price DK1")
* DK2:
qui reg p wp wp_other wp_se $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
test wp = wp_other = wp_se = 0
estadd scalar f3 = r(F)
estadd scalar f3_p = r(p)
test wp_other = wp_se = 0
estadd scalar f2 = r(F)
estadd scalar f2_p = r(p)
est store a_791, title("Price DK2")
qui reg p wp wp_se $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
test wp = wp_se = 0
estadd scalar f2 = r(F)
estadd scalar f2_p = r(p)
est store b_791, title("Price DK2")
qui reg p wp $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
est store c_791, title("Price DK2")
qui reg p wp $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
est store d_791, title("Price DK2")

estout _all using "reduced_form_price.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Control variables=*.*") drop(n_w temp* trend _cons) ///
	stats(f3 f3_p f2 f2_p r2_a N, fmt(1 3 1 3 4 %12.0gc) labels("F statistic (df=3)" "p-val (F-test, df=3)" "F statistic (df=2)" "p-val (F-test, df=2)" "Adj. R^2" "Observations") )
foreach i in 131 791 {
	estout *_`i' using $latex/reduced_form_price_`i'.tex, style(tex) replace ///
		label cells( b(star fmt(4)) se(par fmt(4)) ) ///
		starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
		indicate("Time variables=*.*") drop(trend _cons) ///
		stats(r2_a N, fmt(4 %12.0gc) labels("Adj. \(R^2\)" "Observations") ) ///
		posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
}
estout _all using $results/reduced_form_price.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_a N, fmt(4 %12.0gc) labels("Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Reduced form of log spot price (business days, hours 11-15)<html><table>") ///
	postfoot("</table>Robust standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>F-tests, col (1) and (6): Wind power prognosis other region = Wind power prognosis for Sweden = 0<br>Baseline: Each hour in December.</html>")


********************************************************************************
**** 	NOT USED: Testing endogeneity (relevance of instrumenting)			****
********************************************************************************
est clear

*** EnergiMidt (DK1) ***
* Simple OLS for comparison (relevance of instrumenting)
qui reg e_w p $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
est store OLS_131, title("POLS")
* 1st stage
qui reg p wp wp_other $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
predict vhat_131, residuals
label variable vhat_131 "Estimated residuals, 1st stage"
test wp = wp_other = 0 // F-statistics:
// t- and F-test are strongly rejected: F(2,3539)= 221 (p=0.0000)
// i.e instruments are strongly correlated with price, thus, are relevant
est store first_131, title("Reduced form of log price")
* 2nd stage
qui ivregress 2sls e_w (p = wp wp_other) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
est store second_131, title("P2SLS")
// Very different from OLS, thus p is likely to be endogenous
* Endogeneity test (Hausman)
qui reg e_w vhat_131 p $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
test vhat_131 = 0
est store endogeneity_131, title("Hausman-test: POLS")
// We clearly reject the t-test that vhat=0, thus p is endogenous and P2SLS prefered.

*** Radius (DK2) ***
* Simple OLS
qui reg e_w p $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
est store OLS_791, title("POLS")
* 1st stage
qui reg p wp wp_se $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
predict vhat_791, residuals
label variable vhat_791 "Estimated residuals, 1st stage"
test wp = wp_se = 0 // F-statistics:
// t- and F-test are strongly rejected: F(2,3539)= 249 (p=0.0000)
// i.e instruments are strongly correlated with price, thus, are relevant
est store first_791, title("Reduced form, y = log price")
* 2nd stage
qui ivregress 2sls e_w (p = wp wp_se) $x_w $x_11_15 ///
	if grid==791 & bd==1 & inrange(hour,11,15), robust
est store second_791, title("P2SLS")
// Significantly different from OLS, thus p is likely to be endogenous
* Endogeneity test (Hausman)
qui reg e_w vhat_791 p $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
test vhat_791 = 0
est store endogeneity_791, title("Hausman-test: POLS")
// We are able to reject the t-test that vhat=0 at a 3% confidence level
// thus p is endogenous and P2SLS is preferred.

foreach i in 131 791 {
	estout *_`i' using $latex/ws_endogeneity_`i'.tex, style(tex) replace ///
			label cells( b(star fmt(4)) se(par fmt(4)) ) ///
			starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
			indicate("Time variables=*.*") drop(trend _cons) ///
			stats(r2_a N, fmt(2 %12.0gc) labels("Adj. \(R^2\)" "Observations") ) ///	
			prehead("\begin{tabular}{lcccc}\toprule") posthead("\midrule") ///
			prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
}
estout _all using "ws_endogeneity.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(r2_a N, fmt(2 %12.0gc) )
estout *_131 using $results/ws_endogeneity_131.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_a N, fmt(2 %12.0gc) labels("Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Testing endogeneity of prices (wholesale, business days, hours 11-15)<br>*For grid company EnergiMidt (DK1)*<br><html><table>") ///
	postfoot("</table>Robust standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Baseline: Each hour in December.</html>")
estout *_791 using $results/ws_endogeneity_791.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_a N, fmt(2 %12.0gc) labels("Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Testing endogeneity of prices (wholesale, business days, hours 11-15)<br>*For grid company Radius (DK2)*<br><html><table>") ///
	postfoot("</table>Robust standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Baseline: Each hour in December.</html>")

drop vhat_*


********************************************************************************
**** 	NOT USED: Testing overidentifying restrictions						****
****	by standard Sargan-Hausman test										****
********************************************************************************
/* test only holds in case of homoscedasticity, an assumption that:
   - doesn't hold in general, and especially not for EnergiMidt (DK1)
   - holds for the main variables for Radius (DK2) but not for the overall model
*/
est clear

*** EnergiMidt (DK1) ***
* Each instrument individually
qui foreach z of varlist wp wp_other {
	ivregress 2sls e_w (p = `z') $x_w $x_11_15 ///
		if grid==131 & bd==1 & inrange(hour,11,15), robust
	predict uhat_`z'_131, residuals
	est store iv_`z'_131, title("P2SLS, `z' only")
	reg uhat_`z'_131 $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
	est store OLS_`z'_131, title("POLS, y = uhat(`z')")
}
* Both instruments
qui ivregress 2sls e_w (p = wp wp_other) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
predict uhat_both_131, residuals
est store iv_both_131, title("P2SLS, both")
qui reg uhat_both_131 wp wp_other $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
estadd scalar nR2 = e(N)*e(r2) // .345
estadd scalar p_value = 1-chi2(1, e(N)*e(r2)) // chi-sq(1) = 5.9 (p = 0.015) (df = number of overidentifying restrictions)
// we reject H0 (5% lvl): that at least one of wp and wp_other are not exogenous
est store OLS_both_131, title("OLS, y = uhat(both)")
test wp = wp_other = 0 // F(2, 3539) = 2.46 (p-val = 0.086)
// t- and F-tests cannot be rejected at the 5 pct. confidence level
// i.e. both instruments are likely uncorrelated with uhat => likely exogenous.

*** Radius (DK2) ***
* Each instrument individually
qui foreach z of varlist wp wp_se {
	ivregress 2sls e_w (p = `z') $x_w $x_11_15 ///
		if grid==791 & bd==1 & inrange(hour,11,15), robust
	predict uhat_`z'_791, residuals
	est store iv_`z'_791, title("P2SLS, `z' only")
	reg uhat_`z'_791 $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
	est store OLS_`z'_791, title("POLS, y = uhat(`z')")
}
* Both instruments
qui ivregress 2sls e_w (p = wp wp_se) $x_w $x_11_15 ///
	if grid==791 & bd==1 & inrange(hour,11,15), robust
predict uhat_both_791, residuals
est store iv_both_791, title("P2SLS, both")
qui reg uhat_both_791 wp wp_se $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
estadd scalar nR2 = e(N)*e(r2) // .345
estadd scalar p_value = 1-chi2(1, e(N)*e(r2)) // chi-sq(1) = 16 (p = 0.0001) (df = number of overidentifying restrictions)
// we clearly rejects H0: that at least one of wp and wp_se are not exogenous
est store OLS_both_791, title("OLS, y = uhat(both)")
test wp = wp_se = 0 // F(2, 3539) = 7.47 (p-val = 0.006)
// t- and F-tests are clearly rejected even at a 1 pct. confidence level
// i.e. both instruments are NOT uncorrelated with uhat => one or both are endogenous.

foreach i in 131 791 {
estout *_`i' using "ws_overidentifying_`i'.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N nR2 p_value, fmt(%12.0gc 3 3) )
estout *_`i' using $latex/ws_overidentifying_`i'.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(nR2 p_value r2_a N, fmt(2 2 2 %12.0gc) labels("\(N\cdot R^2\)" "p-val" "Adj. \(R2\)" "Observations") ) ///
	prehead("\begin{tabular}{lcccc}\toprule") posthead("\midrule") ///
	prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
}
estout *_131 using $results/ws_overidentifying_131.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(nR2 p_value r2_a N, fmt(2 2 2 %12.0gc) labels("n*R&sup2" "p-val" "Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Testing overidentifying assumptions (wholesale, business days, hours 11-15)<br>*For grid company EnergiMidt (DK1)*<br><html><table>") ///
	postfoot("</table>Robust standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Baseline: Each hour in December.</html>")
estout *_791 using $results/ws_overidentifying_791.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(nR2 p_value r2_a N, fmt(2 2 2 %12.0gc) labels("N*R&sup2" "p-val" "Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Testing overidentifying assumptions (wholesale, business days, hours 11-15)<br>*For grid company Radius (DK2)*<br><html><table>") ///
	postfoot("</table>Robust standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Baseline: Each hour in December.</html>")

drop uhat*


********************************************************************************
**** 	Testing both endogeneity and overidentifying restrictions			****
********************************************************************************
/*  Wooldridge's heteroscedasticity-robust score test of overidentifying restrictions:
	H0: All instruments are valid at the 5% level.
	p < .05 => test statistic is significant at the 5% level => reject H0
			=> either instrument is invalid or the structural model is misspecified
	Equivalently for the regression based F-test.
*/
est clear

*** EnergiMidt (DK1) ***
* Simple OLS for comparison (relevance of instrumenting)
qui reg e_w p $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
est store POLS_131, title("POLS")
* Each instrument individually: DK1
qui ivregress 2sls e_w (p = wp) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
estat endogenous
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
est store iv_wp_131, title("P2SLS, wp DK1")
* Each instrument individually: DK2
qui ivregress 2sls e_w (p = wp_other) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
estat endogenous
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
est store iv_wp_other_131, title("P2SLS, wp DK2")
* Both instruments
qui ivregress 2sls e_w (p = wp wp_other) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
estat endogenous // H0: the regressor (price) is exogenous
/*	Robust score chi2(1)            =  77.1  (p = 0.0000)
	Robust regression F(1, 3539)    =  86.3  (p = 0.0000)
	p < .05 => H0 clearly rejected => regressor is endogenous
*/
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
estat firststage // H0: the set of instruments is weak
/*	F(2, 3539) = 200, (p = 0.0000)
	p < .05 => H0 clearly rejected => our instruments are not weak
*/
estadd scalar mineig = r(mineig) // doesn't work somehow
estat overid // H0: Our instruments are valid at the 5% level.
/* 	chi-sq(1) = 5.1 (p = 0.024) (df = number of overidentifying restrictions).
	p < .05 => reject H0, thus, either or all of the instruments are invalid.
	i.e. instruments are either not exogenous or the model is misspecified.
	However, each instrument was found to be endogenous when tested individually
	=> Model is overspecified
*/
estadd scalar overid = r(score) // Overid-score
estadd scalar p_overid = r(p_score) // p-val (overid)
est store iv_both_131, title("P2SLS, both")

*** Radius (DK2) ***
* Simple OLS for comparison (relevance of instrumenting)
qui reg e_w p $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
est store POLS_791, title("POLS")
* Each instrument individually: DK2
qui ivregress 2sls e_w (p = wp) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
estat endogenous
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
est store iv_wp_791, title("P2SLS, wp DK2")
* Each instrument individually: SE
qui ivregress 2sls e_w (p = wp_se) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
estat endogenous
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
est store iv_wp_se_791, title("P2SLS, wp SE")
* Both instruments
qui ivregress 2sls e_w (p = wp wp_se) $x_w $x_11_15 ///
	if grid==791 & bd==1 & inrange(hour,11,15), robust
estat endogenous // H0: the regressor (price) is exogenous
/*	Robust score chi2(1)            =  5.0	(p = 0.0249)
	Robust regression F(1,3539)     =  4.8	(p = 0.0285)
	p < .05 => H0 rejected => regressor is endogenous
*/
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
estat firststage // H0: the set of instruments is weak
/*	F(2, 3539) = 249, (p = 0.0000)
	p < .05 => H0 clearly rejected => our instruments are not weak
*/
estadd scalar mineig = r(mineig) // doesn't work somehow
estat overid // H0: Our instruments are valid at the 5% level.
/* 	chi-sq(1) = 15.5 (p = 0.0001) (df = number of overidentifying restrictions).
	p < .05 => reject H0, thus, either or all of the instruments are invalid.
	i.e. instruments are either not exogenous or the model is misspecified.
	However, each instrument was found to be endogenous when tested individually
	=> Model is overspecified
*/
estadd scalar overid = r(score) // Overid-score
estadd scalar p_overid = r(p_score) // p-val (overid)
est store iv_both_791, title("P2SLS, both")

estout _all using "ws_endog_overid.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(endog p_endog endog_reg p_endog_reg overid p_overid r2_a N, fmt(1 4 1 4 1 4 4 %12.0gc) )
foreach i in 131 791 {
	estout *_`i' using $latex/ws_endog_overid_`i'.tex, style(tex) replace ///
		label cells( b(star fmt(4)) se(par fmt(4)) ) ///
		starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
		indicate("Time variables=*.*") drop(trend _cons) ///
		stats(endog p_endog endog_reg p_endog_reg overid p_overid r2_a N, fmt(1 4 1 4 1 4 4 %12.0gc) labels("Score test of exogeneity" "p-val, exogeneity" "Regression-based F-test" "p-val, regression-based" "Test of overidentifying restrictions" "p-val, overidentifying restrictions" "Adj. \(R^2\)" "Observations") ) ///
		prehead("\begin{tabular}{lcccc}\toprule") posthead("\midrule") ///
		prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
}
estout *_131 using $results/ws_endog_overid_131.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(endog p_endog endog_reg p_endog_reg overid p_overid r2_a N, fmt(1 4 1 4 1 4 4 %12.0gc) labels("Score test of exogeneity" "p-val, exogeneity" "Regression-based F-test" "p-val, regression-based" "Test of overidentifying restrictions" "p-val, overidentifying restrictions" "n*R&sup2" "p-val" "Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Testing endogeneity and overidentifying restrictions (wholesale, business days, hours 11-15)<br>*For grid company EnergiMidt (DK1)*<br><html><table>") ///
	postfoot("</table>Robust standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Baseline: Each hour in December.</html>")
estout *_791 using $results/ws_endog_overid_791.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(endog p_endog endog_reg p_endog_reg overid p_overid r2_a N, fmt(1 4 1 4 1 4 4 %12.0gc) labels("Score test of exogeneity" "p-val, exogeneity" "Regression-based F-test" "p-val, regression-based" "Test of overidentifying restrictions" "p-val, overidentifying restrictions" "N*R&sup2" "p-val" "Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Testing endogeneity and overidentifying restrictions (wholesale, business days, hours 11-15)<br>*For grid company Radius (DK2)*<br><html><table>") ///
	postfoot("</table>Robust standard errors are in parentheses. * p<0.10, ** p<0.05, *** p<0.01.<br>Baseline: Each hour in December.</html>")


prehead("**Table:** Testing for homoscedasticity (log wholesale electricity consumption, business days, hours 11-15)<br>*Grid 131 is EnergiMidt (DK1), grid 791 is Radius (DK2)*<br><html><table>") ///

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
qui ivregress 2sls e_hh s_tout (p = wp wp_other wp_se) $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), vce(robust)
est store all, title("All days")

qui ivregress 2sls e_hh s_tout (p = wp wp_other wp_se) $x_hh $x_17_19 ///
	if bd==1 & grid==791 & inrange(hour,17,19), vce(robust)
est store bd, title("Business days")

qui ivregress 2sls e_hh s_tout (p = wp wp_other wp_se) $x_hh ///
	i1.non_bd#i(17 18 19).hour i.month#i(17 18 19).hour ///
	if non_bd==1 & grid==791 & inrange(hour,17,19), vce(robust)
est store nbd, title("Non-business days")

estout _all using "r_radius_17-19.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc) )

estout _all using $latex/r_radius_17-19.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(r2_a N, fmt(2 %12.0gc) labels("Adj. \(R^2\)" "Observations") ) ///	
	prehead("\begin{tabular}{lccc}\toprule") posthead("\midrule") ///
	prefoot("\midrule") postfoot("\bottomrule\end{tabular}")


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

estout _all using "r_homoscedasticity.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
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

estout _all using "r_endogeneity.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(1 %12.0gc) )
estout _all using $latex/r_endogeneity.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N, labels("Constant" "Observations") fmt(1 %12.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
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

estout _all using "r_overidentifying.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N nR2 p_value, fmt(%12.0gc 3 3) )
estout _all using $latex/r_overidentifying.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(cons N nR2 p_value, labels("Constant" "Observations" "n*R2" "p-value") fmt(1 %12.0gc 3 3) ) ///
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule\end{tabular}")


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
estout _all using "r_robustness.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(%12.0gc 3 3) )

